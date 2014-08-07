require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Sona")


AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})
AddToggle("", {on=true, key=113, label=""})
AddToggle("tear", {on=true, key=114, label="Charge Tear / Fastwalk"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "blue"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})



spells["blue"] = {
   key="Q", 
   range=650, 
   color=blue, 
   base={40,80,120,160,200}, 
   ap=.5
}
spells["green"] = {
   key="W", 
   range=1000, 
   color=green, 
   base={25,45,65,85,105}, 
   ap=.2,
   damOnTarget=
      function(target)
         if target then
            return GetSpellDamage("green")*(1-GetHPerc(target))
         end
         return 0
      end
   type="H"
}
spells["violet"] = {
   key="E", 
   range=350, 
   color=violet,
   cost=65
}
spells["yellow"] = {
   key="R", 
   range=1000, 
   color=yellow, 
   base={150,250,350}, 
   ap=.5
}

pcBlue = nil
pcGreen = nil
pcViolet = nil

-- TODO track power chord and change AA target depending.

function Run()
   if StartTickActions() then
      return true
   end

   if IsOn("healTeam") and CanUse("green") then
      local closeAllies = SortByHealth(GetInRange(me, "green", ALLIES))
      local target
      for _,ca in ipairs(closeAllies) do
         if not IsMe(ca) and
            not IsRecalling(ca)
         then
            target = ca
         end
      end
      
      if GetMPerc(me) > .9 then
         -- TODO check if there's an OOR heal that I should wait for
         -- else top off
         if target.health + GetSpellDamage("green", target) < target.maxHealth*.9 or
            me.health + GetSpellDamage("green", me) < me.maxHealth*.9
         end
            Cast("green", me)
            PrintAction("Top off")
            return true
         end
      end

      if target.health + GetSPellDamage("green", target) < target.maxHealth*.66 or
         me.health + GetSPellDamage("green", me) < me.maxHealth*.66
      then
         Cast("green", me)
         PrintAction("Heal because I should", target)
         return true
      end

   end

   if HotKey() then
      if Action() then
         return true
      end
   end
   
   if IsOn("lastHit") and Alone() and CanUse("blue") then
      local minionRays = 2
      local targets = SortByDistance(GetInRange(me, "blue", MINIONS))
      for _,minion in ipairs(targets) do
         if minionRays <= 0 then
            break
         end
         if WillKill("blue", minion) then
            Cast("blue", minion)
            PrintAction("Blue for lasthit")
            return true
         end
         minionRays = minionRays - 1
      end
   end

   if IsOn("tear") then
      if CanUse("violet") and Alone() then
         if GetDistance(HOME) > 1000 and GetMPerc(me) > .9 then
            Cast("violet", me)
            return true
         elseif CanChargeTear() and GetMPerc(me) > .75 then
            Cast("violet", me)
            return true
         end
      end

      if CanUse("blue") and not CanUse("violet") and VeryAlone() then
         if #GetInRange(me, "blue", CREEPS, MINIONS) == 0 then
            if GetMPerc(me) > .75 and CanChargeTear() then
               Cast("blue", me)
               return true
            end
         end
      end
   end

   EndTickActions()
end

function Action()
   if CanUse("blue") then
      local target = GetWeakestEnemy("blue")
      if target then
         Cast("blue", me)
         PrintAction("Blue", target)
         return true
      end
   end

   if CanUse("violet") and not VeryAlone() and GetMPerc(me) > .5 then
      if #GetInRange(me, "violet", ALLIES) >= 2 then
         Cast("violet", me)
         PrintAction("Violet in teamfight")
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

end

local function onObject(object)
   if find(object.charName, "SonaPowerChordReady") then
      if find(object.charName, "blue") then
         pcBlue = {object.charName, object}
      elseif find(object.charName, "green") then
         pcGreen = {object.charName, object}
      elseif find(object.charName, "violet") then
         pcViolet = {object.charName, object}
      end
   end
   
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")