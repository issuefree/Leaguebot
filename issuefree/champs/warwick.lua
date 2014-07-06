require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Warwick")
pp(" - Howl if near enemies")
pp(" - Strike enemies")
pp(" - AA enemies")

local thirstDam = {3,3.5,4,4.5,5,5.5,6,6.5,7,8,9,10,11,12,13,14,15,16}

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["strike"] = {
   key="Q", 
   range=400, 
   color=violet, 
   base={75,125,175,225,275}, 
   ap=1,
   cost={60,70,80,90,100}
}
spells["howl"] = {
   key="W", 
   cost=35
}
spells["duress"] = {
   key="R", 
   range=700, 
   color=red,
   cost={100,125,150}
}

--[[ 
should be easy. Try to AA people. Howl if I can. Q them.
Q minions if I have lots of mana or am low on health.
]]

function Run()
   spells["AA"].bonus = thirstDam[me.selflevel]

   if StartTickActions() then
      return true
   end

	if HotKey() and CanAct() then
		if Action() then
			return
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if CanUse("strike") and Alone() then
      local minions = SortByHealth(GetInRange(me, "strike", MINIONS), "strike")
      
      if #minions > 0 then
         if GetMPerc(me) > .75 then
            for _,minion in ipairs(minions) do
               if GetDistance(minion) > spells["AA"].range and
                  WillKill("strike", minion)
               then
                  Cast("strike", minion)
                  PrintAction("Strike for lasthit")
                  return true
               end
            end
         end

         if GetHPerc(me) < .75 and GetHPerc(me) < GetMPerc(me) then
            Cast("strike", minions[1])
            PrintAction("Strike for health")
            return true
         end
      end
   end

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end

   EndTickActions()
end

function Action()
   if CanUse("howl") and GetWeakestEnemy("AA",100) then
      Cast("howl", me) -- non blocking
      PrintAction("Howl")
   end

   if CastBest("strike") then
      return true
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   return false
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
