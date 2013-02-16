--Shows a circle around wards to let you see their sight range
--option:Change alwaysshow to 1 or 0
--option:Set a hotkey to show,default key=0x78(F9)

require "basic_functions"

local script_loaded=1
local ward_table = {}
local ward_timers ={}
local ward_ranges ={}
local ward_counter=1;
local script_ct=os.clock()
local alwaysshow=1;
local key=0x78;--F9
--local player_team=(GetSelf()).team
function sample_CallBackWardRange()
	local player_team=(GetSelf()).team
	local CLOCK=os.clock()
	if (CLOCK-script_ct<12) then
		DrawText("Ward circles loaded",20,100,0xFF00EE22)
	end

	--local p=GetSelf()
	--local key=0x78;--F9
	local max_new_objects=objManager:GetMaxNewObjects()
	for i = 1,max_new_objects, 1 do
		local object = objManager:GetNewObject(i)
		local s=object.name
		if (s ~= nil and object.team ~= player_team) then
			local chk=string.find(s,"SightWard") or string.find(s,"WriggleLantern") or string.find(s,"VisionWard")
			if (chk ~= nil) then
				ward_table[ward_counter]=object
				ward_timers[ward_counter]=CLOCK+180
				ward_ranges[ward_counter]=1400
				ward_counter=ward_counter+1
			end
		end
	end
	if (IsKeyDown(key)~=0 or alwaysshow==1) then
		for i=1,ward_counter-1,1 do
			if (CLOCK<ward_timers[i]) then
				local o=ward_table[i]
				local r=ward_ranges[i]
				DrawCircleObject(o,r,1)
				DrawCircleObject(o,r+1,1)
				DrawCircleObject(o,r+2,1)
			end
		end
	end
end
SetTimerCallback("sample_CallBackWardRange")
print("\nward_ranges loaded\n")
			