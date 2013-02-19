local function table_print (tt, indent, done)
	done = done or {}
	indent = indent or 0
	if type(tt) == "table" then
		local sb = {}
		for key, value in pairs (tt) do
			table.insert(sb, string.rep (" ", indent)) -- indent it
			if type (value) == "table" and not done [value] then
				done [value] = true
				table.insert(sb, "{\n");
				table.insert(sb, table_print (value, indent + 2, done))
				table.insert(sb, string.rep (" ", indent)) -- indent it
				table.insert(sb, "}\n");
			elseif "number" == type(key) then
				table.insert(sb, string.format("\"%s\"\n", tostring(value)))
			else
				table.insert(sb, string.format(
				"%s = \"%s\"\n", tostring (key), tostring(value)))
			end
		end
		return table.concat(sb)
	else
		return tt .. "\n"
	end
end

function pp(str)
	if str == nil then
		pp("nil")
	elseif type(str) == "table" then
		pp(table_print(str, 2))
	else
		printtext(str.."\n")
	end
end

function merge(table1, table2)
	if not table2 then	
		pp(debug.traceback())
	end
	local resTable = {}
	for k,v in pairs(table1) do
		resTable[k] = v
	end
	for k,v in pairs(table2) do
		resTable[k] = v
	end
	return resTable
end

function rpairs(t)
	if not t then
		pp(debug.traceback())
	end
	return prev, t, table.getn(t)+1
end

function prev(t, i)
	if i == 1 then
		return nil
	end
	return i-1, t[i-1]
end

local line = 0
function PrintState(state, str)
	DrawText(str,15,100+state*15,0xFFCCEECC);
--	pp(state.."."..str)
end

LOADING = true

OBJECT_CALLBACKS = {}
SPELL_CALLBACKS = {}

function AddOnCreate(callback)
	table.insert(OBJECT_CALLBACKS, callback)
end

function AddOnSpell(callback)
	table.insert(SPELL_CALLBACKS, callback)	
end

-- circle colors
yellow = 0
green  = 1
red    = 2
blue   = 3
violet = 4

-- globals for convenience
me = GetSelf()
hotKey = GetScriptKey()
playerTeam = ""

-- common item / spell defs
ITEMS = {}
spells = {}

-- simple attempt to grab high priority targets
ADC = nil
APC = nil

EADC = nil
EAPC = nil

-- object arrays
MINIONS = {}
ALLIES = {}
ENEMIES = {}
RECALLS = {}
TURRETS = {}
MYTURRETS = {}
CCS = {}
WARDS = {}

-- globals for the toggle menus
keyToggles = {}
toggleOrder = {}

spells["AA"] = {range=me.range+100, base={0}, ad=1, type="P", color=red} 


-- stuns roots fears taunts?
ccNames = {"Stun_glb", "summoner_banish", "Global_Taunt", "Global_Fear", "Ahri_Charm_buf", "leBlanc_shackle_tar", "LuxLightBinding_tar", "RunePrison_tar", "DarkBinding_tar", "Amumu_SadRobot_Ultwrap", "Amumu_Ultwrap", "maokai_elementalAdvance_root_01", "VarusRHitFlash"}

--Active offense
ITEMS["Entropy"]                  = {id=3184, range=me.range+50, type="active"}
ITEMS["Bilgewater Cutlass"]       = {id=3144, range=400,         type="active", color=violet}
ITEMS["Hextech Gunblade"]         = {id=3146, range=700,         type="active", color=violet}
ITEMS["Blade of the Ruined King"] = {id=3153, range=500,         type="active", color=violet}
ITEMS["Deathfire Grasp"]          = {id=3128, range=750,         type="active", color=violet}
ITEMS["Ravenous Hydra"]           = {id=3074, range=400,         type="active", color=red}
ITEMS["Youmuu's Ghostblade"]      = {id=3142, range=me.range+50, type="active"}
ITEMS["Randuin's Omen"]           = {id=3143, range=500,         type="active", color=yellow}

