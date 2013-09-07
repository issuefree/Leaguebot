require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Olaf")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["axe"] = {
   key="Q", 
   range=1000, 
   color=violet, 
   base={80,125,170,215,260}, 
   adBonus=1, 
   type="P",
   delay=2.65,
   speed=16,
   width=80,
   overShoot=150
}
spells["strikes"] = {
   key="W"
}
spells["swing"] = {
   key="E", 
   range=325, 
   color=yellow, 
   base={100,160,220,280,340}, 
   type="T"
}
spells["ragnarok"] = {
   key="R"   
}

--[[
Jungling
   Axe stuff. Hit everything I can. Keep it close so I can pick it up.
   Swing at stuff as long as I have enough health.
Ganking
   Axe people.
   Attack people.
   If I can hit people pop W.
   Swing at people.
]]--

function Run()
   if IsRecalling(me) or me.dead == 1 then
      return
   end

   if HotKey() and CanAct() then
      Action()
   end

   if IsOn("lasthit") then
      if me.health/me.maxHealth > .75 and KillWeakMinion("swing") then
         PrintAction("Swing for lasthit")
         return true
      end
      if KillMinionsInLine("axe", 2) then
         return true
      end
   end
   
   if IsOn("jungle") then
      local creeps = GetInRange(me, 350, CREEPS)
      for _,creep in ipairs(creeps) do
         if ListContains(creep.name, MajorCreepNames, true) or 
            ListContains(creep.name, BigCreepNames, true) 
         then
            if GetDistance(creep) < 275 and creep.dead ~= 1 then
               if CanUse("axe") then 
                  local a = AngleBetween(me, creep)
                  local d = 60
                  local x = me.x+d*math.sin(a)
                  local z = me.z+d*math.cos(a)
                  CastXYZ("axe", x, 0, z)
                  break
               elseif CanUse("swing") then
                  CastSpellTarget("E", creep)
               end
            end
         end
      end
   end
end

function Action()   
   UseItems()
      
   if SkillShot("axe") then
      return
   end
      
   local aaTarget = GetWeakEnemy("PHYSICAL", spells["swing"].range+100)
   if aaTarget then
      if CanUse("strikes") then
         Cast("strikes", me)
      end

      if CanUse("swing") then
         Cast("swing", aaTarget)
         return true
      end

      if AA(aaTarget) then
         return true
      end
   end

   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         return true
      end
   end
   if IsOn("clearminions") and Alone() then
      if me.mana/me.maxMana > .75 then
         if HitMinionsInLine("axe", 3) then
            return true
         end
      elseif me.mana/me.maxMana > .66 then
         if HitMinionsInLine("axe", 4) then
            return true
         end
      elseif me.mana/me.maxMana > .5 then
         if HitMinionsInLine("axe", 5) then
            return true
         end
      end

      if me.health/me.maxHealth < .75 then
         if CanUse("strikes") and #GetInRange(me, "swing", MINIONS) >= 2 then
            Cast("strikes", me)
         end
      end

      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end

   if IsOn("move") then
      local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
      if target then
         if GetDistance(target) > spells["AA"].range then
            PrintAction("MTT")
            MoveToTarget(target)
            return true
         end
      else        
         MoveToCursor() 
         PrintAction("Move")
         return true
      end
   end
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
