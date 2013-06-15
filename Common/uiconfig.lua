-- uiconfig
--
-- v01 - 5/31/2013 12:02:09 PM - initial release, requires utils 2.0.4+, simpleui v01+, winapi v06+
-- v02 - 5/31/2013 7:08:26 PM - keymapper widget, all add_* functions return widget, widget tick property
-- v03 - 6/1/2013 3:18:04 PM - added permashow, added keymapper to keydown/keytoggle widgets, wider format, menu menu changes, and more
-- v04 - 6/6/2013 9:00:45 PM - added widget.onchange handler, now skips items associated to inactive scripts, valuemaps no longer index by +1, fixed menu bg panel display issue
-- v05 - 6/8/2013 12:03:55 AM - fixed a bug with key widgets, scary refactoring, pin menu feature, options menu created, master key remapping, permashow width slider, add_menu width param now works

-- todo: draw slider value inside slider? maybe not...

-- later: only trigger saves if menu is popped up with shift key, otherwise it never saves
-- later: dragging while hiding messes up state, fix?
-- later: alternative add_* functions that take a table add_label{foo=bar, etc=whatever}
-- later: allow keys to adjust widget values? meh
-- later: menu checkbuttons take up extra space when checked... how!?323456

-- 2 ways to get/set values
-- cfg.Name, cfg.Name = 42, or... menu_table.get(), menu_table.set()
-- 2 ways to add widgets
-- add_label('My Config',...), or... cfg.add_label(...)

require 'Keys'
require 'winapi'
local ui = require 'simpleui'
local draw = require 'simpleui_drawing'
local Rectangle = draw.Rectangle
local Color = draw.Color

local menus = {}
local all_widgets = {}
local background_logic = {}
local permashow = {} -- {menu:{widget, ...}}

local folder = 'uiconfig'
local selfconfig = folder..'\\_uconfig.txt'
local line_height = math.ceil(GetFontSize()*2)
local line_height_perma = math.ceil(GetFontSize()*1.2)

local one = line_height/2
local two = line_height
local ox, oy = 400, 100
local loaded_menu_data = {}
local save_interval = 60
local next_autosave = os.clock() + save_interval
local capture_next_key = false -- for keymapper
local captured_key = nil
local oxperma, oyperma = 10, 400
local key_names = {} -- {[118]='F7',...}
local perma_text_color = 0xffbbbbbb
local pin_menu = false

local options_cfg, options_menu

-- avoid local lexical nonsense
local do_keymapper, add_keymapper, do_permashow, add_permashow, save_self, load_self, do_menu
local do_root_checkbutton, get_loaded_value

local function menu_key_down()
    return options_cfg.uiconfig_key
end

local function should_show()
    --print('menu key down', menu_key_down(), 'pin_menu', pin_menu)
    return menu_key_down() or pin_menu    
end

local function make_id(menu, name)
    assert(type(menu)=='table', 'menu must be a table')
    return menu.id..':'..name
end

local function string_to_boolean(s)
    if s =='true' then
        return true
    else
        return false
    end
end

local function deserialize_value(s)
    local value
    if s=='true' then
        value = true
    elseif s=='false' then
        value = false
    else
        value = tonumber(s)
    end
    return value
end

local function convert_to_uistring(v)
    local s
    if type(v) == 'boolean' then
        if v then
            s = 'ON'
        else 
            s = 'OFF'
        end
    elseif type(v) == 'number' then
        s = tostring(draw.round(v,2))
    else
        s = tostring(v)
    end
    return s
end

local function lookup_key_name(id)
    local name = key_names[id]
    if name == nil then
        name = '?'
    end
    return name
end

-- skip means do_widget will not be called, probably because it's part of a composite widget
local function add_widget(menu, widget, skip)
    local loaded_value = get_loaded_value(menu, widget)
    if loaded_value ~= nil then        
        widget.value = loaded_value
        print('associated loaded data to widget', menu.name, widget.name, widget.value)
    else
        print('no loaded data for widget', menu.name, widget.name, widget.value)
    end
    widget.menu = menu
    widget.skip = skip
    widget.id = make_id(menu, widget.name)
    all_widgets[widget.id] = widget
    if widget.background_logic and widget.logic ~= nil then
        background_logic[widget.id] = widget
    end
    table.insert(menu.widgets, widget)
