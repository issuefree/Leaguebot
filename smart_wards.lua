require "Utils"

local version = "1.1 (by Val)"
local AUTOPLACE_IF_MISS = 0
mousePos = {x=0,y=0,z=0}
items = {2045,2049,3154,2044,2043}
wardSpots = {
        -- ward spots
        { x = 2572,    y = 45.84,  z = 7457},     -- BLUE GOLEM
        { x = 7422,    y = 46.53,  z = 3282},     -- BLUE LIZARD
        { x = 10148,   y = 44.41,  z = 2839},     -- BLUE TRI BUSH
        { x = 6269,    y = 42.51,  z = 4445},     -- BLUE PASS BUSH
        { x = 7406,    y = 43.31,  z = 4995},     -- BLUE RIVER ENTRANCE
        { x = 4325,    y = 44.38,  z = 7241.54},  -- BLUE ROUND BUSH
        { x = 4728,    y = -51.29, z = 8336},     -- BLUE RIVER ROUND BUSH
        { x = 6598,    y = 46.15,  z = 2799},     -- BLUE SPLIT PUSH BUSH

        { x = 11500,   y = 45.75,  z = 7095},     -- PURPLE GOLEM
        { x = 6661,    y = 44.46,  z = 11197},    -- PURPLE LIZARD
        { x = 3883,    y = 39.87,  z = 11577},    -- PURPLE TRI BUSH
        { x = 7775,    y = 43.14,  z = 10046.49}, -- PURPLE PASS BUSH
        { x = 6625.47, y = 47.66,  z = 9463},     -- PURPLE RIVER ENTRANCE
        { x = 9720,    y = 45.79,  z = 7210},     -- PURPLE ROUND BUSH
        { x = 9191,    y = -73.46, z = 6004},     -- PURPLE RIVER ROUND BUSH
        { x = 7490,    y = 41,     z = 11681},    -- PURPLE SPLIT PUSH BUSH

        { x = 3527.43, y = -74.95, z = 9534.51},  -- NASHOR
        { x = 10473,   y = -73,    z = 5059},     -- DRAGON
}

	WardConfig = scriptConfig("Ward Config", "wardconf")
	WardConfig:addParam("smartward", "Smart Ward", SCRIPT_PARAM_ONKEYDOWN, false, 99)
	WardConfig:permaShow("smartward")

function sample_CallBackWard()
    CLOCK=os.clock()
    if WardConfig.smartward then
        --print("\nkshowcircles")
        mousePos.x=GetCursorWorldX()
        mousePos.y=GetCursorWorldY()
        mousePos.z=GetCursorWorldZ()
        keypressed=1
        for i,wardSpot in pairs(wardSpots) do
        if GetDistance(wardSpot, mousePos) <= 250 then
                                wardColor = 0x02
                        else
                                wardColor = 0x01
                        end
            DrawCircle(wardSpot.x, wardSpot.y, wardSpot.z, 28, wardColor)
                        DrawCircle(wardSpot.x, wardSpot.y, wardSpot.z, 29, wardColor)
                        DrawCircle(wardSpot.x, wardSpot.y, wardSpot.z, 30, wardColor)
                        DrawCircle(wardSpot.x, wardSpot.y, wardSpot.z, 31, wardColor)
                        DrawCircle(wardSpot.x, wardSpot.y, wardSpot.z, 32, wardColor)
                        DrawCircle(wardSpot.x, wardSpot.y, wardSpot.z, 250, wardColor)
        end
    end
    if (WardConfig.smartward == false and (keypressed==1)) then
        smartwarded=0
        mousePos.x=GetCursorWorldX()
        mousePos.y=GetCursorWorldY()
        mousePos.z=GetCursorWorldZ()
        for i,wardSpot in pairs(wardSpots) do
        if GetDistance(wardSpot, mousePos) <= 250 then
			for i,item in pairs(items) do
				UseItemLocation(item, wardSpot.x, wardSpot.y, wardSpot.z)
				UseItemLocation(item, wardSpot.x, wardSpot.y, wardSpot.z)
			end
            smartwarded=1
        end
        end
        if (smartwarded==0 and AUTOPLACE_IF_MISS==1) then
			for i,item in pairs(items) do
				UseItemLocation(item, wardSpot.x, wardSpot.y, wardSpot.z)
				UseItemLocation(item, wardSpot.x, wardSpot.y, wardSpot.z)
			end
        end
        keypressed=0
    end

end
SetTimerCallback("sample_CallBackWard")
printtext("\nsmartwarder loaded")