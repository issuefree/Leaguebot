print=printtext
printtext("\nPG timers loaded")
timer_xpositions = {4751,5931,7473,8922}
timer_ypositions = {3902,5192,6617,7868}
runetimers_up = {}
runetimers_clock= {}
HP_TIMER=40
function sample_CallBacker()
	CLOCK=os.clock()
	for i = 1,4 do
		local ix=timer_xpositions[i]
		local iy=timer_ypositions[i]
		if (runetimers_up[i]==1) then
			--DrawTextMinimap("UP",ix+1200,iy+1200,0xFF44DD00)
		end
		if (runetimers_up[i]==0) then
			local tm=math.floor(HP_TIMER-(CLOCK-runetimers_clock[i]))
			if (tm>1) then
				DrawTextMinimap(tostring(tm),ix+1200,iy+1200,0xFFEEEE00)
			end
			if ((tm<2) and (tm>-4)) then
				DrawTextMinimap("UP",ix+1200,iy+1200,0xFF22FF00)
			end
		end
	end
	for i = 1, objManager:GetMaxNewObjects(), 1 do
		local object = objManager:GetNewObject(i)
		local s=object.charName
		if (s ~= nil) then
		if (string.find(s,"odin_heal_rune.troy") ~= nil) then
			local x=math.floor((object.x-2500)/1500)
			runetimers_up[x]=1
			print("\nrune found:" .. tostring(x) .. " x:" .. tostring(object.x) .. " y:" .. tostring(object.z))
		end
		if (string.find(s,"Odin_HealthPackHeal") ~= nil) then
			local x=math.floor((object.x-2500)/1500)
			runetimers_clock[x]=CLOCK
			runetimers_up[x]=0
			print("\nrune used:" .. tostring(x))
		end
		end
	end
end
SetTimerCallback("sample_CallBacker")