-- uiconfig
--
-- v01 - 5/31/2013 12:02:09 PM - initial release, requires utils 2.0.4+, simpleui v01+, winapi v06+
-- v02 - 5/31/2013 7:08:26 PM - keymapper widget, all add_* functions return widget, widget tick property

-- later: alternative add_* functions that take a table add_label{foo=bar, etc=whatever}
-- later: allow keys to adjust widget values? meh
-- later: root checkbuttons take up extra space when checked... how!?323456

-- 2 ways to get/set values
-- cfg.Name, cfg.Name = 42, or... root_table.get(), root_table.set()
-- 2 ways to add widgets
-- add_label('My Config',...), or... cfg.add_label(...)

require 'Keys'
require 'winapi'
local ui = require 'simpleui'
local draw = require 'simpleui_drawing'
local Rectangle = draw.Rectangle
local Color = draw.Color

local roots = {}
local all_widgets = {}
local background_logic = {}

local folder = 'uiconfig'
local selfconfig = folder..'\\_uconfig.txt'
local uiconfig_key = Keys.ShiftKey
local line_height = math.ceil(GetFontSize()*2)

local ox, oy = 400, 100
local loaded = false
local save_interval = 10
local frame = 0 -- frame counter
local capture_next_key = false -- for keymapper
local captured_key = nil

local function make_id(root, name)
    return root..':'..name
end

local function add_widget(root, widget)
    widget.id = make_id(root, widget.name)
    table.insert(roots[root].widgets, widget)
    all_widgets[widget.id] = widget
    if widget.background_logic and widget.logic ~= nil then
        background_logic[widget.id] = widget
    end
end

local function get_value(root, name)
    local id = make_id(root, name)
    return all_widgets[id].value    
end

local function set_value(root, name, value)
    local id = make_id(root, name)
    all_widgets[id].value = value
end

local function make_root_value_table(root)
    local proxy = {}
    local mt = {}
    mt.__index = function (table, key)
        return get_value(root, key)
    end
    mt.__newindex = function (table, key, value)
        set_value(root, key, value)
    end    
    setmetatable(proxy, mt)
    return proxy
end

-- convenience
local function add_checkbox(root, name, label, value)
    local widget = {}
    widget.kind = 'checkbox'
    widget.name = name
    widget.label = label
    widget.value = value
    add_widget(root, widget)
    return widget
end

local function add_label(root, name, label)
    local widget = {}
    widget.kind = 'label'
    widget.name = name
    widget.label = label
    add_widget(root, widget)
    return widget
end

local function add_button(root, name, text, value)
    local widget = {}
    widget.kind = 'button'
    widget.name = name
    widget.text = text
    widget.value = value
    add_widget(root, widget)
    return widget
end

local function add_progressbar(root, name, max, value)
    local widget = {}
    widget.kind = 'progressbar'
    widget.name = name
    widget.max = max
    widget.value = value
    add_widget(root, widget)
    return widget
end

local function add_slider(root, name, label, min, max, value, valuemap, fractional)
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
    add_widget(root, widget)
    return widget
end

local function add_checkbutton(root, name, text, value)
    local widget = {}
    widget.kind = 'checkbutton'
    widget.name = name
    widget.text = text
    widget.value = value
    add_widget(root, widget)
    return widget
end

function lookup_key_name(key)
    for name,value in pairs(Keys) do
        if key == value then
            return name
        end
    end
end

-- annoyance
local function do_bool_indicator(widget)
    if widget.cache == nil then
        widget.keyname = lookup_key_name(widget.key)
        widget.cache = true
    end
    local changed = false
    local uiid = widget.id
    local label, rect, value = widget.label, widget.rect, widget.value
    ui.layout_push('horizontal')
    local rect1 = draw.rectangle_copy(rect)
    rect1.Width = draw.round(rect.Width*.8)
    local rect2 = draw.rectangle_copy(rect)
    rect2.Width = rect.Width-rect1.Width
    rect2.X = rect.Width
    if widget.keyname ~= nil then
        label = string.format('%s [%s]', label, widget.keyname)
    end
    ui.label(uiid..' label', label, rect1)
    local uistate = ui.state
    if uistate.step == UIStep_Init then
        ui.layout_increment(rect2)
    elseif uistate.step == UIStep_Logic then
        --return standard_logic(uiid)
        if widget.logic ~= nil then
            changed, value = widget.logic(widget)
        end
    elseif uistate.step == UIStep_Draw then
        local state = ui.calc_drawstate(uiid)
        ui.layout_transform(rect2)
        local text
        if value then text = 'ON' else text = 'OFF' end
        draw.checkbutton(text, rect2, state, value)
        ui.layout_increment(rect2)
    end
    ui.layout_pop()
    return changed, value
end

local function make_key_logic(key, toggle)
    local prev_state = winapi.get_async_key_state(key)
    return function(widget)
        local state = winapi.get_async_key_state(widget.key)
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

