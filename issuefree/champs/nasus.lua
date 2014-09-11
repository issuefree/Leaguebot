require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Nasus")

local config = {}

function strikeBonus()
   return spells["strike"].bonus
end

function setStrikes(val)
   spells["strike"].bonus = val
   config["strikes"] = val
   SaveConfig("nasus", config)
end

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}      {2}", args={GetAADamage, "strike", strikeBonus}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["strike"] = {
   key="Q", 
   base={30,50,70,90,110}, 
   bonus=0,
   type="P",
   modAA="strike",
   object="Nasus_Base_Q_Buf",
   range=GetAARange,
   cost=20
}
spells["wither"] = {
   key="W", 
   range=600,
   color=yellow,
   cost=80
}
spells["fire"] = {
   key="E", 
   range=650,
   color=violet,
   base={55,95,135,175,215},
   ap=.6,
   radius=400,
   delay=4,
   speed=0,
   noblock=true,
   cost={70,85,100,115,130}
}
spells["fury"] = {
   key="R", 
   range=350,
   color=red,
   cost=100
}

config = LoadConfig("nasus")
spells["strike"].bonus = config["strikes"]

if GetSpellLevel("Q") == 0 then
   setStrikes(0)
end

local victim

function Run()
   if StartTickActions() then
      return true
   end
   
   if HotKey() then
      if Action() then
         return true
      end
   end   
   

   if IsOn("lasthit") and Alone() then
      if CanUse("strike") then
         local targets = SortByDistance(GetInRange(me, spells["AA"].range+100, CREEPS, MINIONS))
         for _,target in ipairs(targets) do 
            if WillKill("strike", target) then
               Cast("strike", target)
               AttackTarget(target) -- not using AA as I want to interupt auto attacks
               needMove = true
               PrintAction("strike lasthit")
               return true
            end
         end
      end

      if KillMinionsInArea("fire", 2) then
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
   -- spirit fire: Nice if I can hit a few people
   -- other wise one will do if it's my aa target.
   if CanUse("fire") then
      local hits = GetBestArea(me, "fire", 1, 0, ENEMIES)
      if #hits >= 2 then
         CastXYZ("fire", GetCastPoint(hits, "fire"))
         PrintAction("Fire on area", #hits)
         return true
      end

      local target = GetWeakEnemy("PHYS", spells["AA"].range*2)
      if target then
         CastFireahead("fire", target)
         PrintAction("Fire", target)
         return true
      end
   end

   if CanUse("wither") then
      -- hit the adc if I can
      local spell = spells["wither"]
      local target = GetMarkedTarget()
      if not target then
         if EADC and GetDistance(EADC) < spell.range then
            target = EADC
         end
      end
      if not target then
         target = GetWeakestEnemy("wither")
      end
      if target then
         Cast("wither", target)
         PrintAction("Wither", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target, "strike") then
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

local function onObject(object)
   if find(object.charName, "DeathsCaress") then
      if GetDistance(object) < 300 then         
         setStrikes(spells["strike"].bonus + 3)
         if victim then
            if ListContains(victim.name, BigCreepNames, true) or
               ListContains(victim.name, MajorCreepNames, true) or
               find(victim.name, "Mech") or
               string.find(victim.name, "Wraith") == 0 
            then
               setStrikes(spells["strike"].bonus + 3)
            end
            victim = nil
         end
      end 
   end
end

local function onSpell(unit, spell)   
   if ICast("NasusQAttack", unit, spell) then
      victim = spell.target
   end
end

function onKey(msg, key)
   if msg == KEY_UP then
      if key == 107 then         
         setStrikes(spells["strike"].bonus + 3)
      elseif key == 109 then
         setStrikes(spells["strike"].bonus - 3)
      end
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnKey(onKey)
SetTimerCallback("Run")
