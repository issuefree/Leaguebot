require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Caitlyn")
pp(" - alert for snipe")
pp(" - try to trap to kite or chase")
pp(" - piltover people out of AA range")
pp(" - farming w/headshot clears with piltover")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("pp", {on=true, key=113, label="Piltover", auxLabel="{0}", args={"pp"}})
AddToggle("trap", {on=true, key=114, label="Trap"})
AddToggle("execute", {on=true, key=115, label="AutoExecute", auxLabel="{0}", args={"ace"}})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

function getAceRange()   
   if GetSpellLevel("R") == 1 then return 2000 end
   if GetSpellLevel("R") == 2 then return 2500 end
   if GetSpellLevel("R") == 3 then return 3000 end
   return 0
end

spells["pp"] = {
   key="Q", 
   range=1200, 
   color=violet, 
   base={20,60,100,140,180}, 
   ad=1.3,
   cost={50,60,70,80,90},
   delay=2,
   speed=20,
   type="P",
   width=80
}
spells["trap"] = {
   key="W", 
   range=800, 
   base={80,130,180,230,280}, 
   ap=.6,
   cost=50,
   delay=7,
   speed=99
}
spells["net"] = {
   key="E", 
   range=800, 
   color=yellow, 
   base={80,130,180,230,280}, 
   ap=.8,
   cost=75
}
spells["recoil"] = {
   key="E", 
   range=400+50, 
   color=blue
}
spells["ace"] = {
   key="R", 
   range=getAceRange, 
   color=red, 
   base={250,475,700}, 
   type="P",
   adBonus=2
}
spells["headshot"] = {
   base={0},
   ad=0
}

local headshot = nil 

function Run()
   TimTick()

   if IsRecalling(me) or me.dead == 1 then
      return
   end

   if Check(headshot) then
      spells["headshot"].ad = 1.5
   else
      spells["headshot"].ad = 0
   end
   if HotKey() and CanAct() then
      Action()
   end
   
   if IsOn("execute") then
      local target = GetWeakEnemy("PHYSICAL", getAceRange())
      if target and target.health < GetSpellDamage("ace", target) then
         PlaySound("Beep")
         DrawThickCircleObject(target, 100, red, 6)
      end
   end
end

function Action()
   UseItems()
   
   local target = GetWeakEnemy("PHYSICAL", spells["AA"].range)
   if target then
      if IsOn("trap") and 
         CanUse("trap") and 
         me.mana > GetManaCost("net") + GetManaCost("trap") 
      then
         -- trap targets that are moving mostly directly toward or away from me.
         if SSGoodTarget(target, "trap", 30) then
            CastSpellFireahead("trap", target)            
            return
         end
      end

      if AA(target) then
         return
      end
   end
   local targets = GetInRange(me, "pp", ENEMIES)
   targets = FilterList(targets, function(item) return GetDistance(item) > spells["AA"].range end)
   target = GetWeakest("pp", targets)
   if target then
      if IsOn("pp") and CanUse("pp") and me.mana > GetManaCost("net") + GetManaCost("pp") then
         if SSGoodTarget(target, "pp") then
            CastSpellFireahead("pp", target)
            return
         end
      end

   end

   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         return
      end
   end

   if IsOn("clearminions") and Alone() then
      -- check for a big clear from pp
      if IsOn("pp") and KillMinionsInLine("pp", 4, false, -100, false) then
         return
      end

      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      local minion = minions[#minions]
      if minion and AA(minion) then
         return
      end
   end

   if IsOn("move") then
      MoveToCursor() 
   end
end

local function onObject(object)
   if find(object.charName, "headshot_rdy") and 
      GetDistance(object) < 50 
   then      
      headshot = StateObj(object)
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