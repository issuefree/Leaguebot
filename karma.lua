require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Karma")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["flame"] = {
   key="Q", 
   range=950, 
   color=violet, 
   base={80,125,170,215,260}, 
   ap=.6,
   delay=1.6,
   speed=17,
   width=100,
   cost={50,55,60,65,70},
   radius=250
}
spells["soulflare"] = {
   key="R",
   base={25+50,75+150,125+250,175+350},
   ap=.9
}
spells["tether"] = {
   key="W", 
   range=650, 
   color=yellow, 
   base={60,110,160,210,260}, 
   ap=.6,
   cost={70,75,80,85,90}
}
spells["shield"] = {
   key="E", 
   range=800, 
   color=blue, 
   base={80,120,160,200,240}, 
   ap=.5,
   cost={60,70,80,90,100},
   shieldRadius=700,
   damageRadius=600
}
spells["mantra"] = {
   key="R"
} 

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

	if IsOn("lasthit") and Alone() then
      if CanUse("flame") then
         local unblocked = GetUnblocked(me, "flame", MINIONS)
         local bestK = 1
         local bestT
         for _,target in ipairs(unblocked) do
            local kills = #GetKills("flame", GetInRange(target, 150, MINIONS))
            if kills > bestK then
               bestT = target
               bestK = kills
            end
         end
         if bestT then
            CastXYZ("flame", bestT)
            PrintAction("flame for lasthit")
            return true
         end
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
end

function Action()
   if CanUse("tether") then
      local target = SortByDistance(GetInRange(me, "tether", ENEMIES))[1]
      if target then
         if GetHPerc(me) < .5 and CanUse("mantra") then
            Cast("mantra", me)
            PrintAction("Mantra for heal")
         end
         Cast("tether", target)
         PrintAction("Tether", target)
         return true
      end
   end

   if CanUse("flame") then
      if CanUse("mantra") then -- look for executes, then for clumps
         local unblocked = GetUnblocked(me, "flame", MINIONS, ENEMIES)
         unblocked = FilterList(unblocked, function(item) return not IsMinion(item) end)
         unblocked = SortByDistance(FilterList(unblocked, function(item) return IsGoodFireahead("flame", item) end))
         for _,target in ipairs(unblocked) do -- aim for the closest guy I can kill
            if GetSpellDamage("flame", target) < target.health and
               GetSpellDamage("flame", target) + GetSpellDamage("soulflare", target) > target.health then
               Cast("mantra", me)
               CastFireahead("flame", target)
               PrintAction("Soulflare for execute", target)
               return true
            end
         end
         local bestT
         local bestH = 1
         for _,target in ipairs(unblocked) do
            local hits = #GetInRange(target, spells["flame"].radius, ENEMIES)
            if hits > bestH then
               bestT = target
               bestH = hits
            end
         end
         if bestT then
            Cast("mantra", me)
            CastFireahead("flame", bestT)
            PrintAction("Soulflare for aoe", bestT)
            return true
         end
      end

      local target = GetSkillShot("flame")
      if target then
         if CanUse("mantra") and ApproachAngleRel(me, target) < 30 then
            Cast("mantra", me)
            PrintAction("Mantra for good flame")
         end

         CastFireahead("flame", target)
         PrintAction("Flame", target)
         return true
      end
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
      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end

   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
   local target = CheckShield("shield", unit, spell, "CHECK")
   if target then
      if CanUse("mantra") and
         #GetInRange(target, spells["shield"].shieldRadius, ALLIES) >= 2 and
         #GetInRange(target, spells["shield"].damageRadius, ENEMIES) >= 2
      then
         Cast("mantra", me)
         PrintAction("Mantra for shield")
      end
      Cast("shield", target)
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
