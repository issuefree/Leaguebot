require "issuefree/timCommon"
require "issuefree/modules"

pp("Tim's Mundo")

InitAAData({
   windup = .2,
   extraRange=10,
})

spells["cleaver"] = {
   key="Q", 
   range=1000, -- - 100
   color=violet, 
   base={80,130,180,230,280},
   type="M",
   width=80, -- reticle
   delay=2.3,  -- tss
   speed=20,
   showFireahead=true   
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

AddToggle("", {on=true, key=112, label=""})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true,  key=116, label="Cook / Butcher minions", auxLabel="{0} / {1}", args={"agony", "cleaver"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

function Run()
   if StartTickActions() then
      return true
   end

   if CastAtCC("cleaver") then
      return true
   end

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end

   if IsOn("jungle") and CanUse("cleaver") and JustAttacked() then
      if GetHPerc(me) > .5 then
         local creeps = SortByHealth(GetUnblocked("cleaver", me, CREEPS), "cleaver")
         if #creeps >= 1 then
            local target = creeps[#creeps]
            CastXYZ("cleaver", target)
            PrintAction("Cleaver in the jungle", target)
            return true
         end
      end

      local target = GetUnblocked("cleaver", me, BIGCREEPS, MAJORCREEPS)[1]
      if target then
         CastXYZ("cleaver", target)
         PrintAction("Cleaver in the jungle", target)
         return true
      end
   end

   if IsOn("lasthit") then

      if not P.burning and CanUse("agony") then
         for _,minion in ipairs(GetInRange(me, "agony", MINIONS)) do
            if WillKill("agony", minion) then
               Cast("agony", me)
               PrintAction("Cook the minions")
               return true
            end
         end
      end

      if Alone() and CanUse("cleaver") then
         for _,minion in ipairs(GetUnblocked("cleaver", me, MINIONS)) do
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

   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
   
   EndTickActions()
end

function Action()
   -- TestSkillShot("cleaver")

   if SkillShot("cleaver") then
      return true
   end
   
   local target = GetMarkedTarget() or GetMeleeTarget()
   if target then
      if CanUse("masochism") then
         Cast("masochism", me)
         PrintAction("Rawr", nil, 1)
      end
      
      if not P.burning and CanUse("agony") then
         Cast("agony", me)
         PrintAction("Burn", nil, 1)
      end

      if AutoAA(target) then
         return true
      end
   end
   return false
end

function FollowUp()
   return false
end

function onCreate(object)
   PersistBuff("burning", object, "dr_mundo_burning_agony")
end
local function onSpell(unit, spell)
   if IAttack(unit, spell) and CanUse("masochism") and GetHPerc(me) > .33 then
      Cast("masochism", me)
      PrintAction("Masochism")
   end
end


AddOnCreate(onCreate)
AddOnSpell(onSpell)

SetTimerCallback("Run")