--Active defense
ITEMS["Locket of the Iron Solari"] = {id=3190, range=700, type="active", color=green}

--Aura offense
ITEMS["Abyssal Scepter"] = {id=3001, range=700, type="aura", color=violet}
ITEMS["Frozen Heart"]    = {id=3110, range=700, type="aura", color=violet}

--Aura Defense
ITEMS["Mana Manipulator"]     = {id=3037, range=1200, type="aura", color=blue}
ITEMS["Aegis of Legion"]      = {id=3105, range=1200, type="aura", color=green}
ITEMS["Banner of Command"]    = {id=3060, range=1000, type="aura", color=yellow}
ITEMS["Emblem of Valor"]      = {id=3097, range=1200, type="aura", color=green}
ITEMS["Runic Bulwark"]        = {id=3107, range=1200, type="aura", color=green}
ITEMS["Shard of True Ice"]    = {id=3092, range=1200, type="aura", color=blue}
ITEMS["Will of the Ancients"] = {id=3152, range=1200, type="aura", color=yellow}
ITEMS["Zeke's Herald"]        = {id=3050, range=1200, type="aura", color=yellow}

--Active cleanse
ITEMS["Quicksilver Sash"]   = {id=3140,            type="active"}
ITEMS["Mercurial Scimitar"] = {id=3139,            type="active"}
ITEMS["Mikael's Crucible"]  = {id=3222, range=750, type="active"}

--On Hit
ITEMS["Malady"] = {id=3114}

repeat
	if string.format(me.team) == "100" then
		playerTeam = "Blue"
		HOME = {x=27, z=265}
	elseif string.format(me.team) == "200" then  
		playerTeam = "Red"
		HOME = {x=13923, z=14169}
	end
until playerTeam ~= nil and playerTeam ~= "0"


local function drawSpellRanges()
	for name,info in pairs(spells) do
		if info.range and 
		( not info.key or GetSpellLevel(info.key) > 0 ) 
		then
			DrawCircleObject(me, info.range, info.color)
		end	
	end
end

local function drawItemRanges()
	local ranges = {}
	for name, item in pairs(ITEMS) do
		if GetInventorySlot(item.id) and item.range and item.color then
			local range = item.range
			while ranges[range] do
				range = range+1
			end
			DrawCircleObject(me, range, item.color)
			ranges[range] = true
		end
	end 
end

local function drawCommon()
	if me.dead == 1 then
		return
	end
	drawSpellRanges()
	drawItemRanges()
end

function AddToggle(key, value)
	keyToggles[key] = value
	table.insert(toggleOrder, key)
end

function IsOn(key)
	return keyToggles[key].on
end

function GetMousePos()
	return {x=GetCursorWorldX(), z=GetCursorWorldZ()}
end

local pressed = {}
local function checkToggles()
	for _,toggle in pairs(keyToggles) do		
		local key = toggle.key		
		if IsKeyDown(key) == 1 then
			pressed[key] = true
		elseif IsKeyDown(key) == 0 then
			if pressed[key] == true then 
				toggle.on = not toggle.on 
				pressed[key] = false
			end
		end
	end
	DrawToggles()
end

local labelX = 280
local labelY = 960
function DrawToggles()
	for i,key in ipairs(toggleOrder) do
		local val = keyToggles[key]
		local label = val.label
		local auxLabel = val.auxLabel
		if val.args then
			for a,v in ipairs(val.args) do
				local arg = expandToggleArg(val.args[a])				
				label = string.gsub(label, "{"..(a-1).."}", arg)
				auxLabel = string.gsub(auxLabel, "{"..(a-1).."}", arg)
			end
		end
		if val.on then
			DrawText(label,labelX,labelY+(i-1)*15,0xFF00EE00);
			if auxLabel then			
				DrawText(auxLabel,labelX+150,labelY+(i-1)*15,0xFF00EE00);
			end
		else
			DrawText(label,labelX,labelY+(i-1)*15,0xFFFFFF00);
			if auxLabel then
				DrawText(auxLabel,labelX+150,labelY+(i-1)*15,0xFFFFFF00);
			end
		end
	end	
