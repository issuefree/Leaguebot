require "timCommon"

local showWardsFromSpells = true
local showTimerRadius = 100
local showVisionRangeKey = 18
local showSameTeam = true

local wardTypes = {
	sight={color=green, duration=180000, sightRange=1350, triggerRange=70},
	vision={color=violet, duration=180000, sightRange=1350, triggerRange=70},
	shaco={color=red, duration=60000, sightRange=690, triggerRange=300},
	shroom={color=yellow, duration=600000, sightRange=405, triggerRange=160},
   yordle={color=yellow, duration=240000, sightRange=150, triggerRange=150},
   bushwhack={color=yellow, duration=240000, sightRange=0, triggerRange=150},
   sapling={color=red, duration=35000, sightRange=700, triggerRange=500}
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
		local timer = string.format(math.ceil((ward.tick+ward.duration-GetClock())/1000))
		DrawCircle(ward.x, ward.y, ward.z, ward.triggerRange, ward.color)
		if showVisionRange then					
			DrawCircle(ward.x, ward.y, ward.z ,ward.sightRange, ward.color)
		end
		if GetDistance({x=ward.x, z=ward.z},GetMousePos()) < showTimerRadius then
			if ward.source == "onload" then
				DrawText(ward.name..": max "..timer, GetCursorX()-13, GetCursorY()-17, timerColor)
			else
				DrawText(ward.name..": "..timer, GetCursorX()-13, GetCursorY()-17, timerColor)
			end
		end
	end
end

function cleanUpWards()
	for i,ward in rpairs(wards) do
		if ward.source ~= "spell" then
			if not ward.object or not ward.object.x then
				table.remove(wards,i)
				break ;
			end
		end
		if GetClock()-ward.tick >= ward.duration then
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
		local ward = {x=object.x, y=object.y, z=object.z, object=object, tick=GetClock(), source="oncreate"}		
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
		ward.tick = GetClock()
		addWard(ward)
	end
end

function addWard(ward)
	ward = populate(ward)
	--check for dups
	for i,w in rpairs(wards) do
		if math.abs(w.x - ward.x) < 100 and 
		   math.abs(w.z - ward.z) < 100 and
		   math.abs(w.tick - ward.tick) < 1000 then
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