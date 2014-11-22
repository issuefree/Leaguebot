require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Vayne")

-- TODO condemn away dives / pulls
--    condemn away leona when she lands her sword
--    condemn away alister when he headbutts
--    condemn away blitz when he pulls
--    condemn away darius when he pulls

InitAAData({
   speed = 2000, windup=.2,
   -- extraRange=-10,
   resets={me.SpellNameQ},
   particles = {"vayne_basicAttack_mis.troy", "vayne_critAttack_mis.troy", "vayne_ult_mis.troy"}
})
AddToggle("kb", {on=true, key=112, label="Auto KB"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move to Mouse"})

spells["tumble"] = {
   key="Q", 
   range=300, 
   color=blue,
   base=0,
   ad={.3,.35,.4,.45,.5},
   type="P",
} 
spells["bolts"] = {
   key="W",
   base={20,30,40,50,60}, 
   targetMaxHealth={.04,.05,.06,.07,.08},
   type="T"
} 
spells["condemn"] = {
   key="E", 
   range=550,
   rangeType="e2e",
   color=violet, 
   base={45,80,115,150,185}, 
   adBonus=.5,
   type="P",
   cost=90,
   knockback=470-25
} 
spells["final"] = {
   key="R", 
   cost=80
} 

spells["AA"].damOnTarget = 
   function(target)
      if HasBuff("rings", target) then
         return GetSpellDamage("bolts", target, true)
      end
      return 0
   end

function Tick()
   spells["AA"].bonus = 0
   if P.tumble then
      spells["AA"].bonus = GetSpellDamage("tumble")      
   end
   
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("condemn") then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("kb") and CanUse("condemn") then
      local enemies = SortByHealth(GetInRange(me, "condemn", ENEMIES), "condemn")
      for _,enemy in ipairs(enemies) do
         local kb = GetKnockback("condemn", me, enemy)
         if WillCollide(enemy, kb) then
            Cast("condemn", enemy)
            -- AttackTarget(enemy)
            PrintAction("Condemn for stun", enemy)
            return true
         end
      end

      if CanUse("tumble") and not P.tumble then
         for _,loc in ipairs(GetTumbleLocs()) do
            enemies = SortByHealth(GetInRange(loc, "condemn", ENEMIES), "condemn")
            for _,enemy in ipairs(enemies) do
               local kb = GetKnockback("condemn", loc, enemy)
               if WillCollide(enemy, kb) then
                  Circle(loc, 25, yellow, 5)
               end
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

   EndTickActions()
end

function TumbleCondemn(enemy)
   if CanUse("tumble") and CanUse("condemn") and not P.tumble then
      local bestLoc
      local bestDist
      for _,loc in ipairs(GetTumbleLocs()) do
         if GetDistance(loc, enemy) < GetSpellRange("condemn") then
            local kb = GetKnockback("condemn", loc, enemy)
            local cp =  WillCollide(enemy, kb)
            if cp then
               local dist = GetDistance(loc, cp)
               if not bestLoc or dist < bestDist then
                  bestLoc = loc
                  bestDist = dist
               end
            end
         end
      end
      if bestLoc then
         Circle(bestLoc, 25, yellow, 5)
         CastXYZ("tumble", bestLoc)
         PrintAction("Tumble for condemn", enemy)
         return true
      end
   end
   return false
end

function Action()

   for _,target in ipairs(GetInRange(me, GetSpellRange("condemn"), ENEMIES)) do
      if TumbleCondemn(target) then
         return true
      end
   end

   if CanUse("tumble") and not P.tumble then
      local target = GetWithBuff("rings", ENEMIES)[1]
      if target then
         if not IsInRange("AA", target) then
            CastXYZ("tumble", target)
            PrintAction("Tumble for close (rings)", target)
            return true
         end
      end

      local target = SortByDistance(GetKills("AA", GetInE2ERange(me, GetSpellRange("tumble")+GetAARange(), ENEMIES)))[1]
      if target then
         if not IsInRange("AA", target) then
            CastXYZ("tumble", target)
            PrintAction("Tumble for close (exe)", target)
            return true
         end
      end
   end


   local target = GetMarkedTarget() or 
                  GetWithBuff("rings", ENEMIES)[1] or 
                  GetWithBuff("ring", ENEMIES)[1] or 
                  GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clear") and Alone() then
      local minion = GetWithBuff("rings", MINIONS)[1] or
                     GetWithBuff("ring", MINIONS)[1]
      if AA(minion) then
         PrintAction("AA ringed for clear")
         return true
      end

   end
   return false
end

-- give me a set of possible tumble location
function GetTumbleLocs()
   return GetCircleLocs(me, GetSpellRange("tumble"))
end

local function onCreate(object)
   PersistOnTargets("ring", object, "vayne_W_ring1", ENEMIES, MINIONS, CREEPS)
   PersistOnTargets("rings", object, "vayne_W_ring2", ENEMIES)
   PersistOnTargets("rings", object, "vayne_W_ring2", MINIONS, CREEPS)
   PersistBuff("tumble", object, "vayne_Q_buf")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Tick)

