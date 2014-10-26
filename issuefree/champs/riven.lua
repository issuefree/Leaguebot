require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Riven")

InitAAData({
   windup=.25,
   extraRange=20,
   resets = {me.SpellNameQ}
})

SetChampStyle("bruiser")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["runic"] = {
   base=0, 
   ad=
      function() 
         if P.runic then 
            return .20+(math.floor(me.selflevel/3)*.05) 
         end
         return 0
      end
} 
spells["wings"] = {
   key="Q", 
   range=260+me.movespeed/10,
   rangeB=260,
   color=violet, 
   base={10,30,50,70,90}, 
   ad={.4,.45,.5,.55,.6},
   radius=112.5+GetWidth(me),
   radiusB={112.5,112.5,150},
   radiusE={162.5,112.5,200},
   timeout=4,
   type="P",
   name="RivenTriCleave"
} 

spells["burst"] = {
   key="W", 
   range=125+125,
   rangeE=135+125,
   rangeB=125+125,
   color=yellow, 
   base={50,80,110,140,170}, 
   adBonus=1,
   type="P"
} 
spells["valor"] = {
   key="E", 
   range=325-50,
   color=blue, 
   base={90,120,150,180,210}, 
   adBonus=1,
   type="H"
} 
spells["exile"] = {
   key="R", 
   timeout=15,
}
spells["windSlash"] = {
   key="R", 
   range=900, 
   color=red, 
   base={80,120,160}, 
   adBonus=.6,
   delay=2,
   speed=22,
   noblock=true,
   cone=30,
   width=300, -- hack until I actually do the math for cone into fireahead
   type="P"   
}

spells["windSlash"].damOnTarget = 
   function(target)
      local missingPerc = math.min(1-GetHPerc(target), .75)
      local dam = GetSpellDamage("windSlash")
      return dam * 8/3 * missingPerc
   end

local wingsStage = 1
local lastWings = 0

local exileExpireTime = 0

function GetCenterTarget(targets)
   return SortByDistance(targets, GetCenter(targets))[1]
end

function wingChain(start, minionPool, numKills)
   local hits,kills,_ = GetBestArea(start, "wings", .1, 1, minionPool)
   for _,hit in ipairs(hits) do
      hit.health = hit.health - GetSpellDamage("wings", hit)
   end
   for i,minion in rpairs(minionPool) do
      if minion.health <= 0 then
         table.remove(minionPool, i)
         numKills = numKills + 1         
      end
   end
   return GetCenterTarget(hits), numKills
end

