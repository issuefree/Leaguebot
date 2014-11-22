require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Template")

-- InitAAData({ 
--    speed = 1300, windup=.25,
--    minMoveTime = 0,
--    extraRange=-20,
--    particles = {"TeemoBasicAttack_mis", "Toxicshot_mis"} 
-- })

-- SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

--spells["binding"] = {
--    key="Q", 
--    range=1175, 
--    color=violet, 
--    base={60,110,160,210,260}, 
--    ap=.7,
--    delay=2,
--    speed=12,
--    width=80,
--    cost={10,20,30,40,50}
--} 
--spells["binding"] = {
--    key="W", 
--    range=1175, 
--    color=violet, 
--    base={60,110,160,210,260}, 
--    ap=.7,
--    delay=2,
--    speed=12,
--    width=80,
--    cost={10,20,30,40,50}
--} 
--spells["binding"] = {
--    key="E", 
--    range=1175, 
--    color=violet, 
--    base={60,110,160,210,260}, 
--    ap=.7,
--    delay=2,
--    speed=12,
--    width=80,
--    cost={10,20,30,40,50}
--} 
--spells["binding"] = {
--    key="R", 
--    range=1175, 
--    color=violet, 
--    base={60,110,160,210,260}, 
--    ap=.7,
--    delay=2,
--    speed=12,
--    width=80,
--    cost={10,20,30,40,50}
--} 

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("binding") then
      return true
   end

   if CastAtCC("pillar") then
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
      end
   end
   
   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   -- local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
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
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

