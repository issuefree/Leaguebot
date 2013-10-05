require "timCommon"

local showWardsFromSpells = true
local showTimerRadius = 100
local showVisionRangeKey = 18
local showSameTeam = false

local wardTypes = {
	sight={color=green, duration=180, sightRange=1350, triggerRange=70},
	vision={color=violet, duration=180, sightRange=1350, triggerRange=70},
	shaco={color=red, duration=60, sightRange=690, triggerRange=300},
	shroom={color=yellow, duration=60, sightRange=405, triggerRange=115},
   yordle={color=yellow, duration=240, sightRange=150, triggerRange=150},
   bushwhack={color=yellow, duration=240, sightRange=0, triggerRange=150},
   sapling={color=red, duration=350, sightRange=700, triggerRange=500}
}

local wardSpots = {
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

local timerColor = 0xFFFFFFFF

local wards = {}
local showVisionRange = false

function OnTick()
	if IsKeyDown(showVisionRangeKey) == 1 then 
		showVisionRange = true
	else 
		showVisionRange = false 
	end
	
	cleanUpWards()
	drawWards()
end

function drawWards()
	for i,ward in ipairs(wards) do 
		local timer = string.format(math.ceil((ward.tick+ward.duration-time())))
		Circle(ward, ward.triggerRange, ward.color)
		if showVisionRange then					
			Circle(ward, ward.sightRange, ward.color)
		end
		if GetDistance({x=ward.x, z=ward.z},GetMousePos()) < showTimerRadius then
			if ward.source == "onload" then
				DrawText(ward.name..": max "..timer, GetCursorX()-13, GetCursorY()-17, timerColor)
			else
				DrawText(ward.name..": "..timer, GetCursorX()-13, GetCursorY()-17, timerColor)
			end
		end
	end

	for _,spot in ipairs(wardSpots) do
		Circle(Point(spot), 25, yellow, 2)
	end 
end

function cleanUpWards()
	for i,ward in rpairs(wards) do
		if ward.source ~= "spell" then
			if not ward.object or not ward.object.x then
				table.remove(wards,i)
				break
			end
		end
		if time()-ward.tick >= ward.duration then
			table.remove(wards,i)
		end
	end
end

local function createWards(object)
	if object.charName == "VisionWard" or 
		object.charName == "SightWard" or
		object.charName == "Jack In The Box" or 
		object.charName == "Noxious Trap" or
		object.charName == "Cupcake Trap" or
		object.name == "Nidalee_Spear" or
		object.charName == "MaokaiSproutling"
	then
		local ward = {x=object.x, y=object.y, z=object.z, object=object, tick=time(), source="oncreate"}		
		if LOADING then
			ward.source = "onload"
		end
		addWard(ward)
	end
end

local function processWards(object,spell)
	local ward
	if showSameTeam or object.team ~= me.team then
		if spell.name == "SightWard" then
			ward = {name="Sight Ward", source="spell", type="sight"}
		elseif spell.name == "wrigglelantern" then
			ward = {name="Sight Ward", source="spell", type="sight"}
		elseif spell.name == "VisionWard" then
			ward = {name="Vision Ward", source="spell", type="vision"}
		elseif spell.name == "ItemGhostWard" then
			ward = {name="Sight Ward", source="spell", type="sight"}
		elseif spell.name == "JackInTheBox" then
			ward = {name="Shaco Box", source="spell", type="shaco"}
		elseif spell.name == "BantamTrap" then
			ward = {name="Shroom", source="spell", type="shroom"}
		elseif spell.name == "CaitlynYordleTrap" then
			ward = {name="Yordle Trap", source="spell", type="yordle"}
		elseif spell.name == "Bushwhack" then
			ward = {name="Bushwhack", source="spell", type="bushwhack"}
		elseif spell.name == "MaokaiSapling2" then
			ward = {name="Sapling", source="spell", type="sapling"}
		else
			return
		end
		ward.x = spell.endPos.x
		ward.y = spell.endPos.y
		ward.z = spell.endPos.z
		ward.tick = time()
		addWard(ward)
	end
end

function addWard(ward)
	ward = populate(ward)
	--check for dups
	for i,w in rpairs(wards) do
		if math.abs(w.x - ward.x) < 100 and 
		   math.abs(w.z - ward.z) < 100 and
		   math.abs(w.tick - ward.tick) < 1 then
			if ward.source == "spell" then  -- don't add spells if the obj exists
				return
			else
				table.remove(wards, i)
				break
			end
		end
	end
	table.insert(wards, ward)
end

function populate(ward)
	if ward.object and ward.object.charName == "SightWard" and ward.object.name == "SightWard" then
		ward.name = "Sight Ward"
		ward.type = "sight"
				
	elseif ward.object and ward.object.charName == "VisionWard" and ward.object.name == "VisionWard" then
		ward.name = "Vision Ward"
		ward.type = "vision"
		
	elseif ward.object and ward.object.charName == "VisionWard" and ward.object.name == "SightWard" then
		ward.name = "Explorer's Ward"
		ward.type = "sight"
		
	elseif ward.object and ward.object.charName == "Jack In The Box" then
		ward.name = "Shaco Box"
		ward.type = "shaco"
				
	elseif ward.object and ward.object.charName == "Cupcake Trap" then
		ward.name = "Yordle Trap"
		ward.type = "yordle"
		
	elseif ward.object and ward.object.name == "Nidalee_Spear" then
		ward.name = "Bushwhack"
		ward.type = "bushwhack"
		
	elseif ward.object and ward.object.charName == "Noxious Trap" then
		ward.name = "Shroom"
		ward.type = "shroom"
		
	elseif ward.object and ward.object.charName == "MaokaiSproutling" then
		ward.name = "Sapling"
		ward.type = "sapling"
		
	end
	if not wardTypes[ward.type] then
		pp(ward.object.charName)
	else 
		ward = merge(ward, wardTypes[ward.type])
		return ward
	end
end

AddOnCreate(createWards)
AddOnSpell(processWards)

ModuleConfig:addParam("wardRevealer", "Ward Revealer", SCRIPT_PARAM_ONOFF, true)
ModuleConfig:permaShow("wardRevealer")

SetTimerCallback("OnTick")