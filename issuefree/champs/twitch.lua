require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Twitch")

InitAAData({ 
   projSpeed = 2.5, windup = .25,
   -- extraRange=-10,
   particles = {"twitch_basicAttack_mis", "twitch_sprayandPray_mis"},
})

SetChampStyle("marksman")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["ambush"] = {
   key="Q"
}
spells["cask"] = {
   key="W", 
   range=950, 
   color=yellow, 
   delay=2,
   speed=14,
   noblock=true,
   radius=300
}
spells["expColor1"] = {
   key="E", 
   range=1198, 
   color=red
}
spells["expColor2"] = {
   key="E", 
   range=1202, 
   color=red
}
spells["contaminate"] = {
   key="E", 
   range=1200,
   color=yellow, 
   base=0,
   damOnTarget=function(target)
      return getStacks(target)*GetSpellDamage("contaminateStack")
   end
}
spells["contaminateStack"] = {
   base={20,35,50,65,80}, 
   ap=.2,
   adBonus=.25
}

spells["rattat"] = {
   key="R",
   color=red,
   range=850,
   onHit=true,
}

function Run()
   drawPoisons()

   if CastAtCC("cask") then
      return true
   end

   if StartTickActions() then
      return true
   end

   if P.stealth then
      if HotKey() then
         if GetDistance(mousePos) < 3000 then
            MoveToCursor()
            CURSOR = Point(mousePos)
         end
      end

      PrintAction("STEALTH")
      return
   end

   if CanUse("contaminate") then
      local targets = GetWithBuff("poison6", GetInRange(me, "contaminate", ENEMIES))
      if #targets > 0 then
         Cast("contaminate", me)
         PrintAction("Contaminate max stacks", targets[1])
         return true
      end

      local kills = GetKills("contaminate", GetInRange(me, "contaminate", ENEMIES))
      if #kills > 0 then
         Cast("contaminate", me)
         PrintAction("Contaminate for execute", kills[1])
         return true
      end
   end

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") then
      if VeryAlone() and CanUse("contaminate") then
         local kills = GetKills("contaminate", GetInRange(me, "contaminate", MINIONS))
         if #kills >= 2 then
            Cast("contaminate", me)
            PrintAction("Contaminate for LH", #kills)
            return true
         end
      end
   end

   EndTickActions()
end

function getStacks(target)
   for i=1,6 do
      if HasBuff("poison"..i, target) then
         return i
      end
   end
   return 0
end
function circlePoison(p, count)
   for i=1,count do
      if i%2 == 0 then
         Circle(p, 85+(i*2), green)
      else
         Circle(p, 85+(i*2), yellow)
      end
   end
end
function drawPoisons()
   for i=1,6 do
      local poisoned = GetWithBuff("poison"..i, MINIONS, ENEMIES)
      for _,p in ipairs(poisoned) do
         circlePoison(p, i)         
      end
   end
end

function Action()
   if CanUse("cask") then      
      local hits, kills, score = GetBestArea(me, "cask", 1, 1, ENEMIES)
      if #hits >= 2 or
         ( #hits == 1 and not IsInAARange(hits[1]) )
      then
         CastXYZ("cask", GetCastPoint(hits, "cask"))
         PrintAction("Cask")
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end
   return false
end

local function onObject(object)
   PersistOnTargets("poison1", object, "twitch_poison_counter_01", ENEMIES, MINIONS)
   PersistOnTargets("poison2", object, "twitch_poison_counter_02", ENEMIES, MINIONS)
   PersistOnTargets("poison3", object, "twitch_poison_counter_03", ENEMIES, MINIONS)
   PersistOnTargets("poison4", object, "twitch_poison_counter_04", ENEMIES, MINIONS)
   PersistOnTargets("poison5", object, "twitch_poison_counter_05", ENEMIES, MINIONS)
   PersistOnTargets("poison6", object, "twitch_poison_counter_06", ENEMIES, MINIONS)

   PersistBuff("stealth", object, "Twitch_Base_Q_Invisible.troy")
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