end

local function get_widget(menu, name)
    local id = make_id(menu, name)
    local widget = all_widgets[id]
    if widget == nil then
        error('no such widget: '..tostring(menu.name)..' > '..tostring(name))
    end
    return widget
end

local function get_value(menu, name)
    local widget = get_widget(menu, name)
    return widget.value
end

local function set_value(menu, name, value)
    local widget = get_widget(menu, name)
    widget.value = value
end

local function make_config_table(menu)
    local proxy = {}
    local mt = {}
    mt.__index = function (table, key)
        return get_value(menu, key)
    end
    mt.__newindex = function (table, key, value)
        set_value(menu, key, value)
    end    
    setmetatable(proxy, mt)
    return proxy
end

-- convenience
local function add_checkbox(menu, name, label, value)
    local widget = {}
    widget.kind = 'checkbox'
    widget.name = name
    widget.label = label
    widget.value = value
    add_widget(menu, widget)
    return widget
end

local function add_label(menu, name, label)
    local widget = {}
    widget.kind = 'label'
    widget.name = name
    widget.label = label
    add_widget(menu, widget)
    return widget
end

local function add_button(menu, name, text, value)
    local widget = {}
    widget.kind = 'button'
    widget.name = name
    widget.text = text
    widget.value = value
    add_widget(menu, widget)
    return widget
end

local function add_progressbar(menu, name, max, value)
    local widget = {}
    widget.kind = 'progressbar'
    widget.name = name
    widget.max = max
    widget.value = value
    add_widget(menu, widget)
    return widget
end

local function add_slider(menu, name, label, min, max, value, valuemap, fractional)
    local widget = {}
    widget.kind = 'slider'
    widget.name = name
    widget.label = label
    widget.min = min
    widget.max = max
    widget.value = value
    widget.valuemap = valuemap    
    if widget.valuemap ~= nil then
        assert(type(widget.valuemap)=='table', 'widget.valuemap must be table, not '..type(widget.valuemap))
    end
    widget.fractional = fractional
    add_widget(menu, widget)
    return widget
end

local function add_checkbutton(menu, name, text, value)
    local widget = {}
    widget.kind = 'checkbutton'
    widget.name = name
    widget.text = text
    widget.value = value
    add_widget(menu, widget)
    return widget
end

-- annoyance
local function do_key_indicator(widget)
    if widget.cache == nil then
        widget.cache = true
        
        local rect = widget.rect
        
        local rect1 = draw.rectangle_copy(rect)
        rect1.Width = draw.round(rect.Width*.5)

        local rect2 = draw.rectangle_copy(rect)
        rect2.Width = 30
        rect2.X = rect.Width

        local rect3 = draw.rectangle_copy(rect)
        rect3.Width = rect.Width-rect2.Width-rect1.Width
        rect3.Width = rect3.Width - ui.layout_peek().padding*2

        widget.rect1 = rect1
        widget.rect2 = rect2
        widget.keymapper.rect = rect3
    end
    assert(widget.rect1~=nil, 'widget.rect1~=nil')
    local changed = false
    local uiid = widget.id
    local label, rect, value = widget.label, widget.rect, widget.value
    ui.layout_push('horizontal')
    ui.label(uiid..' label', label, widget.rect1)
    local uistate = ui.state
    if uistate.step == UIStep_Init then
        ui.layout_increment(widget.rect2)
    elseif uistate.step == UIStep_Logic then
        --return standard_logic(uiid)
        if widget.logic ~= nil then
            changed, value = widget.logic(widget)
        end
    elseif uistate.step == UIStep_Draw then
        local state = ui.calc_drawstate(uiid)
        ui.layout_transform(widget.rect2)
        local text
        if value then text = 'ON' else text = 'OFF' end
        draw.checkbutton(text, widget.rect2, state, value)
        ui.layout_increment(widget.rect2)
    end   
    if widget.keymapper~=nil then
        local keymapper_changed
        keymapper_changed, widget.keymapper.value = do_keymapper(widget.keymapper)
    end
    ui.layout_pop()
    return changed, value
