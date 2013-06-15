-- simpleui.lua
--
-- v00 - 5/27/2013 2:45:53 PM - preview release
-- v01 - 5/31/2013 12:14:53 PM - initial release, requires utils 2.0.4+
-- v02 - 5/31/2013 2:12:37 PM - important changes to work with multiple ui.tick calls
-- v03 - 6/1/2013 3:21:13 PM - minor handle drag fix, optional label color
--
-- todo: control_changed(uiid), control_value(uiid)
-- later: tweak drawing

local draw = require 'simpleui_drawing'
local round = draw.round
local Point = draw.Point
local Rectangle = draw.Rectangle

local debug_draw_hotspots = false
local debug_draw_debuglines = false
local debuglines = {}

local layout_stack = {}

-- these are in utils already
--local WM_LBUTTONDOWN = 0x0201
--local WM_LBUTTONUP = 0x0202

UIStep_None = 0
UIStep_Create = 1
UIStep_Init = 2
UIStep_Logic = 3
UIStep_Draw = 4

local uistate = {}
uistate.hotitem = ''
uistate.focusitem = ''
uistate.activatingitem = ''
uistate.activateditem = ''
uistate.step = UIStep_None
uistate.hotspots = {}
uistate.mouselocation = {0,0}
uistate.focuspoint = {0,0}
uistate.leftpress = false
uistate.leftheld = false
uistate.leftrelease = false

local function Hotspot(id, rect)
    assert(id ~= nil, 'hotspot with nil id')
    assert(rect ~= nil, 'hotspot with nil rect')
    return {
        id = id,
        rect = rect
    }
end

local function clamp(value, x1, x2)
    return math.min(math.max(value, x1), x2)
end

local function rectangle_contains(rect, pt)
    local x2 = rect.X + rect.Width
    local y2 = rect.Y + rect.Height
    return (pt.X >= rect.X and pt.X <= x2 and pt.Y >= rect.Y and pt.Y <= y2)
end

local function DrawState()
    return {
        Hot = false,
        Focused = false,
        Activating = false,
        Activated = false
    }
end

local function calc_drawstate(uiid)
    local ishot = uistate.hotitem == uiid
    local isfocus = uistate.focusitem == uiid
    local isactivating = uistate.activatingitem == uiid
    local isactivated = uistate.activateditem == uiid
    local state = DrawState()
    if (ishot) then state.Hot = true end
    if (isfocus) then state.Focused = true end
    if (isactivating) then state.Activating = true end
    if (isactivated) then state.Activated = true end
    return state
end

