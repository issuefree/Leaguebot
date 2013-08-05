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
   width=100
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
   TimTick()
   
   if IsRecalling(me) or me.dead == 1 then
      return
   end

   if HotKey() and CanAct() then
      Action()
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
         return return true
      end
   end

   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         return true
      end
      if me.health/me.maxHealth > .75 and KillWeakMinion("swing") then
         return true
      end
   end
   if IsOn("clearminions") and Alone() then
      if me.mana/me.maxMana > .75 then
         if KillMinionsInLine("axe", 3, false, 0, false) then
            return true
         end
      elseif me.mana/me.maxMana > .66 then
         if KillMinionsInLine("axe", 4, false, 0, false) then
            return true
         end
      elseif me.mana/me.maxMana > .5 then
         if KillMinionsInLine("axe", 5, false, 0, false) then
            return true
         end
      end

      if me.health/me.maxHealth > .66 then
         if CanUse("swing") then
            local minions = SortByHealth(GetInRange(me, "swing", MINIONS))
            local minion = minions[#minions]
            if minion and Cast("swing", minion) then
               return true
            end
         end
      end
      if me.health/me.maxHealth < .75 then
         if CanUse("strikes") and #GetInRange(me, "swing", MINIONS) >= 2 then
            Cast("strikes", me)
         end
      end

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
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