end

local function root_width()
    return 140
end

local function make_key_logic(key, toggle)
    local prev_state = winapi.get_async_key_state(key)
    return function(widget)
        local state = winapi.get_async_key_state(widget.keymapper.value)
        local changed = false
        local value = widget.value
        if state ~= prev_state then
            changed = true
            if toggle then
                if state then -- we only care when it goes down
                    value = not value
                end            
            else
                value = state
            end
            prev_state = state            
        end
        return changed, value
    end
end

local function add_keydown(menu, name, label, key)
    local rect = Rectangle(nil, nil, menu.width, line_height)
    local widget = {fn=do_key_indicator, kind='keydown', name=name, label=label, value=false, rect=rect, logic=make_key_logic(key), background_logic=true}
    add_widget(menu, widget)
    
    local keymapper = {fn=do_keymapper, name=name..'___Keymapper', label=nil, value=key, rect=rect}
    keymapper.pressmsg = '<press>'
    add_widget(menu, keymapper, true)
    widget.keymapper = keymapper

    return widget
end

local function add_keytoggle(menu, name, label, key, default)
    local rect = Rectangle(nil, nil, menu.width, line_height)
    local widget = {fn=do_key_indicator, kind='keytoggle', name=name, label=label, value=default, rect=rect, logic=make_key_logic(key, true), background_logic=true}
    add_widget(menu, widget)

    local keymapper = {fn=do_keymapper, name=name..'___Keymapper', label=nil, value=key, rect=rect}
    keymapper.pressmsg = '<press>'
    add_widget(menu, keymapper, true)
    widget.keymapper = keymapper

    return widget
end

function do_keymapper(widget)
    if widget.cache == nil then        
        widget.checkbutton_value = false
        widget.cache = true
    end
    local checkbutton_text
    local changed = false
    local uiid = widget.id

    if widget.label ~= nil then
        ui.label(uiid..' label', widget.label, widget.rect)
    end
    
    -- if cb is down and we are waiting for a key, then change the message
    if widget.checkbutton_value and capture_next_key then
        if widget.pressmsg ~= nil then
            checkbutton_text = widget.pressmsg
        else
            checkbutton_text = '<press a key>'
        end
    else
        checkbutton_text = lookup_key_name(widget.value)        
    end

    -- if cb is down, and we captured a key, then deal with it(tm)
    if widget.checkbutton_value and captured_key ~=nil then
        changed = true
        widget.value = captured_key
        widget.checkbutton_value = false
        captured_key = nil
    end
    
    local cb_changed
    cb_changed, widget.checkbutton_value = ui.checkbutton(uiid..' checkbutton', checkbutton_text, widget.rect, widget.checkbutton_value)
    if cb_changed and widget.checkbutton_value then -- cb went down
        capture_next_key = true
    end
    
    return changed, widget.value
end

-- catches key when checkbutton is down, value is whatever key is currently mapped
function add_keymapper(menu, name, label, default)
    local rect = Rectangle(nil, nil, menu.width, line_height)
    local widget = {fn=do_keymapper, kind='keymapper', name=name, label=label, value=default, rect=rect}
    add_widget(menu, widget)
    return widget
end

local function get_filename(menu)
    assert(type(menu)=='table', 'menu must be a table')
    return folder..'\\'..menu.id..'.txt'
end

