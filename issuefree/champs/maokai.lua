require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Maokai")

InitAAData({ 
   windup=.4, -- TODO
})

-- SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("maelstrom", {on=true, key=112, label="Maelstrom"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["smash"] = {
   key="Q", 
   range=600, 
   color=yellow, 
   base={70,115,160,205,250}, 
   ap=.4,
   delay=4, -- TestSkillShot
   speed=18, 
   width=120, -- reticle
   noblock=true,
} 
-- omnidirectional
spells["smashPB"] = {
   key="Q", 
   range=GetWidth(me)+125, 
   base={70,115,160,205,250}, 
   ap=.4,
   delay=4,
   speed=0,
   noblock=true
} 
spells["advance"] = {
   key="W", 
   range=525, 
   color=blue, 
   base=0, 
   targetMaxHealth={.09,.10,.11,.12,.13},
   targetMaxHealthAP=.0003,
} 
spells["sapling"] = {
   key="E", 
   range=1100, 
   color=violet, 
   base={40,60,80,100,120}, 
   ap=.4,
   delay=3.8, -- TestSkillShot
   speed=10+5, -- might go deeper
   noblock=true,
   radius=225, -- reticle (wiki says 175)
} 
spells["maelstrom"] = {
   key="R", 
   range=475, 
   color=red, 
   base={100,150,200}, 
   ap=.5,
} 

function Run()
   Circle(P.maelstrom)
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("smashPB") then
      return true
   end

   if CastAtCC("sapling") or
      CastAtCC("smash")
   then
      return true
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
         if KillMinionsInArea("sapling") then
            return true
         end

         if KillMinionsInLine("smash") then
            return true
         end

         if KillMinionsInPB("smashPB") then
            return true
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
   -- TestSkillShot("sapling", "Maokai_sapling_mis")
   -- TestSkillShot("smash", "maoki_trunkSmash_mis.troy")

   if SkillShot("sapling") then
      return true
   end

   if CastBest("smash") then
      return true
   end

   if CanUse("advance") then
      local target = GetMarkedTarget() or GetWeakestEnemy("advance")
      if target and not IsInRange("AA", target) then
         Cast("advance", target)
         PrintAction("Advance", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   if P.sap and GetHPerc(me) < .9 then
      local target = SortByDistance(GetInRange(me, "AA", MINIONS, CREEPS, PETS))[1]
      if AA(target) then
         PrintAction("AA for sap regen")
         return true
      end
   end

   return false
end

local function onCreate(object)
   PersistBuff("sap", object, "maokai_passive_indicator_graveDigger.troy")
   PersistBuff("maelstrom", object, "maoki_torrent_01_teamID_green.troy")
end

local function onSpell(unit, spell)
   if IsOn("maelstrom") then
      if not P.maelstrom and CanUse("maelstrom") then
         local target = CheckShield("maelstrom", unit, spell, "CHECK")
         if target then
            if #GetInRange(me, "maelstrom", ENEMIES) > 0 then
               Cast("maelstrom", me)
            end
         end
      end
   end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

