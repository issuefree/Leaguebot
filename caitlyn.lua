require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Caitlyn")

AddToggle("lasthit", {on=true, key=112, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("execute", {on=true, key=113, label="AutoExecute", auxLabel="{0}", args={"ace"}})

function getAceRange()   
   if GetSpellLevel("R") == 1 then return 2000 end
   if GetSpellLevel("R") == 2 then return 2500 end
   if GetSpellLevel("R") == 3 then return 3000 end
   return 0
end

spells["pp"] = {key="Q", range=1300, color=violet, base={20,60,100,140,180}, ad=1.3}
spells["trap"] = {key="W", range=800, base={80,130,180,230,280}, ap=.6}
spells["net"] = {key="E", range=800, color=yellow, base={80,130,180,230,280}, ap=.8}
spells["recoil"] = {key="E", range=400+50, color=blue}
spells["ace"] = {key="R", range=getAceRange, color=red, base={250,475,700}, adBonus=2}
spells["headshot"] = {ad=0}

function test()
   pp("later")
end

function Run()
   TimTick()
   
   if HotKey() then
      UseItems()
   end
   
   if IsOn("execute") then
      local target = GetWeakEnemy("PHYSICAL", getAceRange())
      if target and target.health < GetSpellDamage("ace", target) then
         PlaySound("Beep")
      end
   end
   if IsOn("lasthit") and not GetWeakEnemy("MAGIC", 950) then
      if KillWeakMinion("AA", 100) then
         OrbWalk(500)
      end
   end
end

local function onObject(object)
   if find(object.charName, "headshot_rdy") and 
      GetDistance(object) < 50 
   then
      spells["headshot"].ad = 1.5
   end   
end

local function onSpell(unit, spell)
--   DumpSpells(unit, spell)
   if unit.charName == me.charName and
      find(spell.name, "HeadshotMissile")
   then
      spells["ace"].ad = 0
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")