require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Gragas")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "barrel"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["barrel"] = {
  key="Q", 
  range=850, 
  color=violet, 
  base={80,120,160,200,240},
  ap=.6,
  delay=2,
  speed=12,
  radius=275,
  cost={60,65,70,75,80},
  noblock=true,
  overShoot=50
}
spells["rage"] = {
  key="W",
  base={20,50,80,110,140},
  ap=.3,
  percMaxHealth={.08,.09,.10,.11,.12}
}
spells["slam"] = {
  key="E", 
  range=650,
  color=yellow, 
  base={80,130,180,230,280}, 
  ap=.6,
  delay=1.6,
  speed=9,
  area=150,
  cost=50
}
spells["cask"] = {
  key="R", 
  range=1050,
  color=red, 
  base={200,300,400}, 
  ap=.7,
  delay=1.6,
  speed=30,
  radius=400,
  cost=100
}

spells["AA"].damOnTarget = 
   function(target)
      if P.rage then
         return GetSpellDamage("rage", target)
      end
   end

function Run()
   if P.rage then
      spells["AA"].bonus = GetSpellDamage("vorpal")
   else
      spells["AA"].bonus = 0

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

   if CastAtCC("barrel") then
      return true
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
  Persist("rage", object, "DRUNKEN RAGE OBJECT")
end

local function onSpell(unit, spell)
   -- if find(spell.name, "GragasDrunkenRage") and unit.team == me.team then
   --    CHANNELLING = true
   --    DoIn(function() CHANNELLING = false end, 1000, "DrunkenRage")
   -- end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
