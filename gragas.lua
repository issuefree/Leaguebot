require "timCommon"
require "modules"

pp("\nTim's Gragas")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "barrel"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["barrel"] = {
  key="Q", 
  range=950, 
  color=violet, 
  base={85,135,185,235,285},
  ap=.9,
  delay=2,
  speed=12,
  radius=275,
  cost={80,90,100,110,120},
  noblock=true,
  overShoot=50
}
spells["rage"] = {
  key="W"
}
spells["slam"] = {
  key="E", 
  range=650,
  color=yellow, 
  base={80,120,160,200,240}, 
  ap=.5,
  ad=.66,
  delay=2,
  speed=9,
  area=150,
  cost=75
}
spells["cask"] = {
  key="R", 
  range=1050,
  color=red, 
  base={200,325,450}, 
  ap=1,
  delay=2,
  speed=30,
  radius=400,
  cost={100,125,150}
}


function Run()
   if P.barrel then
      Circle(P.barrel)
   end

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   if P.barrel and isBarrelActive() then
      if #GetInRange(P.barrel, spells["barrel"].radius, ENEMIES) > 0 then
         Cast("barrel", me, true)
         PrintAction("BOOM")
      end

      local minions = GetInRange(P.barrel, spells["barrel"].radius, MINIONS)
      local kills = GetKills("barrel", minions)
      if #kills > 2 then
         Cast("barrel", me, true)
         PrintAction("Pop to kill "..#kills.." minions")
      end

   end

   if HotKey() and CanAct() then
      UseItems()
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and CanUse("barrel") and not P.barrel and VeryAlone() then
      -- lasthit with barrel if it kills 3 minions or more
      if KillMinionsInArea("barrel", 3) then
         return true
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
end

function Action()
   if not isBarrelActive() then
      if SkillShot("barrel") then
         return true
      end
   end
end

function FollowUp()
end

function isBarrelActive()
   return me.SpellNameQ == "gragasbarrelrolltoggle"
end

local function onObject(object)
  Persist("barrel", object, "gragas_barrelfoam")
end

local function onSpell(unit, spell)
   if find(spell.name, "GragasDrunkenRage") and unit.team == me.team then
      CHANNELLING = true
      DoIn(function() CHANNELLING = false end, 1000, "DrunkenRage")
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