local function save_dictionary(fn, dict)
    assert(#dict==0, 'dict with array elements')
    --print('saving', fn)
    local f = io.open(fn, 'w+') 
    for k,v in pairs(dict) do        
        local line = string.format('%s=%s', k, v)
        f:write(line)
        f:write('\n')                
    end
    f:close()
end

local function load_dictionary(fn)
    local f = io.open(fn)    
    local dict = {}
    if f == nil then return dict end
    for line in f:lines() do
        if line:len() >= 3 then
            local pos = line:find('=')
            if pos > 1 then
                local k = line:sub(1,pos-1)
                local v = line:sub(pos+1)
                dict[k] = v
            end
        end
    end
    f:close()
    return dict
end

local function save_menu(menu)
    local dict = {}
    local changed = false
    for i,widget in ipairs(menu.widgets) do
        dict[widget.name] = widget.value
        -- doesnt work, care later (because changed is only true during one ui step? probably)
        --if not changed and widget.changed then
        --    changed = true
        --end
        --print(menu, widget.name, widget.value)
    end
    if true or changed then -- later: change detection
        local fn = get_filename(menu)
        save_dictionary(fn, dict)
    end
end

local function save()
    print('uiconfig saving...')
    next_autosave = os.clock() + save_interval    
    for name, menu in pairs(menus) do
        save_menu(menu)
    end
    save_menu(options_menu)
    save_self()
end

local function consider_save()
    if true then
        save()
    end
end

function get_loaded_value(menu, widget)
    if loaded_menu_data[menu] ~= nil then       
        local v = loaded_menu_data[menu][widget.name]
        if v ~= nil then
            return v
        end
    end
end

local function load_menu(menu)    
    local fn = get_filename(menu)
    print('loading menu from', fn)
    local dict = load_dictionary(fn)    
    local data = {}
    for k,v in pairs(dict) do
        data[k] = deserialize_value(v)
    end
    loaded_menu_data[menu] = data
end

local function load()
    load_self()
end

function save_self()
    local dict = {
        ox=ox,
        oy=oy,
        oxperma=oxperma,
        oyperma=oyperma,
    }
    save_dictionary(selfconfig, dict)
end

function load_self()
    -- load self
    local dict = load_dictionary(selfconfig)
    if dict.ox ~= nil then ox = tonumber(dict.ox) end
    if dict.oy ~= nil then oy = tonumber(dict.oy) end
    if dict.oxperma ~= nil then oxperma = tonumber(dict.oxperma) end
    if dict.oyperma ~= nil then oyperma = tonumber(dict.oyperma) end
end

function do_save()
    if os.clock() >= next_autosave then
        consider_save()
    end
end

local function do_widget(widget)
    local one = line_height/2
    local two = line_height
    local t = widget.menu
    if widget.tick ~= nil then
        widget.tick(widget)
    end
    --print('do_widget', widget.id)
    if widget.kind == 'checkbox' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,two,two)
            widget.labelid = widget.id..' label'
            widget.labelrect = Rectangle(nil,nil,t.width-two-ui.layout_peek().padding*2,two)
            widget.cache = true
        end
        ui.layout_push('horizontal')
        widget.changed, widget.value = ui.checkbox(widget.id, widget.rect, widget.value)
        ui.label(widget.labelid, widget.label, widget.labelrect)
        ui.layout_pop()
    elseif widget.kind == 'label' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,t.width,two)
            widget.cache = true
        end
        ui.label(widget.id, widget.label, widget.rect)
    elseif widget.kind == 'button' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,t.width,two)
            widget.cache = true
        end
        widget.changed = ui.button(widget.id, widget.text, widget.rect)
    elseif widget.kind == 'progressbar' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,t.width,two)
            widget.cache = true
        end
        widget.changed, widget.value = ui.progressbar(widget.id, widget.rect, widget.max, widget.value)
    elseif widget.kind == 'slider' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,t.width,two)
            widget.label_id = widget.id..' label'
            widget.label_rect = widget.rect
            widget.valuelabel_id = widget.id..' valuelabel'
            widget.valuelabel_rect = Rectangle(nil,nil,80,two)
            widget.cache = true
        end
        if widget.label ~= nil then
            ui.label(widget.label_id, widget.label, widget.label_rect)
        end
        ui.layout_push('horizontal')
        assert(widget.value ~= nil, 'widget.value nil A')
        widget.changed, widget.value = ui.slider(widget.id, widget.rect, widget.min, widget.max, widget.value, widget.fractional)
        assert(widget.value ~= nil, 'widget.value nil B')
        local valuelabel
        if widget.valuemap == nil then            
            valuelabel = widget.value
            if widget.fractional then
                valuelabel = draw.round(valuelabel, 2)
            end
        else            
            valuelabel = widget.valuemap[widget.value]
        end
        ui.label(widget.valuelabel_id, valuelabel, widget.valuelabel_rect)
        ui.layout_pop()
    elseif widget.kind == 'checkbutton' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,t.width,two)
            widget.cache = true
        end
        widget.changed, widget.value = ui.checkbutton(widget.id, widget.text, widget.rect, widget.value)
    else
        if widget.fn ~= nil then
            widget.changed, widget.value = widget.fn(widget)
        end
    end
    if widget.changed and widget.onchange ~= nil then
        widget.onchange(widget)
    end
