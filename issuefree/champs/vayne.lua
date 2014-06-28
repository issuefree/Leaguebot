require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Vayne")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("kb", {on=true, key=113, label="Auto KB"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["tumble"] = {
   key="Q", 
   range=300, 
   base=0,
   ad={.3,.35,.4,.45,.5},
   color=blue,
   cost=30
} 
spells["bolts"] = {
   key="W",
   base={20,30,40,50,60}, 
   percMaxHealth={.04,.05,.06,.07,.08},
   type="T"
} 
spells["condemn"] = {
   key="E", 
   range=550, 
   color=violet, 
   base={45,80,115,150,185}, 
   bonusAd=.5,
   type="P",
   cost=90,
   knockback=435+25
} 
spells["final"] = {
   key="R", 
   cost=80
} 

spells["AA"].damOnTarget = 
   function(target)
      if HasBuff("rings", target) then
         return GetSpellDamage("bolts", target)
      end
   end

function Tick()
   if P.tumble then
      spells["AA"].bonus = GetSpellDamage("tumble")      
   else
      spells["AA"].bonus = 0
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
      UseItems()
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
            AttackTarget(enemy)
            PrintAction("Condemn for stun", enemy)
            return true
         end
      end

      if CanUse("tumble") then
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
   if CanUse("tumble") and CanUse("condemn") then
      for _,loc in ipairs(GetTumbleLocs()) do
         local kb = GetKnockback("condemn", loc, enemy)
         if WillCollide(enemy, kb) then
            Circle(loc, 25, yellow, 5)
            CastXYZ("tumble", loc)
            PrintAction("Tumble for condemn", enemy)
            return true
         end
      end
   end
   return false
end

function Action()
   -- if CanAttack() then
   --    if HitMinion("AA", "weak") then
   --       return true
   --    end
   --    if GetGolem() then
   --       AttackTarget(GetGolem())
   --       return true
   --    end
   -- end
   -- if CanMove() then
   --    MoveToMouse()
   --    PrintAction("MTM")
   --    return true
   -- end   

   local target = GetMarkedTarget()
   if target then
      if TumbleCondemn(target) then
         return true
      end
      if GetDistance(target) < GetSpellRange("AA") then
         if AA(target) then
            PrintAction("AA marked", target)
            return true
         end         
      elseif CanUse("tumble") and GetDistance(target) < GetSpellRange("AA") + GetSpellRange("tumble") then
         CastXYZ("tumble", target)
         PrintAction("Tumble toward", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   return false
end

-- give me a set of possible tumble location
function GetTumbleLocs()
   return GetCircleLocs(me, GetSpellRange("tumble"))
end

local function onCreate(object)
   PersistOnTargets("ring", object, "vayne_W_ring1", ENEMIES, MINIONS, CREEPS)
   local mark = PersistOnTargets("rings", object, "vayne_W_ring2", ENEMIES)
   if mark then
      MarkTarget(mark)
   end
   PersistOnTargets("rings", object, "vayne_W_ring2", MINIONS, CREEPS)
   PersistBuff("tumble", object, "vayne_Q_buf")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Tick)

