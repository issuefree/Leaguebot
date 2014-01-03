require "timCommon"

local showTimerRadius = 100
local showVisionRangeKey = 18
local showSameTeam = false

local types = {
	 { label="Trinket Ward", color=yellow,
	   duration=60, sightRange=1350, triggerRange=70,
	   charName="SightWard", name="YellowTrinket", spellName="RelicSmallLantern" },
	 { label="Trinket Ward", color=yellow,
	   duration=120, sightRange=1350, triggerRange=70, 
	   charName="SightWard", name="YellowTrinketUpgrade", spellName="RelicLantern" },
	 { label="Sight Ward", color=green, 
		duration=180, sightRange=1350, triggerRange=70,
		charName="SightWard", name="SightWard", spellName="SightWard" }, 
	 { label="Sight Ward", color=green, 
		duration=180, sightRange=1350, triggerRange=70, 
		charName="SightWard", name="SightWard", spellName="wrigglelantern" },
	 { label="Vision Ward", color=violet, 
		duration=0, sightRange=1350, triggerRange=70, 
		charName="VisionWard", name="VisionWard", spellName="VisionWard" },

	 { label="Jack in the Box", color=red, 
		duration=60, sightRange=690, triggerRange=300,
		charName="Jack In The Box", name="ShacoBox", spellName="JackInTheBox" },
	 { label="Shroom", color=red, 
		duration=600, sightRange=405, triggerRange=115, 
		charName="Noxious Trap", name="TeemoMushroom", spellName="BantamTrap" },
  	 { label="Yordle Trap", color = red, 
  		duration = 240, sightRange=150, triggerRange=150,
  		charName="Cupcake Trap", name="CaitlynYordleTrap", spellName="CaitlynYordleTrap" }, 
  	 { label="Bushwhack", color=yellow,
  		duration = 240, sightRange=0, triggerRange=150,
		charName="Noxious Trap", name="Nidalee_Spear", spellName="Bushwhack" }
}

local wardSpots = {
        -- ward spots
        { x = 2850,    y = 45.84,  z = 7575},     -- BLUE GOLEM
        { x = 7422,    y = 46.53,  z = 3282},     -- BLUE LIZARD
        { x = 10148,   y = 44.41,  z = 2839},     -- BLUE TRI BUSH
        { x = 6269,    y = 42.51,  z = 4445},     -- BLUE PASS BUSH
        { x = 7406,    y = 43.31,  z = 4995},     -- BLUE RIVER ENTRANCE
        { x = 4325,    y = 44.38,  z = 7041.54},  -- BLUE ROUND BUSH
        { x = 4728,    y = -51.29, z = 8336},     -- BLUE RIVER ROUND BUSH
        { x = 6598,    y = 46.15,  z = 2799},     -- BLUE SPLIT PUSH BUSH
 
        { x = 11183,   y = 45.75,  z = 6899},     -- PURPLE GOLEM
        { x = 6661,    y = 44.46,  z = 11197},    -- PURPLE LIZARD
        { x = 3883,    y = 39.87,  z = 11577},    -- PURPLE TRI BUSH
        { x = 7775,    y = 43.14,  z = 10046.49}, -- PURPLE PASS BUSH
        { x = 6625.47, y = 47.66,  z = 9463},     -- PURPLE RIVER ENTRANCE
        { x = 9658,    y = 45.79,  z = 7556},     -- PURPLE ROUND BUSH
        { x = 9300,    y = -73.46, z = 6128},     -- PURPLE RIVER ROUND BUSH
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
		if ward.duration > 0 then
			local timer = string.format(math.ceil((ward.tick+ward.duration-time())))
			Circle(ward.loc, ward.triggerRange, ward.color)
			if showVisionRange then					
				Circle(ward.loc, ward.sightRange, ward.color)
			end
			if GetDistance(ward.loc, GetMousePos()) < showTimerRadius then
				if ward.source == "onload" then
					DrawText(ward.label..": max "..timer, GetCursorX()-13, GetCursorY()-17, timerColor)
				else
					DrawText(ward.label..": "..timer, GetCursorX()-13, GetCursorY()-17, timerColor)
				end
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
		if ward.duration > 0 and time()-ward.tick >= ward.duration then
			table.remove(wards,i)
		end
	end
end

function addWard(ward, type)
	ward = merge(ward, type)

	--check for dups
	for i,w in rpairs(wards) do
		if GetDistance(w.loc, ward.loc) < 100 and
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

local function onCreate(object)
	if not showSameTeam and object.team == me.team then
		return
	end

	for _,type in ipairs(types) do
		if object.charName == type.charName and 
			object.name == type.name
		then
			local ward = {loc=Point(object), object=object, tick=time(), source="oncreate"}
			if LOADING then
				ward.source = "onload"
			end
			addWard(ward, type)
			break
		end
	end
end

local function onSpell(unit, spell)
	if IsHero(unit) and (showSameTeam or IsEnemy(unit)) then
		for _,type in ipairs(types) do
			if type.spellName == spell.name then
				local ward = {loc=Point(spell.endPos), tick=time(), source="spell"}
				addWard(ward, type)
				break
			end
		end
	end
end


AddOnCreate(onCreate)
AddOnSpell(onSpell)

SetTimerCallback("OnTick")