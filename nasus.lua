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

AddToggle("autoStrike", {on=true, key=112, label="Auto Strike", auxLabel="{0} / {1}", args={strikeBonus, "strike"}})

spells["strike"] = {
   key="Q", 
   base={30,50,70,90,110}, 
   ad=1,
   bonus=0,
   type="P"
}
spells["wither"] = {
   key="W", 
   range=700,
   color=yellow
}
spells["fire"] = {
   key="E", 
   range=650,
   color=violet,
   base={55,95,135,175,215},
   area=800,
   ap=.6
}
spells["fury"] = {
   key="R", 
   range=350,
   color=red
}

config = LoadConfig("nasus")
spells["strike"].bonus = config["strikes"]

-- didn't work
if GetSpellLevel("Q") == 0 then
   setStrikes(0)
end

local victim, victimName

function Run()
   TimTick()
   
   if HotKey() then
      UseItems()
      
      local target = GetWeakEnemy("PHYS", spells["AA"].range+100)
      if target and CanUse("strike") then
         CastSpellTarget("Q", me)
      end
         
   end
   
   if IsOn("autoStrike") and not GetWeakEnemy("PHYS", 750) then
      if CanUse("strike") then
         local targets = GetInRange(me, spells["AA"].range+100, CREEPS, MINIONS)
         for _,target in ipairs(targets) do 
            if GetSpellDamage("strike", target) > target.health then
               CastSpellTarget("Q", target)
               if ListContains(target, CREEPS) then
                  ClickSpellXYZ("M", target.x, target.y, target.z, 0)
               else 
                  AttackTarget(target)
               end
               victim = target
               victimName = target.name
               break
            end
         end
      end
   end
   
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

function OnWndMsg(msg, key)
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
SetTimerCallback("Run")