end

function expandToggleArg(arg)
	if type(arg) == "string" then
		return GetSpellDamage(arg)	
	elseif type(arg) == "function" then
		return arg()
	end
end

function SafeCall(f, ...)
	local b,e = pcall(f, ...)
	if not b then
		pp(e)
	end
end

function doCreateObj(object)
	if not (object and object.x and object.z) then
		return
	end

	-- find minions
	if ( ( find(object.name, "Blue_Minion") and playerTeam == "Red" ) or 
	     ( find(object.name, "Red_Minion") and playerTeam == "Blue" ) )
	then
		table.insert(MINIONS, object)
	end

	if ( find(object.name, "OrderTurret") or
	     find(object.name, "ChaosTurret") )
	then
      if object.team ~= me.team then 	     
         table.insert(TURRETS, object)
      else
         table.insert(MYTURRETS, object)
      end
	end

	if find(object.charName, "TeleportHome") then
		table.insert(RECALLS, object)
	end

	if ListContains(object.charName, ccNames) then
		table.insert(CCS, object)
	end

	if find(object.name, "Ward") then
		table.insert(WARDS, object)
	end

	for i, callback in ipairs(OBJECT_CALLBACKS) do
		callback(object, LOADING)
	end

end 

function DumpCloseObjects(object)
	if GetDistance(object) < 50 then
		pp(object.name.." "..object.charName)
	end
end

local function updateHeroes()
	ALLIES = {}
	ENEMIES = {}
	ADC = nil
	APC = nil
	EADC = nil
	EAPC = nil
	for i = 1, objManager:GetMaxHeroes(), 1 do
		local hero = objManager:GetHero(i)
		if hero.team == me.team then
			table.insert(ALLIES, hero)
		else
			table.insert(ENEMIES, hero)
		end
	end	
	ADC = getADC(ALLIES)
	APC = getAPC(ALLIES)

	EADC = getADC(ENEMIES)
	EAPC = getAPC(ENEMIES)

	if ADC then
		DrawText("ADC:"..ADC.name, 10, 910, 0xFF00FF00)
	end
	if APC then
		DrawText("APC:"..APC.name, 10, 925, 0xFF00FF00)
	end
	if EADC then
		DrawText("ADC:"..EADC.name, 150, 910, 0xFFFF0000)
	end
	if EAPC then
		DrawText("APC:"..EAPC.name, 150, 925, 0xFFFF0000)
	end
end

local function updateMinions()
	for i,minion in rpairs(MINIONS) do
		if not minion or
			minion.dead == 1 or
			minion.x == nil or 
			minion.y == nil or
			not find(minion.name, "Minion")
		then
			table.remove(MINIONS,i)
		end
	end
end

local function updateObjects()
	updateMinions()
	updateHeroes()
	Clean(RECALLS, "charName", "TeleportHome")
	Clean(CCS)
	Clean(WARDS, "name", "Ward")
	Clean(TURRETS, "name", "Turret")
	Clean(MYTURRETS, "name", "Turret")
end


-- find lowest health minion in range and smack it if it will die
function KillWeakMinion(spell, extraRange)
	if not CanUse(spell) then return end	
   if not extraRange then extraRange = 0 end

	-- find a weak minion
	local wMinion
	for _,minion in ipairs(GetInRange(me, spell.range+extraRange, MINIONS)) do
		if not wMinion or minion.health < wMinion.health then
			wMinion = minion
		end
	end

	-- if it's weak enough KILL IT
	if wMinion and wMinion.health < GetSpellDamage(spell, wMinion) then
		if not spell.key then
			AttackTarget(wMinion)
		else
			CastSpellTarget(spell.key, wMinion)
		end
	end
