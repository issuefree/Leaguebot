require "utils"
require "timCommon"
require "modules"

pp("Tim's Mundo")

spells["cleaver"] = {
   key="Q", 
   range=1000, 
   color=violet, 
   base={80,130,180,230,280},
   type="M",
   width=80,
   delay=2,
   speed=20
}
spells["agony"] = {
   key="W",
   range=325,  
   color=red, 
   base={35,50,65,80,95},
   type="M", 
   ap=.2
}
spells["masochism"] = {
   key="E",
   base={40,55,70,85,100},
   mhp={0.4,0.55,0.7,0.85,1},
   type="P"
}

function getMasochismDamage()
   local spell = spells["masochism"]
   local level = GetSpellLevel(spell.key) 
   if level == 0 then
      return 0
   end
   
   local damage = spell.base[level]
   damage = damage + spell.mhp[level]*((1-me.health/me.maxHealth)*100)
   return damage
end

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("lasthit", {on=true,  key=116, label="Cook / Butcher minions", auxLabel="{0} / {1}", args={"agony", "cleaver"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})


function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   if HotKey() and CanAct() then
      UseItems()
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and not P.burning and CanUse("agony") then
      for _,minion in ipairs(GetInRange(me, "agony", MINIONS)) do
         if WillKill("agony", minion) then
            Cast("agony", me)
            PrintAction("Cook the minions")
            return true
         end
      end
   end

   if IsOn("lasthit") and Alone() and CanUse("cleaver") then
      for _,minion in ipairs(GetUnblocked(me, "cleaver", MINIONS)) do
         if GetDistance(minion) > spells["agony"].range and 
            WillKill("cleaver", minion)
         then
            LineBetween(me, minion, spells["cleaver"].width)
            CastXYZ("cleaver", minion)
            PrintAction("Butcher minion")
            return true
         end
      end
   end

   if HotKey() and CanAct() then
      UseItems()
      if FollowUp() then
         return true
      end
   end
end

function Action()
   local target = SkillShot("cleaver")
   if target then
      CastFireahead("cleaver", target)
      PrintAction("Cleaver", target)
      return true
   end
   
   local target = GetMarkedTarget() or GetWeakEnemy("PHYS", spells["AA"].range*2)
   if target then
      if CanUse("masochism") then
         Cast("masochism", me)
         PrintAction("I hurt me to hurt them")
      end
      
      if not P.burning and CanUse("agony") then
         Cast("agony", me)
         PrintAction("Burn in my agony")
      end

      if AA(target) then
         PrintAction("AA", target)
         return true
      end
   end
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         PrintAction("AA lasthit")
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
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
            MoveToTarget(target)
            return false
         end
      else        
         MoveToCursor() 
         PrintAction("Move")
         return false
      end
   end
end

function checkBurning(object)
   PersistBuff("burning", object, "dr_mundo_burning_agony")
end

AddOnCreate(checkBurning)

SetTimerCallback("Run")