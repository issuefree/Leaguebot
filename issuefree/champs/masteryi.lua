require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Master Yi")

function getADam()
   if spells["alpha"].spellLevel > 0 then
      return GetSpellDamage("alpha") + GetLVal(spells["alpha"], "mmBonus")
   else
      return 0
   end
end

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, getADam}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["alpha"] = {
   key="Q", 
   range=600, 
   color=violet, 
   base={25,60,95,130,165}, 
   ad=1,
   mmBonus={75,100,125,150,175},
   type="P",
   cost={70,80,90,100,110},
   chainRange=400
}
spells["meditate"] = {
   key="W", 
   cost=50
}
spells["wuju"] = {
   key="E",
   base={10,15,20,25,30},
   ad={.1,.125,.15,.175,.2},
   type="T"
}
spells["highlander"] = {
  key="R",
  cost=100
}

-- it might be easier to set a bounding radius and see if looking 
-- for a chain is worth it rather than calculating all of the possible chains
-- i.e. Find a target and see if you can chain rather than looking at
-- all of the chains and finding the best chain
local maxChainDist = spells["alpha"].chainRange*3

function getAlphaKills(target, dam)
   local kills = 0
   local path = getAlphaPath(target)
   for _, t in ipairs(path) do
      if CalculateDamage(t, dam) > t.health then
         kills = kills + 1
      end            
   end
   return kills
end

function Run()

   if HasBuff("wuju", me) then
      spells["AA"].bonus = GetSpellDamage("wuju")
   end


   if IsChannelling(P.med) then
      CHANNELLING = true
      return true
   end

   if StartTickActions() then
      return true
   end

   if HotKey() then
      UseItems()
      if Action() then
         return true
      end
   end

   if IsOn("jungle") then

   end


   if IsOn("lasthit") then
	   if CanUse("alpha") and Alone() then
         local bestT, bestK = SelectFromList(GetInRange(me, "alpha", MINIONS), getAlphaKills, getADam())

	   	if (GetMPerc(me) > .75 and bestK >= 2) or
            (GetMPerc(me) > .5 and bestK >= 3) or
            (GetMPerc(me) > .33 and bestK >= 4)
         then
	   		Cast("alpha", bestT)
	   		PrintAction("Alpha minions:", bestK)
	   		return true
	   	end
	   end
	end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
	if CanUse("alpha") then

		-- Execute direct target with alpha
		local target = GetWeakestEnemy("alpha")	
		if target and WillKill("alpha", target) then
			if not UnderTower(target) then
				Cast("alpha", target)
				PrintAction("Alpha (primary)", target)
				AttackTarget(target) -- just in case
				return true
			end
		end

		-- look for an execute
		local targets = SortByHealth(GetInRange(me, "alpha", MINIONS, ENEMIES))
		for _,target in ipairs(targets) do
			if not UnderTower(target) then
				for _,t in ipairs(getAlphaPath(target)) do
					if IsEnemy(t) and WillKill("alpha", t) then
						Cast("alpha", target)
						PrintAction("Alpha (chain)", t)
						return true
					end
				end
			end
		end

		local target = GetMarkedTarget() or GetWeakestEnemy("alpha")
		if target and 
			GetDistance(target) < GetSpellRange("alpha") and
			GetDistance(target) > GetSpellRange("AA") and
			not UnderTower(target) 
		then
			Cast("alpha", target)
			PrintAction("Alpha (gap)", target)
			return true
		end

	end

   if not P.wuju and CanUse("wuju") and GetWeakestEnemy("AA",100) then
      Cast("wuju", me)
      PrintAction("Wuju")
      return true
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if target then
      if AA(target) then
         PrintAction("AA", target)
         return true
      end
   end
   return false   
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clear") and Alone() then
      if HitMinion("AA", "strong") then
         return true
      end
   end

   if IsOn("move") then
      if MeleeMove() then
         return true
      end
   end

   return false
end

function getAlphaPath(target)
   local testNearby = SortByDistance(GetAllInRange(target, maxChainDist, MINIONS, ENEMIES), target)
   local path = {}

   local jumps = 0
   while jumps < 4 do
      local nearestI = GetNearestIndex(target, testNearby)
      if nearestI then
         if GetDistance(target, testNearby[nearestI]) > spells["alpha"].chainRange then
            break
         end
         table.insert(path, testNearby[nearestI])
         table.remove(testNearby, nearestI)
      else
         break  -- out of bounce targets
      end
      jumps = jumps+1
   end
   return path
end


local function onObject(object)
	PersistBuff("wuju", object, "MasterYi_Base_E_SuperChraged_buf")
	PersistBuff("wujuBase", object, "MasterYi_Base_E_buff")
	PersistBuff("med", object, "MasterYi_Base_W_Buf")
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
