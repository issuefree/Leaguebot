require "Utils"
require "timCommon"
require "modules"

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

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {2}      {1}", args={GetAADamage, strikeBonus, "strike"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["strike"] = {
   key="Q", 
   base={30,50,70,90,110}, 
   ad=1,
   bonus=0,
   type="P",
   cost=20
}
spells["wither"] = {
   key="W", 
   range=700,
   color=yellow,
   cost=80
}
spells["fire"] = {
   key="E", 
   range=650,
   color=violet,
   base={55,95,135,175,215},
   ap=.6,
   cost={70,85,100,115,130},
   radius=400,
   delay=3,
   speed=99
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

local victim, victimName

function Run()
   TimTick()

   if IsRecalling(me) or me.dead == 1 then
      return
   end
   
   if HotKey() and CanAct() then
      if Action() then
         return
      end
   end
      
   
   if IsOn("lasthit") and Alone() then
      if CanUse("strike") then
         local targets = SortByDistance(GetInRange(me, spells["AA"].range+100, CREEPS, MINIONS))
         for _,target in ipairs(targets) do 
            if GetSpellDamage("strike", target) > target.health then
               Cast("strike", target)
               if ListContains(target, CREEPS) then
                  ClickSpellXYZ("M", target.x, target.y, target.z, 0)
               else 
                  AttackTarget(target) -- not using AA as I want to interupt auto attacks
               end
               victim = target
               victimName = target.name
               return true
            end
         end
      end
   end
   

   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end
end

function Action()
   UseItems()

   -- spirit fire: Nice if I can hit a few people
   -- other wise one will do if it's my aa target.
   if CanUse("fire") then
      local targets = GetInRange(me, "fire", ENEMIES)
      local bestTargets = {}
      for _,target in ipairs(targets) do
         local hits = GetInRange(target, spells["fire"].radius, ENEMIES)
         if #hits > #bestTargets then
            bestTargets = hits
         end
      end
      if #bestTargets > 2 then
         local x,y,z = GetCenter(bestTargets)
         CastXYZ("fire", x,y,z)
         return true
      end

      local aaTarget = GetWeakEnemy("PHYS", spells["AA"].range*2)
      if aaTarget then
         DrawThickCircleObject(aaTarget, 100, red, 6)
      end
      if aaTarget then
         CastXYZ("fire", aaTarget)
         return true
      end

   end

   -- Whack shit
   -- If I'm whackin shit, use strike
   local aaTarget = GetWeakEnemy("PHYS", spells["AA"].range*2)
   if aaTarget and CanUse("strike") then
      Cast("strike", me)
   end
   if aaTarget and AA(aaTarget) then
      return true
   end



   if CanUse("wither") then
      -- hit the adc if I can
      local spell = spells["wither"]
      if EADC and GetDistance(EADC) < spell.range then
         Cast("wither", EADC)
         return true
      end
      local target = GetWeakestEnemy("wither")
      if target then
         Cast("wither", target)
         return true
      end
   end

   return false
end

function FollowUp()
   local aaTarget = GetWeakEnemy("PHYS", spells["AA"].range*2)

   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      local minion = minions[#minions]
      if minion and AA(minion) then
         return true
      end
   end

   if IsOn("move") then
      if aaTarget then
         MoveToTarget(aaTarget)
         return true
      else
         MoveToCursor() 
         return true
      end
   end

   return false
end

local function onObject(object)
   if find(object.charName, "DeathsCaress") then
      if GetDistance(object) < 300 then
         setStrikes(spells["strike"].bonus + 3)
         if ListContains(victim.name, BigCreepNames, true) then
            setStrikes(spells["strike"].bonus + 3)
         elseif ListContains(victim.name, MajorCreepNames, true) then
            setStrikes(spells["strike"].bonus + 3)
         elseif find(victim.name, "Mech") then
            setStrikes(spells["strike"].bonus + 3)
         end
      end 
   end
end

local function onSpell(object, spell)
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
