-- simpleui_drawing.lua
--
-- v00 - 5/27/2013 2:23:05 PM - preview release
-- v01 - 5/31/2013 12:15:54 PM - initial release
-- v02 - 6/6/2013 8:59:42 PM - draw_text doesn't complain about a nil string

local font_size = GetFontSize()

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function Color(r, g, b, a)
    if a == nil then a = 1 end
    local r2 = math.floor(r * 255)
    local g2 = math.floor(g * 255)
    local b2 = math.floor(b * 255)
    local a2 = math.floor(a * 255)
    if (bit) then
        return ( bit.bor( bit.lshift(a2,24), bit.lshift(r2,16), bit.lshift(g2,8), b2 ) )
    else
        return ( a2*(2^24) + r2*(2^16) + g2*(2^8) + b2 )
    end
end

local default_text_color = Color(1,1,1)

local normal_back = Color(0.5,0.5,0.5,0.6)
local normal_face = Color(0,0,0,0.6)
local raised_back = Color(0.5,0.5,0.5)
local raised_face = Color(0.8,0.8,0.8)
local hot_back = Color(1,1,1,1)
local hot_face = Color(0,0,0.5,1)
local activating_back = Color(0.25,0.25,0.25,1)
local activating_face = Color(0,0,0.5,1)
local focus_back = normal_back
local focus_face = normal_face

local accent = Color(0.2, 0.2, 0.8, 0.8)

-- todo: get rid of all these, and return/send multivalues instead?
local function Point(x, y)
    return {
        X=x,
        Y=y
    }
end

local function Rectangle(x, y, width, height)
    return {
        X = x,
        Y = y,
        Width = width,
        Height = height,
    }
end

local function vertical_center(rect1, rect2)
    local height_delta = rect1.Height - rect2.Height
    local y_offset = math.floor( height_delta / 2 )
    local result = Point(rect1.X, rect1.Y + y_offset)
    return result
end

local function vertical_center_text(rect)    
    local hack_font_size = round(font_size*1.7)
    local pos = vertical_center(rect, Rectangle(rect.X, rect.Y, rect.Width, hack_font_size))
    assert(pos~=nil, 'pos is nil')
    return pos
end

local function rectangle_center(rect)
    return Point(rect.X + rect.Width / 2, rect.Y + rect.Height / 2)
end

local function rectangle_offset(rect, offset)
    return Rectangle(rect.X + offset, rect.Y + offset, rect.Width, rect.Height)
end

local function rectangle_erode(rect, amount)
    return Rectangle(rect.X+amount, rect.Y+amount, rect.Width-amount*2, rect.Height-amount*2)
end

local function rectangle_dilate(rect, amount)
    return rectangle_erode(rect, amount * -1)
end

local function rectangle_underline(rect, size)
    return Rectangle(rect.X, rect.Y+rect.Height-size, rect.Width, size)
end

local function rectangle_copy(rect)
    return Rectangle(rect.X, rect.Y, rect.Width, rect.Height)
end

local function point_translate(pt, x, y)
    pt.X = pt.X + x
    pt.Y = pt.Y + y
    return pt
end

local function draw_text(text, x, y, color)
    if text==nil then text = '' end
    if color==nil then color = default_text_color end
    DrawText(text, x, y, color)
end

local function draw_rectangle(rect, color)
    DrawBox(rect.X,rect.Y,rect.Width,rect.Height,color)
end

--

local function draw_label(text, pt, color)
    draw_text(text, pt.X, pt.Y, color)
end

local function draw_button(text, rect, state)
    local rect1 = rectangle_erode(rect, 1)
    local rect2 = rectangle_erode(rect, 2)

    if (state.Activating) then
        draw_rectangle(rect, activating_back)
        draw_rectangle(rect1, activating_face)
    elseif (state.Hot) then
        draw_rectangle(rect, hot_back)
        draw_rectangle(rect1, hot_face)
    --elseif (state.Focused) then
    --    draw_rectangle(rect, focus_back)
    --    draw_rectangle(rect1, focus_face)
    else -- normal
        draw_rectangle(rect, normal_back)
        draw_rectangle(rect1, normal_face)
    end

    local valign = point_translate(vertical_center_text(rect1), 3, 0)
    if (state.Activating) then
        valign = point_translate(valign,1,1)
        draw_label(text, valign)
    else
        draw_label(text, valign)
    end
end

local function draw_checkbox(uiid, rect, state, value)
    local rect1 = rectangle_erode(rect, 1)
    local rect2 = rectangle_erode(rect, 4)
    
    if (state.Activating) then
        draw_rectangle(rect, activating_back)
        draw_rectangle(rect1, activating_face)
    elseif (state.Hot) then
        draw_rectangle(rect, hot_back)
        draw_rectangle(rect1, hot_face)
    --elseif (state.Focused) then
    --    draw_rectangle(rect, focus_back)
    --    draw_rectangle(rect1, focus_face)
    else -- normal
        draw_rectangle(rect, normal_back)
        draw_rectangle(rect1, normal_face)
    end

    if (not value and state.Activating) or value then
        draw_rectangle(rect2, 0xffffffff)
    end
end

local function draw_progressbar(uiid, rect, state, max, value)
    local rect1 = rectangle_erode(rect, 1)
    local rect2 = rectangle_erode(rect, 2)
    local rect3 = rectangle_erode(rect, 3)

    if (state.Activating) then
        draw_rectangle(rect, activating_back)
        draw_rectangle(rect1, activating_face)
    elseif (state.Hot) then
        draw_rectangle(rect, hot_back)
        draw_rectangle(rect1, hot_face)
    --elseif (state.Focused) then
    --    draw_rectangle(rect, focus_back)
    --    draw_rectangle(rect1, focus_face)
    else -- normal
        draw_rectangle(rect, normal_back)
        draw_rectangle(rect1, normal_face)
    end

    local progrect = Rectangle(rect3.X, rect3.Y, rect3.Width * (value / max), rect3.Height)
    draw_rectangle(progrect, accent)