local function layout_peek()
    if #layout_stack == 0 then
        return nil
    else
        return layout_stack[#layout_stack]
    end
end
-- modes: 'none', 'vertical', 'horizontal', later: 'grid', 'columns', 'rows'
local function layout_push(mode, padding, x, y) -- last 3 params are optional, inherited from containing layout
    -- get x and y from the current layout, if one exists
    --print('layout_push', mode, padding, x, y)
    local current = layout_peek()
    if current ~= nil then
        --print('inheriting from current')
        -- inherit x and y
        if x == nil then
            --print('inherit layout x', current.x)
            x = current.x
        end
        if y == nil then
            --print('inherit layout y', current.y)
            y = current.y
        end
        -- inherit padding
        if padding == nil then
            padding = current.padding
        end
    end
    local layout = {x=x, y=y, ox=x, oy=y, mode=mode, padding=padding, maxw=0, maxh=0}
    --print('pushing layout', mode, padding, x, y, layout.ox, layout.oy)
    table.insert(layout_stack, layout)
    return layout -- so you can modify it
end
local function layout_increment(rect)
    local layout = layout_peek()
    if layout ~= nil then
        if layout.mode=='vertical' then
            layout.y = layout.y + rect.Height + layout.padding
        elseif layout.mode=='horizontal' then
            layout.x = layout.x + rect.Width + layout.padding
        end
        if layout.mode~='none' then
            layout.maxw = math.max(layout.maxw, rect.Width)
            layout.maxh = math.max(layout.maxh, rect.Height)
        end
    end
end
local function layout_pop(increment)
    if increment == nil then increment = true end
    local result = table.remove(layout_stack)
    -- increment underlying layout by popped layout
    local current = layout_peek()
    if current ~= nil and increment then
        local dx = result.x - result.ox
        local dy = result.y - result.oy
        --print('popping, delta x,y:', w, h)
        --print('popping, max w,h:', result.maxw, result.maxh)
        layout_increment(Rectangle(nil,nil,result.maxw,result.maxh))
    end
    return result
end
-- modify the rect based on layout
local function layout_transform(rect)
    local layout = layout_peek()
    if layout ~= nil and layout.mode ~= 'none' then
        --print('layout_transform', rect.X, rect.Y, '>', layout.x, layout.y)
        rect.X = layout.x
        rect.Y = layout.y
    end
end

local function on_wnd_msg(msg, key)
    --printtext('.')
    if msg==WM_LBUTTONDOWN then
        --printtext('v')
        uistate.leftpress = true
        uistate.leftheld = true
    elseif msg==WM_LBUTTONUP then
        --printtext('^')
        uistate.leftrelease = true
        uistate.leftheld = false
    end
end

-- collect ticks here, run them later
local tick_functions = {}
local function tick(fn)
    table.insert(tick_functions, fn)
    --print('inserting tick function')
end

local function run_all_ticks()
    --print('run_all_ticks', uistate.step, #tick_functions)
    for i,fn in ipairs(tick_functions) do
        --print('!')
        fn()
    end
end

local function main_loop(fn)
    --print('main_loop')
    assert(fn~=nil, 'fn is nil')
    
    uistate.hotspots = {}
    uistate.hotitem = ''
    uistate.mouselocation = Point(GetCursorX(), GetCursorY())

    uistate.step = UIStep_Init
    fn()

    for i=1,#uistate.hotspots do
        local hotspot = uistate.hotspots[i]
        if (not uistate.leftpress and uistate.leftheld) then
            uistate.hotitem = uistate.focusitem
            break -- don't make items hot when mouse down unless they are also the focus item
        end
        if (rectangle_contains(hotspot.rect, uistate.mouselocation)) then
            uistate.hotitem = hotspot.id
            break
        end
    end

    uistate.step = UIStep_Logic
    fn()

    if debug_draw_debuglines then
        table.insert(debuglines, string.format('hotitem: %s', uistate.hotitem))
        table.insert(debuglines, string.format('focusitem: %s', uistate.focusitem))
        table.insert(debuglines, string.format('activatingitem: %s', uistate.activatingitem))
        table.insert(debuglines, string.format('activateditem: %s', uistate.activateditem))
        table.insert(debuglines, string.format('mouse x: %d', uistate.mouselocation.X))
        table.insert(debuglines, string.format('mouse y: %d', uistate.mouselocation.Y))
        table.insert(debuglines, string.format('leftpress: %s', tostring(uistate.leftpress)))
        table.insert(debuglines, string.format('leftheld: %s', tostring(uistate.leftheld)))
        table.insert(debuglines, string.format('leftrelease: %s', tostring(uistate.leftrelease)))
        DrawText(table.concat(debuglines,'\n'), 800, 50, 0xffff0000)    
        debuglines = {}
    end

    uistate.step = UIStep_Draw
    fn()

    if (debug_draw_hotspots) then
        for i=1,#uistate.hotspots do
            local hotspot = uistate.hotspots[i]
            draw.rectangle(hotspot.rect, 0x7fff0000)
        end
    end

    -- reset before next tick
    uistate.leftpress = false
    uistate.leftrelease = false
    layout_stack = {}

end

local function on_lb_tick()
    --local start = os.clock()
    main_loop(run_all_ticks)
    tick_functions = {}
    --local stop = os.clock()
    --local dt = (stop-start)*1000
    --if dt > 1 then
    --    print('simpleui dt', dt)
    --end
end

local function add_hotspot(uiid, rect)
    layout_transform(rect)
    assert(rect.X ~= nil, 'rect.X cannot be nil')
    assert(rect.Y ~= nil, 'rect.Y cannot be nil')
    assert(rect.Width ~= nil, 'rect.Width cannot be nil')
    assert(rect.Height ~= nil, 'rect.Height cannot be nil')
    local hotspot = Hotspot(uiid, rect)
    table.insert(uistate.hotspots, hotspot)
end

local function standard_logic(uiid, activatingtrigger, activatedtrigger)
    if activatingtrigger == nil then activatingtrigger = uistate.leftpress end
    if activatedtriggerl == nil then activatedtrigger = uistate.leftrelease end

    local just_activated = false
    local just_activating = false

    if (uistate.hotitem == uiid) then
        if (activatingtrigger) then
            uistate.focusitem = uiid
            uistate.activatingitem = uiid
            just_activating = true
        end
        if (uistate.focusitem == uiid) then
            if (uistate.activatingitem == uiid) then
                if (activatedtrigger) then
                    uistate.activateditem = uiid
                    just_activated = true
                end
            end
        end
    end

    if (activatedtrigger and uistate.activatingitem == uiid) then
        uistate.activatingitem = ''
        uistate.activateditem = uiid
    end

    return just_activated, just_activating
end

-- optional color
local function do_label(id, text, rect, color)
    if uistate.step == UIStep_Init then
        layout_increment(rect)
    elseif uistate.step == UIStep_Logic then
        -- pass
    elseif uistate.step == UIStep_Draw then
        layout_transform(rect)
        local valign = draw.vertical_center_text(rect)
        draw.label(text, valign, color)
        layout_increment(rect)
    end
end

local function do_rectangle(uiid, rect, color)
    if uistate.step == UIStep_Init then
        layout_increment(rect)
    elseif uistate.step == UIStep_Logic then
        return false
    elseif uistate.step == UIStep_Draw then
        local state = calc_drawstate(uiid)
        layout_transform(rect)
        draw.rectangle(rect, color)
        layout_increment(rect)
    end
    return false
end

local function do_button(uiid, text, rect)
    if uistate.step == UIStep_Init then
        add_hotspot(uiid, rect)
        layout_increment(rect)
    elseif uistate.step == UIStep_Logic then
        return standard_logic(uiid)
    elseif uistate.step == UIStep_Draw then
        local state = calc_drawstate(uiid)
        layout_transform(rect)
        draw.button(text, rect, state)
        layout_increment(rect)
    end
    return false
end

-- returns changed, new_value
-- result, my_bool = do_checkbox('checkbox-a', Rectangle(x,y,w,h), my_bool)
local function do_checkbox(uiid, rect, value)
    if uistate.step == UIStep_Init then
        add_hotspot(uiid, rect)
        layout_increment(rect)
    elseif uistate.step == UIStep_Logic then
        if standard_logic(uiid) then
            return true, not value
        end
    elseif uistate.step == UIStep_Draw then
        local state = calc_drawstate(uiid)
        layout_transform(rect)
        draw.checkbox(uiid, rect, state, value)
        layout_increment(rect)
    end
    return false, value
end

-- returns changed, new_value (when clamped)
local function do_progressbar(uiid, rect, max, value)    
    assert(uiid ~= '', 'id cannot be blank')
    assert(max ~= nil, 'max cannot be nil')
    if uistate.step == UIStep_Init then
        layout_increment(rect)
    elseif uistate.step == UIStep_Logic then
        local clamped_value = clamp(value, 0, max)
        if clamped_value ~= value then
            return true, clamped_value
        end
    elseif uistate.step == UIStep_Draw then
        -- todo: just pass uistate?
        local state = calc_drawstate(uiid)
        layout_transform(rect)
        draw.progressbar(uiid, rect, state, max, value)
        layout_increment(rect)
    end
    return false, value
end

local function do_slider(uiid, rect, min, max, value, fractional)    
    assert(uiid ~= '', 'id cannot be blank')
    assert(rect ~= nil, 'rect cannot be nil')
    assert(min ~= nil, 'min cannot be nil')
    assert(max ~= nil, 'max cannot be nil')
    assert(value ~= nil, 'value cannot be nil')
    local result = false
    if uistate.step == UIStep_Init then
        -- todo: cache hotspots? ya
        add_hotspot(uiid, rect)
        layout_increment(rect)
    elseif uistate.step == UIStep_Logic then
	    layout_transform(rect)
        local x = rect.X
        local y = rect.Y
	    local w = rect.Width
	    local h = rect.Height
	    local range = max - min

        local just_activated = standard_logic(uiid)

        if (uistate.focusitem == uiid and uistate.activatingitem == uiid) then
            local mousepos = uistate.mouselocation.X - x
            mousepos = clamp(mousepos, 0, w)
            -- range / w == units per pixel
            local v = mousepos * (range / w) + min
            if not fractional then
                v = round(v, 0)
            end
            if (v ~= value) then
                result = true
                value = v
            end
        end
    elseif uistate.step == UIStep_Draw then
        -- todo: just pass uistate?
        local state = calc_drawstate(uiid)
        layout_transform(rect)
        draw.slider(uiid, rect, state, min, max, value)
        layout_increment(rect)
    end
    return result, value
end

local function do_checkbutton(uiid, text, rect, value)
    assert(uiid ~= '', 'id cannot be blank')
    local result = false
    if uistate.step == UIStep_Init then
        add_hotspot(uiid, rect)
        layout_increment(rect)
    elseif uistate.step == UIStep_Logic then
        local just_activated = standard_logic(uiid)
        if (just_activated) then
            result = true
            value = not value
        end
    elseif uistate.step == UIStep_Draw then
        local state = calc_drawstate(uiid)
        layout_transform(rect)
        draw.checkbutton(text, rect, state, value)
        layout_increment(rect)
    end
    return result, value
end

-- you can drag it around... anywhere.
local activated_delta_x = 0
local activated_delta_y = 0
local function do_handle(uiid, rect, value1, value2)
    assert(uiid ~= '', 'id cannot be blank')
    assert(rect ~= nil, 'rect cannot be nil')
    local result = false
    if uistate.step == UIStep_Init then
        -- todo: cache hotspots? ya
        add_hotspot(uiid, rect)
        layout_increment(rect)
    elseif uistate.step == UIStep_Logic then
	    layout_transform(rect)
	    local x = rect.X
	    local y = rect.Y
	    local w = rect.Width
	    local h = rect.Height
	    local i = w

        local just_activated, just_activating = standard_logic(uiid)
        if just_activating then
            activated_delta_x = uistate.mouselocation.X - value1 -- rect.X
            activated_delta_y = uistate.mouselocation.Y - value2 -- rect.Y
        end

        if (uistate.activatingitem == uiid) then
            --local mousepos = uistate.mouselocation.X - x
            --mousepos = clamp(mousepos, 0, i)
            --local v = round(mousepos * max / i, 0)
            --if (v ~= value) then
                result = true                
                value1 = uistate.mouselocation.X - activated_delta_x
                value2 = uistate.mouselocation.Y - activated_delta_y
            --end
        end
        --draw.text('x',uistate.mouselocation.X-5,uistate.mouselocation.Y-5,0xffff0000)
    elseif uistate.step == UIStep_Draw then
        -- todo: just pass uistate?
        local state = calc_drawstate(uiid)
        layout_transform(rect)
        draw.handle(uiid, rect, state)
        layout_increment(rect)
    end
    return result, value1, value2
end

if SetTimerCallback == nil then
    function GetFontSize() return 12 end
    function GetMessage() end
    function GetCursorX() return 10 end
    function GetCursorY() return 10 end
    function DrawText(...) print('DrawText', ...) end
    function DrawBox(...) print('DrawBox', ...) end
    ui_main()
end

RegisterLibraryOnTick(on_lb_tick)
RegisterLibraryOnWndMsg(on_wnd_msg)

return {
    tick = tick,
    Hotspot = Hotspot,
    round = round,
    clamp = clamp,
    rectangle_contains = rectangle_contains,
    DrawState = DrawState,
    calc_drawstate = calc_drawstate,
    layout_push = layout_push,
    layout_pop = layout_pop,
    layout_peek = layout_peek,
    layout_transform = layout_transform,
    layout_increment = layout_increment,
    on_wnd_msg = on_wnd_msg,
    add_hotspot = add_hotspot,
    standard_logic = standard_logic,
    --
    label = do_label,
    rectangle = do_rectangle,
    button = do_button,
    checkbox = do_checkbox,
    progressbar = do_progressbar,
    slider = do_slider,
    checkbutton = do_checkbutton,
    handle = do_handle,
    --
    state = uistate
}