end

local rooth, rooth2 = 0,0
local active_menu = nil
local panelbg = Color(0.5,0.5,0.5,0.5)
local top_layout
local function do_ui()
    local changed
    
    changed, ox, oy = ui.handle('uiconfig menu handle', Rectangle(ox-one, oy-two-2, root_width()+two, one), ox, oy)

    -- root top panel
    local menu_rect = Rectangle(ox-one,oy-one,root_width()+two,rooth+two-2)
    ui.rectangle('uiconfig root top panel', menu_rect, panelbg)
    -- root bot panel
    local menu_rect2 = Rectangle(ox-one,oy-one+rooth+two,root_width()+two,rooth2+two)
    ui.rectangle('uiconfig root bot panel', menu_rect2, panelbg)

    -- sort menus by name, case insensitive, skip inactive scriptnum
    local sorted = {}
    for name,menu in pairs(menus) do
        if IsScriptActive(menu.scriptnum) then 
            table.insert(sorted, name)
        end
    end
    table.sort(sorted, function(a,b) return a:lower() < b:lower() end)

    ui.layout_push('vertical', 2, ox, oy)
    top_layout = ui.layout_peek()
    --for key,t in pairs(menus) do
    for i,key in ipairs(sorted) do
        local menu = menus[key]
        --print('menu', key, t.value, #t.widgets)
        do_root_checkbutton(menu)
    end
    local menu_layout = ui.layout_pop()
    if ui.state.step == UIStep_Init then
        rooth = menu_layout.y - menu_layout.oy
    end
        
    ui.layout_push('vertical', 2, menu_layout.x, menu_layout.y+two)
        
    do_root_checkbutton(options_menu)
    
    -- later: this doesn't work right, ignore for now
    changed, pin_menu = ui.checkbutton('uiconfig pin_menu', 'Pin Menu', Rectangle(nil,nil,root_width(),line_height), pin_menu)

    local menu_layout_bot = ui.layout_pop()
    if ui.state.step == UIStep_Init then
        rooth2 = menu_layout_bot.y - menu_layout_bot.oy
        -- same todo as above: "make this a function..."
    end
end

function do_root_checkbutton(menu)
    assert(menu~=nil,'menu is nil')
    local changed
    local rect = Rectangle(nil,nil,root_width(),two)
    local id = 'uiconfig root checkbutton:'..menu.id
    changed, menu.value = ui.checkbutton(id, menu.name, rect, menu.value)
    -- make all other menu checkbuttons false when one changes to true        
    if changed and menu.value then
        active_menu = menu
    end
    if menu ~= active_menu then
        menu.value = false
    end
    if menu.value then
        do_menu(menu)
    end
end

function do_menu(t)
    local key = t.id
    local subh, subtitleh = t.subh, t.subtitleh
    --local curr_layout = ui.layout_peek()
    local subpad = top_layout.padding            
    local subtitlex = top_layout.x+root_width()+one+one+top_layout.padding            
    local subtitley = top_layout.oy
    local subx = subtitlex
    local suby = subtitley + subtitleh + two    
    
    ui.layout_push('none')
    -- title panel
    local sub_title_rect = Rectangle(subtitlex-one,subtitley-one,t.width+two,subtitleh+two-2)
    ui.rectangle(key..' sub title panel', sub_title_rect, panelbg)            
    -- remainder panel
    local sub_rect = Rectangle(subx-one,suby-one,t.width+two,subh+two)
    ui.rectangle(key..' sub panel', sub_rect, panelbg)
    ui.layout_pop()            
    
    -- title
    ui.layout_push('vertical', subpad, subtitlex, subtitley)
    ui.label(key..' title label', t.name, Rectangle(nil,nil,t.width,two))
    local sub_title_layout = ui.layout_pop(false)
    if ui.state.step == UIStep_Init then
        t.subtitleh = sub_title_layout.y - sub_title_layout.oy
        -- todo: make this a function, layout_dimensions(), and it only operates in init?
        --       or ui.panel, a container that does all this and draws the panel
    end
    
    -- remainder
    ui.layout_push('vertical', subpad, subx, suby)
    --ui.rectangle(key..' title hline', Rectangle(nil,nil,t.width,2), draw.normal_face)
    for j,widget in ipairs(t.widgets) do
        if widget.skip ~= true then
            do_widget(widget)
        end
    end
    local sub_layout = ui.layout_pop(false)
    if ui.state.step == UIStep_Init then
        t.subh = sub_layout.y - sub_layout.oy
        -- todo: make this a function, layout_dimensions(), and it only operates in init?
    end
end

function do_permashow()    
    local changed
    local perma_width = options_cfg.permashow_width
    -- todo: large handles? handles with labels?
    if should_show() then
        changed, oxperma, oyperma = ui.handle('permashow handle', Rectangle(oxperma-one, oyperma-two-1, perma_width+two, one), oxperma, oyperma)
    end

    local value_width = 30
    local label_width = perma_width - value_width    

    --local menu_rect = Rectangle(ox-one,oy-one,menuw+two,rooth+two-4)
    --ui.rectangle('uiconfig menu panel', menu_rect, panelbg)

    ui.layout_push('vertical', 4, oxperma, oyperma)
    for menu,widgets in pairs(permashow) do              
        --print('permashow', menu.id)
        for i,widget in pairs(widgets) do
            if IsScriptActive(widget.scriptnum) then                
                --print('do_permashow', menu.id, widget.name, widget.value)
                ui.layout_push('horizontal')
                local idprefix = 'perma '..tostring(i)
                local value_string = convert_to_uistring(widget.value)
                local value_name
                if widget.label == nil then
                    value_name = widget.name
                else
                    value_name = widget.label
                end            
                if widget.kind == 'keydown' or widget.kind == 'keytoggle' then
                    if widget.keymapper ~= nil then
                        local key_name = lookup_key_name(widget.keymapper.value)
                        value_name = string.format('%s [%s]', value_name, key_name)
                    end            
                end
                ui.label(idprefix..' label', value_name, Rectangle(nil,nil,label_width,line_height_perma), perma_text_color)
                local prev_layout = ui.layout_peek()
                if type(widget.value)=='boolean' and widget.value then
                    ui.layout_push('none')
                    local bgcolor = 0x3300ff00
                    ui.rectangle(idprefix..' rect', Rectangle(prev_layout.x-10, prev_layout.y-2, value_width+16, line_height_perma+4), bgcolor)
                    ui.layout_pop()
                end
                ui.label(idprefix..' value', value_string, Rectangle(nil,nil,value_width,line_height_perma), perma_text_color)
                ui.layout_pop()
            end
        end
    end
    ui.layout_pop()
end

local function tick()
    do_save()

    if options_cfg.permashow_toggle == false then -- false means enabled here
        ui.tick(do_permashow)
    end
    
    if should_show() then
        ui.tick(do_ui)
    end
    
    -- run background widget logic whether or not menu is showing (for keydown junk)
    for id,widget in pairs(background_logic) do
        if widget ~= nil and widget.logic ~= nil then
            widget.changed, widget.value = widget.logic(widget)
        end
    end

end

local function on_wnd_msg(msg, key)    
    if msg==KEY_DOWN then
        if capture_next_key then
            local uiconfig_key_code = options_menu.get_widget('uiconfig_key').keymapper.value
            if key ~= uiconfig_key_code then -- ignore the menu key they are holding down
                if should_show() then -- but, also, only capture the key if they are showing the menu
                    captured_key = key
                    capture_next_key = false
                end
            end
        end
    end
end

local function make_menu(name, width, id)
    if width == nil then width = 200 end    
    width = math.max(width,140) -- min menu width
    if id == nil then id = name end
    local menu = {name=name, value=false, widgets={}}
    menu.scriptnum = GetScriptNumber()    
    menu.width = width -- todo: test this
    menu.subh = 0 -- calculated
    menu.subtitleh = 0 -- calculated
    menu.id = id
    menu.name = name
    menu.get_widget = function(widget_name) return get_widget(menu, widget_name) end
    menu.get = function(widget_name) return get_value(menu, widget_name) end
    menu.set = function(widget_name, value) set_value(menu, widget_name, value) end
    menu.checkbox = function(...) return add_checkbox(menu, ...) end
    menu.label = function(...) return add_label(menu, ...) end
    menu.button = function(...) return add_button(menu, ...) end
    menu.progressbar = function(...) return add_progressbar(menu, ...) end
    menu.slider = function(...) return add_slider(menu, ...) end
    menu.checkbutton = function(...) return add_checkbutton(menu, ...) end
    menu.keydown = function(...) return add_keydown(menu, ...) end
    menu.keytoggle = function(...) return add_keytoggle(menu, ...) end
    menu.keymapper = function(...) return add_keymapper(menu, ...) end
    menu.permashow = function(...) return add_permashow(menu, ...) end    
    
    load_menu(menu) -- prep associated data, check with get_loaded_value(menu, widget)
    
    local cfg = make_config_table(menu)
    return cfg, menu
end

local function add_menu(name, width)    
    local cfg, menu = make_menu(name, width)
    menus[name] = menu
    return cfg, menu
end

-- must be after widget is added
function add_permashow(menu, name)    
    local id = make_id(menu, name)
    local widget = all_widgets[id]
    widget.scriptnum = GetScriptNumber()
    if widget ~= nil then
        if permashow[menu] == nil then
            permashow[menu] = {}
        end
        table.insert(permashow[menu], widget)
    end
end

local function define_options()
    local changed
    options_cfg, options_menu = make_menu('Options', nil, '_uiconfig_options')
    
    options_menu.slider('permashow_width','Permashow Width',140,300,180)
    
    options_menu.checkbutton('permashow_toggle', '', false).tick = function(widget)
        -- todo: allow checkbuttons to change label automatically based on state, label_off=""
        -- todo: allow checkbuttons to reverse logic so down is false and up is true
        if not widget.value then 
            widget.text = 'Permashow Enabled'
        else
            widget.text = 'Permashow Disabled'
        end
    end
    
    options_menu.keydown('uiconfig_key', 'UIConfig Key', Keys.ShiftKey)

    options_menu.button('save_button', 'Save All').onchange = function(widget)
        save()
    end
        
    options_menu.label('timetosave_label', '').tick = function(widget)
        local time_to_save = math.ceil(next_autosave - os.clock())
        local time_to_save_label = string.format('Next autosave in %d', time_to_save)
        widget.label = time_to_save_label
    end

end

local function init()
    assert(Keys~=nil, 'The Keys module is required')
    for k,v in pairs(Keys) do
        key_names[v] = k
    end
    load()
    define_options()
end

RegisterLibraryOnTick(tick)
RegisterLibraryOnWndMsg(on_wnd_msg)
init()

return {
    add_menu = add_menu,
    menus = menus -- debug
}