end

-- find the furthest away minion that you can kill and smack it
function KillFarMinion(spell)
	if not CanUse(spell) then return end

	local damage = GetSpellDamage(spell)

	local wMinion, wMinionD
	for _,minion in ipairs(GetInRange(me, spell.range, MINIONS)) do
		if GetSpellDamage(spell, minion) > minion.health then
			local minionD = GetDistance(minion)
			if not wMinionD or minionD > wMinionD then
				wMinion = minion
				wMinionD = minionD
			end
		end
	end
	if wMinion then
		if not spell.key then
			AttackTarget(wMinion)
		else
			CastSpellTarget(spell.key, wMinion)
		end
	end
end

function Check(object)
	if not object or not object[1] or not object[2] then return false end
	if object[1] == object[2].charName or object[1] == object[2].name then
		return true
	end
	return false 
end

function Clean(list, field, value)
	for i, obj in rpairs(list) do
      if field and value then
         if not find(obj[field], value) then
            table.remove(list,i)
         end
      elseif not obj or not obj.x or not obj.z then
         table.remove(list,i)
		end
	end
end

function HotKey()
	return IsKeyDown(hotKey) ~= 0
end

function IsRecalling(hero)
	for _, recall in ipairs(RECALLS) do
		if GetDistance(hero, recall) == 0 then
			return true
		end
	end
	return false
end

function find(source, target)
	if not source then
		return false
	end
	return string.find(source, target)
end

function copy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in pairs(orig) do
			copy[orig_key] = orig_value
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function getADC(list)
	local value = 0
	local adc
	for i,test in ipairs(list) do
		local tValue = test.addDamage + (test.armorPen + test.armorPenPercent)*5		
		if tValue > value then
			value = tValue
			adc = test
		end
	end
	return adc
end

function getAPC(list)
	local value = 0
	local apc
	for i,test in ipairs(list) do
		local tValue = test.ap + (test.magicPen + test.magicPenPercent)*5		
		if tValue > value then
			value = tValue
			apc = test
		end
	end
	return apc
end

function GetInRange(target, range, list)
	local result = {}
	for _,test in ipairs(list) do
		if target and test and test.x and test.y and			
			GetDistance(target, test) < range 
		then
			table.insert(result, test)
		end
	end
	return result
end

function SortByDistance(things, target)
	table.sort(things, function(a,b) return GetDistance(a, target) < GetDistance(b, target) end)
end


function GetNearestIndex(target, list)
	local nearDist = 10000
	local nearInd = nil
	for i,near in ipairs(list) do
		local tDist = GetDistance(target, near)
		if tDist < nearDist then
			nearInd = i
			nearDist = tDist
		end
	end
	return nearInd	 
end

function ListContains(name, list)
	for _, test in pairs(list) do
		if find(name, test) then return true end
	end
	return false
end

