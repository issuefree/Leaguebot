require "issuefree/timCommon"

local camps = {
	bWolf = {id=2, timeout=50, num=3},
	rWolf = {id=8, timeout=50, num=3},
	bWraiths = {id=3, timeout=50, num=4},
	rWraiths = {id=9, timeout=50, num=4},
	bWight = {id=13, timeout=50, num=1},
	rWight = {id=14, timeout=50, num=1},
	bBlue = {id=1, timeout=300, num=3},
	rBlue = {id=7, timeout=300, num=3},
	bRed = {id=4, timeout=300, num=3},
	rRed = {id=10, timeout=300, num=3},
	bGolems = {id=5, timeout=50, num=2},
	rGolems = {id=11, timeout=50, num=2},
	dragon = {id=6, timeout=360, num=1},
	baron = {id=12, timeout=420, num=1}
}

if GetMap() ~= 1 then
	camps = {
	-- Howling abyss 
		bInner = {id=4, timeout=40, num=1},
		rInner = {id=3, timeout=40, num=1},
		bOuter = {id=2, timeout=40, num=1},
		rOuter = {id=1, timeout=40, num=1},
	}
end

for _,camp in pairs(camps) do	
	camp.name = "monsterCamp_"..camp.id
	camp.creepNames = {}
	camp.creeps = {}
	for i = 1, camp.num, 1 do
		table.insert(camp.creepNames, camp.id..".1."..i)
	end
end

if GetSpellLevel("Q") > 0 or
	GetSpellLevel("W") > 0 or
	GetSpellLevel("E") > 0
then
	local timers = LoadConfig("jungle")
	if timers then
		for key,nextSpawn in pairs(timers) do
			if camps[key] then
				if 0+nextSpawn > time() then
					camps[key].nextSpawn = 0+nextSpawn
					pp("Timer "..key.." "..nextSpawn-time())
				end
			end
		end
	end
end


function saveTimers()
	local timers = {}
	for key,camp in pairs(camps) do
		timers[key] = camp.nextSpawn
	end
	SaveConfig("jungle", timers)
end

function JungleTimer()
	for _,camp in pairs(camps) do
		if camp.object then

			for i,creep in rpairs(camp.creeps) do
				if not creep.charName or not ListContains(creep.charName, camp.creepNames) then
					table.remove(camp.creeps, i)
				end
			end

			-- local creeps = GetAllInRange(me, 1000, camp.creeps)
			-- for i,creep in ipairs(creeps) do
			-- 	PrintState(i, creep.charName.." "..creep.dead)
			-- 	if find(creep.charName, "3.1.3") then
			-- 		Circle(creep)
			-- 	end
			-- end

			if camp.nextSpawn and camp.nextSpawn > time() then
				local tts = math.floor((camp.nextSpawn - time())+.5)
				local perc = tts/camp.timeout
				if perc > .5 then
					color = 0x99CCCCCC
				elseif perc > .25 then
					color = 0xFFCCCCCC
				elseif perc > .1 then					
					color = 0xFFEEEE33
				else
					color = 0xFF33CC33
				end
				local label = tts%60
				if tts > 60 then
					if tts%60 < 10 then
						label = "0"..label
					end
					label = math.floor(tts/60)..":"..label
				end
				DrawTextMinimap(label, camp.object.x, camp.object.z, color)
			end

			if not camp.nextSpawn and #camp.creeps > 0 then
				local campLive = false
				for _,creep in ipairs(camp.creeps) do
					if creep.dead == 0 then
						campLive = true
						break
					end
				end
				if not campLive then
					camp.nextSpawn = math.ceil(time()) + camp.timeout
					saveTimers()
				end
			end
		end
	end

	-- DrawTextMinimap("M", mousePos.x,mousePos.z,0xFFCCEECC)
end

function onCreate(object)
	for campName,camp in pairs(camps) do
		if object.charName == camp.name then
			-- pp("Adding camp "..campName.." "..object.charName)
			camp.object = object
		end
		for _,creepName in ipairs(camp.creepNames) do
			if find(object.charName, creepName) and camp.object and GetDistance(camp.object, object) < 1000 then
				-- pp("Adding "..object.charName.." to "..campName)
				table.insert(camp.creeps, object)
				camp.nextSpawn = nil
				saveTimers()
			end
		end

		if find(object.charName, "Odin_HealthPackHeal") then
			if GetDistance(camp.object, object) < 500 then
				camp.nextSpawn = math.ceil(time()) + camp.timeout
				saveTimers()
			end
		end
	end
end

AddOnCreate(onCreate)

AddOnTick(JungleTimer)