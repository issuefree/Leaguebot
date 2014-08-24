require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Irelia")

AddToggle("", {on=true, key=112, label="- - -"})
AddToggle("ult", {on=true, key=113, label="Auto Ult"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "surge"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["surge"] = {
   key="Q", 
   range=650, 
   color=violet, 
   base={20,50,80,110,140}, 
   ad=1,
   onHit=true,
   cost={60,65,70,75,80},
   type="P"
}
spells["hiten"] = {
   key="W", 
   base={15,30,45,60,75}, 
   cost=40,
   type="T"
}
spells["strike"] = {
   key="E", 
   range=425, 
   color=red, 
   base={80,130,180,230,280}, 
   ap=.5,
   cost={50,55,60,65,70}
}
spells["blades"] = {
   key="R", 
   range=1000, 
   color=yellow, 
   base={80,120,160}, 
   ap=.5,
   adBonus=.6,
   delay=1.6,
   speed=20,
   noblock=true,
   width=100,
   cost=100
}

function Run()
   if P.hiten then
      spells["AA"].bonus = GetSpellDamage("hiten")
   else
      spells["AA"].bonus = 0
   end

   if StartTickActions() then
      return true
   end


   for _,minion in ipairs(GetInRange(me, GetSpellRange("surge")+100, MINIONS)) do
      if WillKill("surge", minion) then
         if GetDistance(minion) < GetSpellRange("surge") then
            Circle(minion, nil, blue, 3)
         else
            Circle(minion, nil, blue)
         end
      end
   end

   if IsOn("ult") then
      if P.blades then
         local target = GetMarkedTarget()
         if target then
            CastFireahead("blades", target)
            PrintAction("Blades because", target)
            return true
         end

         local hits = GetBestLine(me, "blades", 1, 5, ENEMIES)
         if #hits > 0 then
            CastXYZ("blades", GetAngularCenter(hits))
            PrintAction("Blade spam", #hits)
            return true
         end
      end
   end

	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") and Alone() then
      if GetThreshMP("surge") <= 1 then
         local target = KillMinion("surge", nil, nil, true)
         if target and #GetInRange(target, 500, ENEMIES) <= 1 then
            Cast("surge", target)
            PrintAction("Surge for LH")
            StartChannel(.25)
            return true
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
-- if someone is in melee range hiten up
-- if I can stun someone, do it
-- If I need to dash to reach my target, do so.
-- What people

   if IsOn("ult") then
      if CanUse("blades") then
         local target = GetMarkedTarget() or GetWeakestEnemy("blades")
         if target and 
            GetDistance(target) > GetSpellRange("AA") and 
            IsGoodFireahead("blades", target) and 
            GetSpellDamage("blades", target)*4 > target.health
         then
            Persist("markedTarget", target)
            CastFireahead("blades", target)
            PrintAction("Blades for kill", target)
            return true
         end
         local hits = GetBestLine(me, "blades", 1, 5, ENEMIES)
         if #hits >= 3 then
            CastXYZ("blades", GetAngularCenter(hits))
            PrintAction("Blades for AOE", #hits)
            return true
         end
      end
   end

   if CanUse("hiten") then
      if GetWeakestEnemy("AA") then
         Cast("hiten", me)
         PrintAction("Hiten Style")
         return true
      end
   end

   if CanUse("strike") then
      local target = GetMarkedTarget() or GetWeakestEnemy("strike")
      if target then
         if GetHPerc(target) > GetHPerc(me) then
            Cast("strike", target)
            PrintAction("Strike for stun", target)
            return true
         end

         if GetDistance(Point(GetFireahead(target, 5, 0))) > GetSpellRange("strike") then
            Cast("strike", target)
            PrintAction("Strike to stop escape", target)
            return true
         end
      end
   end

   if CanUse("surge") then
      local target = GetMarkedTarget() or GetWeakestEnemy("surge")
      if target and GetDistance(target) > GetSpellRange("AA")+50 then
         Cast("surge", target)
         PrintAction("Surge to", target)
         return true
      end

      local target = GetMarkedTarget()
      if target and GetDistance(target) > GetSpellRange("surge") then
         local minions = GetKills("surge", GetInRange(me, "surge", MINIONS))
         local link = SortByDistance(GetInRange(target, "surge", minions), target)[1]
         if link then
            Cast("surge", link)
            PrintAction("Surge for link", target)
            return true
         end
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()   
   if IsOn("move") then
      if MeleeMove() then
         return true
      end
   end

   return false
end

local function onObject(object)
   PersistBuff("blades", object, "Irelia_ult_dagger_active")
   PersistBuff("hiten", object, "irelia_hitenStlye_active_glow", 200)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