end

local function draw_slider(uiid, rect, state, min, max, value)
    local rect1 = rectangle_erode(rect, 1)
    local rect2 = rectangle_erode(rect, 2)
    local rect3 = rectangle_erode(rect, 3)
    local rect4 = rectangle_erode(rect, 4)
    local rect5 = rectangle_erode(rect, 5)
    
    local range = max - min
    local absvalue = value
    local value = absvalue - min -- relative value
    --if (state.Activating) then
    --    draw_rectangle(rect, activating_back)
    --    draw_rectangle(rect1, activating_face)
    --if (state.Hot) then
        
    --elseif (state.Focused) then
    --    draw_rectangle(rect, focus_back)
    --    draw_rectangle(rect1, focus_face)
    -- normal
    draw_rectangle(rect, normal_back)
    draw_rectangle(rect1, normal_face)
    --end
    
    local progrect = Rectangle(rect3.X, rect3.Y, rect3.Width * (value / range), rect3.Height)
    draw_rectangle(progrect, accent)

    -- handle
    local holder = rect1
    local handledim = holder.Height
    --local handlepos = round( rect1.Width * (value / max), 0 )
    local handlepos = round( (rect1.Width-handledim) * (value / range) + handledim/2, 0 )    
    local handlerect = Rectangle(holder.X + handlepos - handledim/2, holder.Y + 0, handledim, handledim)

    local handlerect1 = rectangle_erode(handlerect, 1)
    local handlerect2 = rectangle_erode(handlerect, 2)

    rect = handlerect
    rect1 = handlerect1
    if (state.Activating) then
        --draw_rectangle(rect, activating_back)
        --draw_rectangle(rect1, activating_face)
        draw_rectangle(rect, hot_back)
        draw_rectangle(rect1, raised_face)
        --draw_rectangle(rect1, normal_raised)
    elseif (state.Hot) then
        draw_rectangle(rect, hot_back)
        draw_rectangle(rect1, raised_face)
        --draw_rectangle(rect1, normal_raised)
    --elseif (state.Focused) then
    --    draw_rectangle(rect, focus_back)
    --    draw_rectangle(rect1, focus_face)
    else -- normal    
        draw_rectangle(rect, raised_back)
        draw_rectangle(rect1, raised_face)
    end

    -- draw value string
    --if (true) then
    --    local pt = Point(rect.X + rect.Width + 4, rect.Y + rect.Height - 1)
    --    draw_label(tostring(value), pt, foreground)
    --end
end


local function draw_checkbutton(text, rect, state, value)
    
    local rect1 = rectangle_erode(rect, 1)
    local rect2 = rectangle_erode(rect, 2)
    local rect3 = rectangle_erode(rect, 3)
    local rect4 = rectangle_erode(rect, 4)

    if (state.Activating) then
        draw_rectangle(rect, activating_back)
        draw_rectangle(rect1, activating_face)
    elseif (state.Hot) then
        draw_rectangle(rect, hot_back)
        draw_rectangle(rect1, hot_face)
    --elseif (state.Focused) then
    --    draw_rectangle(rect, focus_back)
    --    draw_rectangle(rect1, focus_face)
    else -- normal
        if value then
            draw_rectangle(rect, hot_back)
            draw_rectangle(rect2, hot_face)
        else
            draw_rectangle(rect, normal_back)
            draw_rectangle(rect1, normal_face)
        end
    end    

    local valign = point_translate(vertical_center_text(rect1), 3, 0)
    if (state.Activating or value) then
        valign = point_translate(valign,1,1)
        draw_label(text, valign)
    else
        draw_label(text, valign)
    end

end

local function draw_handle(uiid, rect, state)
    local rect1 = rectangle_erode(rect, 1)

    if (state.Activating) then
        draw_rectangle(rect, activating_back)
        draw_rectangle(rect1, activating_face)
    elseif (state.Hot) then
        draw_rectangle(rect, hot_back)
        draw_rectangle(rect1, hot_face)
    --elseif (state.Focused) then
    --    draw_rectangle(rect, focus_back)
    --    draw_rectangle(rect1, focus_face)
    else -- normal
        draw_rectangle(rect, normal_back)
        draw_rectangle(rect1, normal_face)
    end
end

return {
    round = round,
    Color = Color,
    --
    default_text_color = default_text_color,
    normal_back = normal_back,
    normal_face = normal_face,
    raised_back = raised_back,
    raised_face = raised_face,
    hot_back = hot_back,
    hot_face = hot_face,
    activating_back = activating_back,
    activating_face = activating_face,
    focus_back = focus_back,
    focus_face = focus_face,
    accent = accent,
    --
    Point = Point,
    Rectangle = Rectangle,
    vertical_center = vertical_center,
    vertical_center_text = vertical_center_text,
    rectangle_center = rectangle_center,
    rectangle_offset = rectangle_offset,
    rectangle_erode = rectangle_erode,
    rectangle_dilate = rectangle_dilate,
    rectangle_underline = rectangle_underline,
    rectangle_copy = rectangle_copy,
    point_translate = point_translate,
    --
    text = draw_text,
    rectangle = draw_rectangle,
    label = draw_label,
    button = draw_button,
    checkbox = draw_checkbox,
    progressbar = draw_progressbar,
    slider = draw_slider,
    checkbutton = draw_checkbutton,
    handle = draw_handle,
}