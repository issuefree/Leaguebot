require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Tristana")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("jump", {on=false, key=113, label="Jumps"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

function getShotRange()
   return 675+(9*(me.selflevel-1))
end

spells["rapid"] = {
   key="Q", 
   cost=50
} 
spells["jump"] = {
   key="W", 
   range=900, 
   color=blue, 
   base={70,115,160,205,250}, 
   ap=.8,
   delay=2,
   speed=12, --?
   radius=300, --?
   cost=80
} 
spells["shot"] = {
   key="E", 
   range=getShotRange,
   color=violet, 
   base={110,150,190,230,270}, 
   ap=1,
   radius=150,
   cost={50,60,70,80,90}
} 
spells["buster"] = {
   key="R", 
   range=700, 
   color=red, 
   base={300,400,500}, 
   ap=1.5,
   cost=100
} 

local jumpPoint = nil

function Run()
   if StartTickActions() then
      return true
   end

   if jumpPoint then
      Circle(jumpPoint, 50, red, 4)
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
      UseItems()
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if IsOn("jump") and 
      CanUse("jump") and CanUse("buster") and
      me.mana > (GetSpellCost("jump") + GetSpellCost("buster"))
   then
      local target = GetWeakestEnemy("jump", -100)
      if target then
         local point = Projection(me, target, GetDistance(target)+100)
         if not UnderTower(point) and 
            #GetInRange(point, 650, ENEMIES) == 1 and
            GetDistance(HOME) < GetDistance(point, HOME)
         then
            CastXYZ("jump", point)
            jumpPoint = Point(me)
            DoIn(function() jumpPoint = nil end, 3)
            PrintAction("JUMP")
            return true
         end
      end
   end

   if CanUse("buster") and jumpPoint then
      for _,target in ipairs(SortByDistance(GetInRange(me, "buster", ENEMIES))) do
         if GetDistance(HOME) > GetDistance(target, HOME) then
            Cast("buster", target)
            PrintAction("KB", target)
            return true
         end
      end
   end


   if CanUse("shot") then
      local target = GetWeakestEnemy("shot")
      if target then
         Cast("shot", target)
         PrintAction("Explosive Shot", target)
         return true
      end
   end

   if CanUse("rapid") then
      local target = GetWeakestEnemy("AA", -50)
      if target then
         Cast("rapid", me)
         PrintAction("Rapid Fire", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AA(target) then
      PrintAction("AA", target)
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

   if IsOn("clearminions") and Alone() then
      if HitMinion("AA", "strong") then
         return true
      end
   end

   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
   if ICast("shot", unit, spell) then
      pp(spell.name)
      pp("range "..getShotRange())
      pp("actual "..GetDistance(GetLizard()))
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")