function UseItem(itemName, target)
	local item = ITEMS[itemName]
	local slot = GetInventorySlot(item.id)
	if not slot then return end	
	slot = tostring(slot)
	if not CanCastSpell(slot) then return end

	if itemName == "Entropy" or
		itemName == "Bilgewater Cutlass" or
		itemName == "Hextech Gunblade" or
		itemName == "Blade of the Ruined King" or
		itemName == "Deathfire Grasp" or
		itemName == "Ravenous Hydra" or
		itemName == "Youmuu's Ghostblade" or
		itemName == "Randuin's Omen"
	then
		if target and GetDistance(target) > item.range then
			return
		end
		if not target then
			target = GetWeakEnemy("MAGIC", item.range)
		end
		if target then
			CastSpellTarget(slot, target)
		end

	elseif itemName == "Shard of True Ice" then
		-- shard
		-- look at all nearby heros in range and target the one with the most nearby enemies
		local shardRadius = 300

		local nearCount = 0
		target = nil
		for i,hero in ipairs(ALLIES) do
			if GetDistance(me, hero) < 750 then
				local near = #GetInRange(hero, shardRadius, ENEMIES)
				if near > nearCount then
					target = hero
					nearCount = near
				end
			end
		end
		if target then
			CastSpellTarget(slot, target)
		end


	elseif itemName == "Locket of the Iron Solari" then
		-- locket
		-- how about 3 nearby allies and 2 nearby enemies
		local locketRange = 700
		if #GetInRange(me, locketRange, ALLIES) >= 3 and
		#GetInRange(me, locketRange, ENEMIES) >= 2 
		then
			CastSpellTarget(slot, me)
		end


	elseif itemName == "Mikael's Crucible" then
		-- crucible
		-- It can heal or it can cleans
		-- heal is better the lower they are so how about scan in range heros and heal the lowest under 25%
		-- the cleanse is trickier. should I save it for higher priority targets or just use it on the first who needs it?\
		-- I took (or tried to) take out the slows so it will only work on harder cc.
		-- how about try to free adc then apc then check for heals on all in range.

		local crucibleRange = 750

		local target = ADC
		if target and target.name ~= me.name and 
		GetDistance(target, me) < crucibleRange and
		#GetInRange(target, 50, CCS) > 0
		then 
			CastSpellTarget(slot, target)
			pp(target.name) 
		else
			target = APC
			if target and target.name ~= me.name and 
			GetDistance(target, me) < crucibleRange and
			#GetInRange(target, 50, CCS) > 0
			then 
				CastSpellTarget(slot, target)
				pp(target.name)
			end
		end

		for _,hero in ipairs(ALLIES) do
			if hero.health/hero.maxHealth < .25 then
				CastSpellTarget(slot, target)
			end
		end
	end
end

function UseAllItems(target)
	for item,_ in pairs(ITEMS) do
		UseItem(item, target)
	end
end

local function getWardingSlot()
	local wardSlot = GetInventorySlot(3154) -- Wriggles
	if wardSlot and CanCastSpell(wardSlot) then
		return wardSlot
	end

	wardSlot = GetInventorySlot(2049) -- Sightstone
	if wardSlot and CanCastSpell(wardSlot) then
		return wardSlot
	end

	wardSlot = GetInventorySlot(2045) -- Ruby Sightstone
	if wardSlot and CanCastSpell(wardSlot) then
		return wardSlot
	end

	wardSlot = GetInventorySlot(2044) -- Sight Ward
	if wardSlot and CanCastSpell(wardSlot) then
		return wardSlot
	end
end

function CanUse(thing)
	if type(thing) == "table" then -- spell or item
		if thing.id then -- item
			return CanCastSpell(GetInventorySlot(item.id))
		elseif thing.key then -- spell
			return CanUse(thing.key)
		end
	elseif type(thing) == "number" then -- item id
		return CanCastSpell(GetInventorySlot(thing))
	else -- string
		if spells[thing] then -- passed in the name of a spell
			if spells[thing].key then
				return CanUse(spells[thing].key)
			else
				return true -- a defined spell without a key prob auto attack
			end
		elseif ITEMS[thing] then  -- passed in the name of an item
			return CanCastSpell(GetInventorySlot(ITEMS[thing].id))
		else -- other string must be a slot
			if thing == "D" or thing == "F" then
				return IsSpellReady(thing) == 1
			end
			return CanCastSpell(thing)
		end
	end
end

local wardCastTime = GetClock() 
function WardJump(key)
	if not CanCastSpell(key) then
		return
	end
	local ward = nil

	-- is there a ward already?
	for _,w in ipairs(WARDS) do
		if GetDistance(w, GetMousePos()) < 150 then
			ward = w
			break
		end
	end

	-- there isn't so cast one and return, we'll jump on the next pass -- on second delay between casting wards to prevent doubles
	if not ward then 
		if GetClock() - wardCastTime > 1000 then
			local wardSlot = getWardingSlot()
			if wardSlot then
				CastSpellXYZ(wardSlot, GetCursorWorldX(), GetCursorWorldY(), GetCursorWorldZ())
				wardCastTime = GetClock()
			end
			return
		end
	else
		CastSpellTarget(key, ward)
	end