local function add_keydown(root, name, label, key)
    local rect = Rectangle(nil, nil, 140, line_height)
    local widget = {fn=do_bool_indicator, name=name, label=label, value=false, rect=rect, logic=make_key_logic(key), background_logic=true, key=key}
    add_widget(root, widget)
    return widget
end

local function add_keytoggle(root, name, label, key, default)
    local rect = Rectangle(nil, nil, 140, line_height)
    local widget = {fn=do_bool_indicator, name=name, label=label, value=default, rect=rect, logic=make_key_logic(key, true), background_logic=true, key=key}
    add_widget(root, widget)
    return widget
end

local function do_keymapper(widget)
    if widget.cache == nil then        
        widget.keyname = lookup_key_name(widget.value)        
        widget.checkbutton_value = false
        widget.cache = true
    end
    local checkbutton_text
    local changed = false
    local uiid = widget.id

    ui.label(uiid..' label', widget.label, widget.rect)
    
    -- if cb is down and we are waiting for a key, then change the message
    if widget.checkbutton_value and capture_next_key then
        checkbutton_text = '<press a key>'
    else
        checkbutton_text = widget.keyname
    end

    -- if cb is down, and we captured a key, then deal with it(tm)
    if widget.checkbutton_value and captured_key ~=nil then
        changed = true
        widget.value = captured_key
        widget.keyname = lookup_key_name(widget.value)
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
local function add_keymapper(root, name, label, default)
    local rect = Rectangle(nil, nil, 140, line_height)
    local widget = {fn=do_keymapper, name=name, label=label, value=default, rect=rect}
    add_widget(root, widget)
    return widget
end

local function get_filename(root)
    return folder..'\\'..root..'.txt'
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

local function save()
    --print('uiconfig saving...')
    for root, menu in pairs(roots) do
        local dict = {}
        local changed = false
        for i,widget in ipairs(menu.widgets) do
            dict[widget.name] = widget.value
            -- doesnt work, care later (because changed only try during one ui step)
            --if not changed and widget.changed then
            --    changed = true
            --end
            --print(root, widget.name, widget.value)
        end
        if true or changed then -- later: change detection
            local fn = get_filename(root)
            save_dictionary(fn, dict)
        end
    end
    -- save self
    assert(ox~=nil, 'ox is nil')
    assert(oy~=nil, 'oy is nil')
    save_dictionary(selfconfig, {ox=ox, oy=oy})
end

local function consider_save()
    if true then
        save()
    end
end

local function load()
    --print('uiconfig loading...')
    local data = {} -- {root_name:{k=v,...}}
    -- first read all data
    for root, menu in pairs(roots) do                
        local fn = get_filename(root)
        data[root] = load_dictionary(fn)
    end
    -- now try to associate it
    for root, menu in pairs(roots) do
        for i,widget in ipairs(menu.widgets) do
            if data[root] and data[root][widget.name] then
                --print('found widget with saved data', root, widget.name)
                local s = data[root][widget.name]                
                local value
                if s=='true' then
                    value = true
                elseif s=='false' then
                    value = false
                else
                    value = tonumber(s)
                end
                set_value(root, widget.name, value)
                --print('set value', value)
            end
        end
    end    
    -- load self
    local dict = load_dictionary(selfconfig)
    if dict.ox ~= nil then ox = tonumber(dict.ox) end
    if dict.oy ~= nil then oy = tonumber(dict.oy) end
end

local function do_load()
    if not loaded then
        load()
        loaded = true
    end
end

function do_save()
    frame = frame + 1
    if frame == 20*save_interval then
        frame = 0
        consider_save()
    end
end

local function do_widget(widget)
    local one = line_height/2
    local two = line_height
    if widget.tick ~= nil then
        widget.tick(widget)
    end
    --print('do_widget', widget.id)
    if widget.kind == 'checkbox' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,two,two)
            widget.labelid = widget.id..' label'
            widget.labelrect = Rectangle(nil,nil,140-two-ui.layout_peek().padding*2,two)
            widget.cache = true
        end
        ui.layout_push('horizontal')
        widget.changed, widget.value = ui.checkbox(widget.id, widget.rect, widget.value)
        ui.label(widget.labelid, widget.label, widget.labelrect)
        ui.layout_pop()
    elseif widget.kind == 'label' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,140,two)
            widget.cache = true
        end
        ui.label(widget.id, widget.label, widget.rect)
    elseif widget.kind == 'button' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,140,two)
            widget.cache = true
        end
        widget.changed = ui.button(widget.id, widget.text, widget.rect)
    elseif widget.kind == 'progressbar' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,140,two)
            widget.cache = true
        end
        widget.changed, widget.value = ui.progressbar(widget.id, widget.rect, widget.max, widget.value)
    elseif widget.kind == 'slider' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,140,two)
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
            valuelabel = widget.valuemap[widget.value+1]
        end
        ui.label(widget.valuelabel_id, valuelabel, widget.valuelabel_rect)
        ui.layout_pop()
    elseif widget.kind == 'checkbutton' then
        if widget.cache == nil then
            widget.rect = Rectangle(nil,nil,140,two)
            widget.cache = true
        end
        widget.changed, widget.value = ui.checkbutton(widget.id, widget.text, widget.rect, widget.value)
    else
        if widget.fn ~= nil then
            widget.changed, widget.value = widget.fn(widget)
        end
    end
