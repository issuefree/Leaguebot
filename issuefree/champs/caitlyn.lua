require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Caitlyn")
pp(" - alert for snipe")
pp(" - try to trap to kite or chase")
pp(" - piltover people out of AA range")
pp(" - farming w/headshot clears with piltover")

InitAAData({
   projSpeed = 2.5, windup=.2,
   minMoveTime=0,
   particles = {"caitlyn_Base_mis", "caitlyn_Base_passive"},
   attacks = {"attack", "CaitlynHeadshotMissile"}
})

SetChampStyle("marksman")

AddToggle("pp", {on=true, key=112, label="Piltover", auxLabel="{0}", args={"pp"}})
AddToggle("trap", {on=true, key=113, label="Trap"})
AddToggle("execute", {on=true, key=114, label="AutoExecute", auxLabel="{0}", args={"ace"}})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["pp"] = {
   key="Q", 
   range=1200, 
   color=violet, 
   base={20,60,100,140,180}, 
   ad=1.3,
   cost={50,60,70,80,90},
   delay=7-3, -- reduce delay for less leading
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
   type="M",
   cost=50,
   delay=8-3, -- reduce delay for less leading
   speed=0,
   radius=75,
   noblock=true
}
spells["net"] = {
   key="E", 
   range=950, 
   color=yellow, 
   base={80,130,180,230,280}, 
   ap=.8,
   type="M",
   cost=75,
   delay=2.25,
   speed=20
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

   if StartTickActions() then
      return true
   end
   
   if IsOn("execute") and CanUse("ace") then
      local target = GetWeakestEnemy("ace")
      if target and WillKill("ace", target) then
         LineBetween(me, target, 3)
         Circle(target, 100, red, 6)
      end
   end

   if CastAtCC("trap") or
      CastAtCC("pp")
   then
      return true
   end

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end   

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   -- TestSkillShot("pp")
   -- TestSkillShot("trap")
   -- TestSkillShot("net")

   if IsOn("trap") and 
      CanUse("trap") and 
      me.mana > GetSpellCost("net") + GetSpellCost("trap") and
      ( not CanUse("ace") or me.mana > GetSpellCost("ace") + GetSpellCost("trap") )
   then
      if SkillShot("trap") then
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   if IsOn("pp") and 
      CanUse("pp") and 
      me.mana > GetSpellCost("net") + GetSpellCost("pp") and
      ( not CanUse("ace") or me.mana > GetSpellCost("ace") + GetSpellCost("pp") ) and
      not GetWeakestEnemy("AA")
   then
      if SkillShot("pp") then
         return true
      end
   end

   return false
end

function FollowUp()
   if IsOn("clear") and Alone() then
      -- check for a big clear from pp
      if IsOn("pp") then
         if HitMinionsInLine("pp", GetThreshMP("pp", .05, 2)) then
            return true
         end
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