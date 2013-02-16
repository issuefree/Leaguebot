--Basic Darius autokill with Ult script--
--Set a hotkey to LOADSCRIPT=darius_dunk.lua
--press it to toggle the script on/off

require "basic_functions"

local script_loaded=1
local hero_table = {}
local hero_table_timer = {}
local toggle_timer=os.clock()
local blood_object="darius_hemo_bleed_trail_only"
local blood_len=string.len(blood_object)
local cast_ult_timer=0
function sample_CallBackDarius()
	CLOCK=os.clock()
	local spellr_level=GetSpellLevel('R')
	if (CLOCK-cast_ult_timer<.3) then
		return
	end
	local p=GetSelf()
	local key=GetScriptKey();
	local max_new_objects=objManager:GetMaxNewObjects()
	local max_heroes=objManager:GetMaxHeroes()
	local player_team=p.team
	local darius_ult_base=70+spellr_level*90+.75*p.addDamage
	if (IsKeyDown(key)~=0 and CLOCK-toggle_timer>1.2 and key~=0) then
		toggle_timer=CLOCK
		script_loaded= ((script_loaded+1)%2)
	end
	if (script_loaded==1) then
		DrawText("Darius Dunk loaded",10,40,0xFF00EE00);
		if (CLOCK-toggle_timer<6) then
			DrawText("Press key again to toggle",10,50,0xFF00EE00);
		end
	else
		DrawText("Darius Dunk unloaded",10,40,0xFFFFFF00);
		return
	end
	for i = 1,max_new_objects, 1 do
		local object = objManager:GetNewObject(i)
		local s=object.charName
		if (s ~= nil) then
		local chk=string.find(s,"darius_hemo_bleed_trail_only")
		if (chk ~= nil) then
			chk=chk+blood_len
			local counter=string.sub(s,chk,chk)
			for j = 1, max_heroes, 1 do
				local h=objManager:GetHero(j)
				if (GetDistance(h,object)<10) then
					local name=h.charName
					hero_table[name]=tonumber(counter)
					hero_table_timer[name]=CLOCK
					--print("\nhero:" .. h.name .. " x:" .. h.x .. " z:" .. h.z .. " counter:" .. counter)
				end
			end
		end
		end
	end
	for i= 1,max_heroes,1 do
		local h=objManager:GetHero(i)
		if (h.team ~= player_team and h.visible==1 and h.invulnerable==0) then
			local name=h.charName
			local stacks=hero_table[name]
			if (stacks==nil or CLOCK-hero_table_timer[name]>4.5) then
				stacks=0
			end
			if (stacks==6) then
				stacks=5
			end
			local damage=darius_ult_base*(1+stacks*.2)
			if (h.health<damage and spellr_level>0) then
				print("\ntarget:" .. h.name .. " damage:" .. damage .. " hp:" .. h.health)
				if (GetDistance(p,h)<475) then
					CastSpellTarget('R',h)
					cast_ult_timer=CLOCK
					break
				end
			end
		end
	end
end
SetTimerCallback("sample_CallBackDarius")
print("\ndarius_dunk loaded\n")
			