end

local rootw, rooth = 0,0
local subw, subh = 0,0
local active_root = nil
local panelbg = Color(0.5,0.5,0.5,0.5)
local function do_ui()
    local one = line_height/2
    local two = line_height
    local changed
    
    changed, ox, oy = ui.handle('uiconfig_handle', Rectangle(ox-one,oy-two-1,140+two,one), ox, oy)

    local root_rect = Rectangle(ox-one,oy-one,rootw+two,rooth+two-4)
    ui.rectangle('root panel', root_rect, panelbg)

    -- sort roots by name, case insensitive
    local sorted = {}
    for name in pairs(roots) do table.insert(sorted, name) end
    table.sort(sorted, function(a,b) return a:lower() < b:lower() end)

    ui.layout_push('vertical', 2, ox, oy)
    --for key,t in pairs(roots) do
    for i,key in ipairs(sorted) do
        local t = roots[key]
        --print('root', key, t.value, #t.widgets)
        local id = 'uiconfig_root:'..key
        local text = key
        local rect = Rectangle(nil,nil,140,two)
        changed, t.value = ui.checkbutton(id, text, rect, t.value)
        -- make all other root checkbuttons false when one changes to true
        if changed and t.value then
            active_root = id
        end
        if id ~= active_root then
            t.value = false
        end
        if t.value then
            local curr_layout = ui.layout_peek()
            local subpad = curr_layout.padding
            local subx = curr_layout.x+140+one+one+curr_layout.padding
            --local suby = curr_layout.y-20+10-curr_layout.padding
            local suby = curr_layout.oy

            ui.layout_push('none')
            local sub_rect = Rectangle(subx-one,suby-one,subw+two,subh+two-4)
            --print(sub_rect.X, sub_rect.Y, sub_rect.Width, sub_rect.Height)
            ui.rectangle(key..'sub panel', sub_rect, panelbg)
            ui.layout_pop()

            ui.layout_push('vertical', subpad, subx, suby)
            ui.label(key..' title label', key, Rectangle(nil,nil,140,two))
            ui.rectangle(key..' title hline', Rectangle(nil,nil,140,2), draw.normal_face)
            for j,widget in ipairs(t.widgets) do
                do_widget(widget)
            end
            local sub_layout = ui.layout_pop(false)
            if ui.state.step == UIStep_Init then
                subw, subh = sub_layout.maxw, sub_layout.y - sub_layout.oy
                -- todo: make this a function, layout_dimensions(), and it only operates in init?
            end
        end
    end

    local root_layout = ui.layout_pop()
    if ui.state.step == UIStep_Init then
        rootw, rooth = root_layout.maxw, root_layout.y - root_layout.oy
        -- same todo as above
    end
end

local function tick()
    -- load must be after the one time ui definition
    do_load()
    do_save()

    if KeyDown(uiconfig_key) then
        ui.tick(do_ui)
    else
        -- run background widget logic (for keydown junk)
        for id,widget in pairs(background_logic) do
            if widget ~= nil and widget.logic ~= nil then
                widget.changed, widget.value = widget.logic(widget)
            end
        end
    end
end

local function on_wnd_msg(msg, key)    
    if msg==KEY_DOWN then
        if capture_next_key then
            if key ~= uiconfig_key then -- ignore the menu key they are holding down
                if KeyDown(uiconfig_key) then -- but, also, only capture the key if they are showing the menu
                    captured_key = key
                    capture_next_key = false
                end
            end
        end
    end
end

-- sick of locals order nonsense
local function add_root(name, width)
    local t = {name=name, value=false, widgets={}}
    -- defaults
    t.width = width -- todo: make this happen
    t.get = function(widget_name) return get_value(name, widget_name) end
    t.set = function(widget_name, value) set_value(name, widget_name, value) end
    t.checkbox = function(...) return add_checkbox(name, ...) end
    t.label = function(...) return add_label(name, ...) end
    t.button = function(...) return add_button(name, ...) end
    t.progressbar = function(...) return add_progressbar(name, ...) end
    t.slider = function(...) return add_slider(name, ...) end
    t.checkbutton = function(...) return add_checkbutton(name, ...) end
    t.keydown = function(...) return add_keydown(name, ...) end
    t.keytoggle = function(...) return add_keytoggle(name, ...) end
    t.keymapper = function(...) return add_keymapper(name, ...) end
    roots[name] = t    
    --print('added root', name, roots[name]~=nil)
    return make_root_value_table(name), t
end

RegisterLibraryOnTick(tick)
RegisterLibraryOnWndMsg(on_wnd_msg)

return {
    add_menu = add_root,
    roots = roots -- debug
}