end

function AngleBetween(object1, object2)
	local a = object2.x - object1.x
	local b = object2.z - object1.z 	
	
	local angle = math.atan(a/b)
	
	if b < 0 then
		angle = angle+math.pi
	end
	return angle
end

function LineBetween(object1, object2, thickness)
	if not thickness then
		thickness = 0
	end

	local angle = AngleBetween(object1, object2)	
	DrawLineObject(object1, GetDistance(object1, object2), 0, angle, thickness)
end

function DrawKnockback(object2, dist)
	local a = object2.x - me.x
	local b = object2.z - me.z 
	
	local angle = math.atan(a/b)
	
	if b < 0 then
		angle = angle+math.pi
	end
	
	DrawLineObject(object2, dist, 0, angle, 0)
end

function CustomCircle(radius,thickness,color,object,x,y,z)
	if object ~= "" then
		local count = math.floor(thickness/2)
		repeat
			DrawCircleObject(object,radius+count,color)
			count = count-2
		until count == (math.floor(thickness/2)-(math.floor(thickness/2)*2))-2
	elseif x ~= "" and y ~= "" and z~= "" then
		local count = math.floor(thickness/2)
		repeat
			DrawCircle(x,y,z,radius+count,color)
			count = count-2
		until count == (math.floor(thickness/2)-(math.floor(thickness/2)*2))-2
	end
end

function GetSpellCost(thing)
	local spell = GetSpell(thing)
	return spell.cost[GetSpellLevel(spell.key)]
end

function GetSpell(thing)
	local spell
	if type(thing) == "table" then
		spell = thing
	else		
		spell = spells[thing]
		if not spell then
			for _,s in pairs(spells) do
				if thing == s.key then
					spell = s
					break
				end
			end
		end
	end 
	return spell
end

function GetSpellDamage(thing, target)
	local spell = GetSpell(thing)
	if not spell or not spell.base then
		return 0
	end

	local lvl 
	if spell.key and not (spell.key == "D" or spell.key == "F") then
		lvl = GetSpellLevel(spell.key)
		if lvl == 0 then
			return 0
		end
	else 
		lvl = 1
	end


	local damage = spell.base[lvl]

	if spell.ap then 
		damage = damage + spell.ap*me.ap
	end
	if spell.ad then
		damage = damage + spell.ad*(me.baseDamage+me.addDamage)
	end 
	if spell.adb then
		damage = damage + spell.adb*me.addDamage
	end
   if spell.mana then
      damage = damage + spell.mana*me.maxMana
   end
	if spell.lvl then
		damage = damage + me.selflevel*spell.lvl
	end

	if target then
		if spell.type and spell.type == "P" then
			damage = CalcDamage(target, damage)
		else
			damage = CalcMagicDamage(target, damage)
		end
	end

	return math.floor(damage)
end

function OnProcessSpell(object, spell)
--	if object.name == me.name then
--		pp(object.name.." "..spell.name)
--	end
	for i, callback in ipairs(SPELL_CALLBACKS) do
		callback(object, spell)
	end	
end

-- Common stuff that should happen every time
function TimTick()
	if not LOADING then
		for i = 1, objManager:GetMaxNewObjects(), 1 do
			local object = objManager:GetNewObject(i)
			if object ~= nil then
				doCreateObj(object)
			end
		end
	else
		for i = 1, objManager:GetMaxObjects(), 1 do
			local object = objManager:GetObject(i)
			if object ~= nil then
				doCreateObj(object)
			end
		end
		LOADING = false
	end
	
	checkToggles()
	updateObjects()
	drawCommon()
	Util__OnTick()
end