function Run()
   spells["wings"].range = spells["wings"].rangeB + me.movespeed/10

   if me.SpellTimeQ < -1 then
      wingsStage = 1
   end

   spells["AA"].bonus = GetSpellDamage("runic")

   if P.exile then
      spells["wings"].radius = spells["wings"].radiusE[wingsStage]+GetWidth(me)
      spells["burst"].range = spells["burst"].rangeE
   else      
      spells["wings"].radius = spells["wings"].radiusB[wingsStage]+GetWidth(me)
      spells["burst"].range = spells["burst"].rangeB
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("burst") then
      return true
   end

   if P.exile and exileExpireTime - time() < 2 and exileExpireTime ~= 0 then
      local target = GetWeakestEnemy("windSlash")
      if target then
         CastFireahead("windSlash", target)
         PrintAction("Wind Slash - use it or lose it", target)
         return true
      end

      if HitMinionsInLine("windSlash", 1) then
         return true
      end
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then      
      if Alone() then
         if CanUse("wings") then
            if wingsStage == 1 then

               local minionPool = {}
               local numKills = 0
               for _,minion in ipairs(MINIONS) do
                  table.insert(minionPool, cloneTarget(minion))
               end

               local firstPos, numKills = wingChain(me, minionPool, numKills)
               if firstPos then
                  -- Circle(firstPos, 70, yellow)
                  -- PrintState(0, numKills)
                  nextPos, numKills = wingChain(firstPos, minionPool, numKills)
                  if nextPos then 
                     -- Circle(nextPos, 75, blue)
                     -- PrintState(1, numKills)
                     nextPos, numKills = wingChain(nextPos, minionPool, numKills)
                     if nextPos then
                        -- Circle(nextPos, 80, red)
                        -- PrintState(2, numKills)
                     end
                  end
               end

               if numKills >= 3 then
                  CastXYZ("wings", firstPos)
                  PrintAction("Wings for chain LHs", numKills)
                  return true
               end

            end
         end

         if not CanAttack() and CanUse("burst") and wingsStage == 1 then
            if #GetKills("burst", GetInRange(me, "burst", MINIONS)) >= 2 then
               Cast("burst", me)
               PrintAction("Burst for LH")
               return true
            end
         end

      end

      if not Engaged() then
         if CanUse("wings") and wingsStage > 1 then
            local hits, kills, score = GetBestArea(me, "wings", .1, 1, MINIONS)
            if score >= .3 then
               local target = GetAngularCenter(hits)
               if target then
                  CastXYZ("wings", target)
                  PrintAction("Wings to finish chain")
                  return true
               end
            end
         end
      end

   end
   
   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if CanUse("exile") and not P.exile and GetWeakestEnemy("wings", spells["wings"].radius) then
      Cast("exile", me)
      PrintAction("POWER UP")
      return true
   end

   if CanUse("windSlash") and P.exile and exileExpireTime ~= 0 then
      local target = GetWeakestEnemy("windSlash")
      if target and WillKill("windSlash", target) then
         CastFireahead("windSlash", target)
         PrintAction("Wind Slash for execute", target)
         return true
      end
   end

   if GetWeakestEnemy("Tiamat") then
      if UseItem("Tiamat", me, true) or
         UseItem("Ravenous Hydra", nil, true)
      then
         PrintAction("Hydra Cleave")
         return true
      end
   end

   -- easy stun if I can
   if CastBest("burst") then
      Cast("burst", me)
      return true
   end

   -- could do a chase for execute.

   if CanUse("wings") and CanAct() then
      local target = GetMarkedTarget() or GetWeakestEnemy("wings", spells["wings"].radius)
      if target and ( not IsInAARange(target) or ( P.runic and not CanAttack() ) ) then
         CastXYZ("wings", target)
         PrintAction("Wings "..wingsStage, target)
         return true
      end

      if wingsStage > 1 then
         local target = GetMarkedTarget() or GetWeakestEnemy("wings", 500)
         if target then
            CastXYZ("wings", target)
            PrintAction("Wings to close gap", target)
            return true
         end
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   return false
end

function AutoJungle()
   local creep = GetBiggestCreep(GetInRange(me, "AA", CREEPS))
   local score = ScoreCreeps(creep)
   if AA(creep) then
      PrintAction("AA "..creep.charName)
      return true
   end

   if CanAct() then
      if CanUse("valor") and GetHPerc(me) < .8 then
         local creep = GetBiggestCreep(GetInRange(me, "valor", CREEPS))
         if creep then
            CastXYZ("valor", creep)
            PrintAction("Valor in jungle")
            return true
         end
      end

      if CanUse("wings") then
         local hits, kills, score = GetBestArea(me, "wings", .1, 1, CREEPS)
         if score > 0 then
            local target = GetAngularCenter(hits)
            if target then
               CastXYZ("wings", target)
               PrintAction("Wings in jungle")
               return true
            end
         end
      end

      if CanUse("Tiamat") or CanUse("Ravenous Hydra") then
         if #GetInRange(me, "Tiamat", CREEPS) >= 2 then
            Cast("Tiamat", me)
            Cast("Ravenous Hydra", me)
            PrintAction("Crescent in jungle")
            return true
         end
      end

      if CanUse("burst") then
         local creep = GetBiggestCreep(GetInRange(me, "burst", CREEPS))
         if creep then
            Cast("burst", me)
            PrintAction("Burst in jungle")
            return true
         end
      end
   end
end   
SetAutoJungle(AutoJungle)

local function onCreate(object)
   Persist("runic", object, "Riven_Skin05_P_Buff")
   Persist("exile", object, "Riven_Base_R_Sword")
end

local function onSpell(unit, spell)
   if ICast("wings", unit, spell) then 
      if wingsStage < 3 then
         wingsStage = wingsStage + 1 
      end
      lastWings = time()
      if IsLoLActive() and IsChatOpen() == 0 then
         send.key_press(SKeys.PgUp, 100)
      end
   end

   if IsMe(unit) and spell.name == "RivenFengShuiEngine" then
      exileExpireTime = time()+spells["exile"].timeout
   end

   if IsMe(unit) and spell.name == "rivenizunablade" then
      exileExpireTime = 0
   end

end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")
