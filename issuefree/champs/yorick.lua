require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Yorick")

SetChampStyle("bruiser")

InitAAData({ 
   windup=.30,
   resets = {me.SpellNameQ}
})

AddToggle("tear", {on=true, key=112, label="Charge Tear"})
AddToggle("autoDeath", {on=true, key=113, label="Omen of Death allies"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2} / {3}", args={GetAADamage, "war", "pestilence", "famine"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["war"] = {
   key="Q",
   base={30,60,90,120,150},
   ad=.2,
   type="P",
   modAA="war",
   object="yorick_spectralGhoul_attack_buf_self",
   range=GetAARange,
   cost=40   
}
spells["pestilence"] = {
   key="W",
   range=600,
   color=yellow,
   base={60,95,130,165,200},
   ap=1,
   type="M",
   radius=100+125,
   cost={55,60,65,70,75}
} 
spells["famine"] = {
   key="E",
   range=550,
   color=violet,
   base={55,85,115,145,175},
   adBonus=1,
   type="M",
   cost={10,20,30,40,50}
} 
spells["death"] = {
   key="R",
   range=900,
   color=red,
   cost=100
}

local numGhouls = 0

function Run()
   numGhouls = 0
   if P.warSpectre then
      numGhouls = numGhouls + 1
   end
   if P.pestilence then
      numGhouls = numGhouls + 1
   end
   if P.famine then
      numGhouls = numGhouls + 1
   end
   if P.death then
      numGhouls = numGhouls + 1
   end

   spells["AA"].bonus = 0
   spells["AA"].bonus = GetAADamage()*numGhouls*.05

   if StartTickActions() then
      return true
   end

   if IsOn("tear") then
      UseItem("Muramana")
   end

   AutoPet(P.death)

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

   if IsOn("tear") and VeryAlone() and CanChargeTear() and GetMPerc(me) > .9 and
      #GetInRange(me, 1000, CREEPS, MINIONS) == 0
   then
      if CanUse("pestilence") then
         Cast("pestilence", me)
         PrintAction("Pestilence for charge")
         return true
      end
      if CanUse("war") then
         Cast("war", me)
         PrintAction("War for charge")
         return true
      end
   end

	-- auto stuff that should happen if you didn't do something more important

   -- I could write a skillshot blocker with pestilence.

   if IsOn("lasthit") then
      if Alone() then
         
         if ModAAFarm("war") then
            return true
         end

         if KillMinionsInArea("pestilence", GetThreshMP(thing, .1, 1)) then
            return true
         end

         if KillMinion("famine", "strong") then
            return true
         end

      end
   end
   
   if IsOn("autoDeath") and CanUse("death") then
      local targets = GetInRange(me, "death", ALLIES)
      local target = SelectFromList(targets, 
         function(ally)
            if GetHPerc(ally) < .33 and #GetInRange(ally, 500, ENEMIES) > 0 then
               return 1 - GetHPerc(ally)
            end
            return 0
         end 
      )
      if target then
         Cast("death", target)
         PrintAction("Omen of Death", target)
         return true
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
   
   if CastBest("pestilence") then
      return true
   end

   if CastBest("famine") then
      return true
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target, "war") then
      return true
   end

   return false
end
function FollowUp()
   if IsOn("move") then
      if MeleeMove() then
         return true
      end
   end
   return false
end

local function onCreate(object)
   Persist("warSpectre", object, "Clyde", me.team)
   Persist("pestilence", object, "Inky", me.team)
   Persist("famine", object, "Blinky", me.team)
   if object.type == 12 then
      for _,hero in ipairs(concat(ENEMIES, ALLIES)) do
         if object.charName == hero.charName then
            Persist("death", object)
            break
         end
      end
   end

end

local function onSpell(unit, spell)
   CheckPetTarget(P.death, unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

