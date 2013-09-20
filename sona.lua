require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Sona")
AddToggle("lastHit", {on=false, key=112, label="Last Hit", auxLabel="{0}", args={"blue"}})
AddToggle("healTeam", {on=true, key=113, label="Heal Team", auxLabel="{0}", args={"green"}})
AddToggle("tear", {on=true, key=114, label="Charge Tear / Fastwalk"})

spells["blue"] = {
   key="Q", 
   range=825, 
   color=blue, 
   base={50,100,150,200,250}, 
   ap=.7,
   cost={45,50,55,60,65}
}
spells["green"] = {
   key="W", 
   range=1000, 
   color=green, 
   base={40,60,80,100,120}, 
   ap=.25,
   cost={60,65,70,75,80}
}
spells["violet"] = {
   key="E", 
   range=999, 
   color=violet,
   cost=65
}
spells["yellow"] = {
   key="R", 
   range=1001, 
   color=yellow, 
   base={150,250,350}, 
   ap=.8,
   cost={100,150,200}
}

pcBlue = nil
pcGreen = nil
pcViolet = nil

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   if IsOn("healTeam") and CanUse("green") then
      local closeAllies = GetInRange(me, "green", ALLIES)
      local count = 0
      for _,hero in ipairs(closeAllies) do
         if not IsRecalling(hero) then
            if hero.health + GetSpellDamage(spell) < hero.maxHealth*.66 then
               Cast("green", me)
               PrintAction("Heal because I should", hero)
               break
            end            
            if hero.health + GetSpellDamage(spell) < hero.maxHealth*.9 then
               count = count + 1
               if count >= 2 then
                  Cast("green", me)
                  PrintAction("Heal because I can")
                  break
               end
            end
         end
      end
   end

   if HotKey() then
      UseItems()
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