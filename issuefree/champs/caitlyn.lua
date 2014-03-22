require "issuefree/timCommon"
require "issuefree/modules"


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

spells["pp"] = {
   key="Q", 
   range=1200, 
   color=violet, 
   base={20,60,100,140,180}, 
   ad=1.3,
   cost={50,60,70,80,90},
   delay=5,
   speed=22,
   type="P",
   width=80,
   noblock=true
}
spells["trap"] = {
   key="W", 
   range=800, 
   base={80,130,180,230,280}, 
   ap=.6,
   cost=50,
   delay=7,
   speed=0,
   noblock=true
}
spells["net"] = {
   key="E", 
   range=800, 
   color=yellow, 
   base={80,130,180,230,280}, 
   ap=.8,
   type="M",
   cost=75
}
spells["recoil"] = {
   key="E", 
   range=400+50, 
   color=blue
}
spells["ace"] = {
   key="R", 
   range={2000, 2500, 3000},
   color=red, 
   base={250,475,700}, 
   type="P",
   adBonus=2
}
spells["headshot"] = {
   base={0},
   ad=.5,
   type="P"
}

spells["AA"].damOnTarget = 
   function(target)
      if P.headshot and not IsHero(target) then
         return GetSpellDamage("headshot")*2
      end
   end

function Run()
   if P.headshot then
      spells["AA"].bonus = GetSpellDamage("headshot")
   else
      spells["AA"].bonus = 0
   end

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end
   
   if IsOn("execute") and CanUse("ace") then
      local target = GetWeakestEnemy("ace")
      if target and WillKill("ace", target) then
         LineBetween(me, target, 3)
         Circle(target, 100, red, 6)
      end
   end

   if CastAtCC("trap") then
      return true
   end

   if HotKey() then
      UseItems()

      if Action() then
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
   if IsOn("trap") and 
      CanUse("trap") and 
      me.mana > GetSpellCost("net") + GetSpellCost("trap") 
   then
      if SkillShot("trap") then
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AA(target) then
      PrintAction("AA", target)
      return true
   end

   if IsOn("pp") and 
      CanUse("pp") and 
      me.mana > GetSpellCost("net") + GetSpellCost("pp") 
   then
      -- get the weakest target within pp range but out of AA range
      local targets = GetGoodFireaheads("pp", ENEMIES)
      targets = FilterList(targets, function(item) return GetDistance(item) > GetSpellRange("AA") end)
      local target = GetWeakest("pp", targets)
      if target then
         CastFireahead("pp", target)
         PrintAction("PP", target)
         return true
      end
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      -- check for a big clear from pp
      if IsOn("pp") then
         if HitMinionsInLine("pp", 4) then
            return true
         end
      end

      if HitMinion("AA", "strong") then
         return true
      end
   end

   if IsOn("move") then
      if RangedMove() then
         return true
      end
   end
   
   return false
end

local function onObject(object)
   PersistBuff("headshot", object, "headshot_rdy")
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