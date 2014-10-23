require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Kennen")

InitAAData({ 
   projSpeed = 1.35, windup=.25,
   attacks={"KennenBasicAttack", "KennenMegaProc"},
   particles = {"KennenBasicAttack_mis"} 
})

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "shuriken"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

-- TODO track marks

spells["shuriken"] = {
   key="Q", 
   range=1050, 
   color=violet, 
   base={75,115,155,195,235}, 
   ap=.75,
   delay=1.8,  --tss
   speed=17,   --tss
   width=55+20,   --reticle
} 
spells["surge"] = {
   key="W", 
   range=800+75, -- reticle
   color=yellow, 
   base={65,95,125,155,185}, 
   ap=.55,
} 
spells["surgePassive"] = {
   base=0,
   ad={.4,.5,.6,.7,.8},
   type="M"
}
spells["rush"] = {
   key="E", 
   base={85,125,165,205,245}, 
   ap=.6,
} 
spells["maelstrom"] = {
   key="R", 
   range=550, 
   color=red, 
   base={80,145,210}, 
   ap=.4,
} 

spells["AA"].bonus = 
   function()
      if P.surge then
         return GetSpellDamage("surgePassive")
      end
      return 0
   end


function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CastAtCC("shuriken") then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end

   -- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if Alone() then
         if KillMinion("shuriken", "burn") then
            return true
         end

         if CanUse("surge") then
            local kills = GetKills("surge", GetInRange(me, "surge", GetWithBuff("mos", MINIONS)))
            if #kills >= 2 then
               Cast("surge", me)
               PrintAction("Surge for LH", #kills)
               return true
            end
         end
      end
   end

   
   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   if P.rush then
      if IsOn("move") then
         AutoMove()
      end
      return true
   end
   EndTickActions()
end

function Action()
   if SkillShot("shuriken") then
      return true
   end

   if CanUse("surge") then
      local targets = GetInRange(me, "surge", GetWithBuff("mos2", ENEMIES))
      local kills = GetKills("surge", targets)
      if #kills >= 1 then
         Cast("surge", me)
         PrintAction("Surge for execute", kills[1])
         return true
      end
      if #targets >= 1 then
         Cast("surge", me)
         PrintAction("Surge for stun")
         return true
      end      
      if #targets >= 1 then
         local nearby = GetInRange(me, "surge", ENEMIES)
         if #targets == #nearby and GetMPerc(me) > .33 then
            Cast("surge", me)
            PrintAction("Surge because everyone has a mark")
            return true
         end
      end
   end

   if not P.rush then
      local target = GetMarkedTarget() or GetWeakestEnemy("AA")
      if AutoAA(target) then
         return true
      end
   end

   return false
end
function FollowUp()
   return false
end

-- function AutoJungle()
--    local creep = GetBiggestCreep(GetInRange(me, "AA", CREEPS))
--    local score = ScoreCreeps(creep)
--    if AA(creep) then
--       PrintAction("AA "..creep.charName)
--       return true
--    end
-- end   
-- SetAutoJungle(AutoJungle)

local function onCreate(object)
   PersistBuff("surge", object, "kennen_ds_proc")
   PersistOnTargets("mos", object, "kennen_mos", MINIONS, PETS, CREEPS, ENEMIES)
   PersistOnTargets("mos2", object, "kennen_mos2", ENEMIES)
   PersistBuff("rush", object, "kennen_lr_buf")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

