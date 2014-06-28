require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Zilean")

AddToggle("", {on=true, key=112, label=""})
AddToggle("autoChrono", {on=true, key=113, label="Auto Chrono Shift"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "bomb"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["bomb"] = {
  key="Q", 
  range=695, 
  color=violet, 
  base={90,145,200,260,320}, 
  ap=.9,
  cost={70,85,100,115,130},
  radius=325
}
spells["rewind"] = {
  key="W", 
  cost=50
}
spells["warp"] = {
  key="E", 
  range=700, 
  color=yellow, 
  cost=80
}
spells["chrono"] = {
  key="R", 
  range=780, 
  color=green, 
  cost={125,150,175}
}

function Run()
   if StartTickActions() then
      return true
   end

   if IsOn("autoChrono") and CanUse("chrono") then
      local targets = GetInRange(me, "chrono", ALLIES)
      local bestT
      local bestP
      for _,target in ipairs(targets) do
         local tp = GetHPerc(target)
         if tp < .2 and #GetInRange(target, 500, ENEMIES) > 0 then
            if not bestT or tp < bestP then
               bestT = target
               bestP = tp
            end
         end
      end
      if bestT then
         Cast("chrono", bestT)
         PrintAction("Save", bestT)
         return true
      end
   end

	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

   if IsOn("lasthit") and Alone() then
      if CanUse("bomb") then
         local targets = GetInRange(me, "bomb", MINIONS)
         local bestT
         local bestK = 2
         for _,target in ipairs(targets) do
            local kills = #GetKills("bomb", GetInRange(target, spells["bomb"].radius, MINIONS))
            if kills > bestK then
               bestT = target
               bestK = kills
            end
         end
         if bestT then
            Cast("bomb", bestT)
            PrintAction("Bomb for lasthit")
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
   if GetWeakestEnemy("bomb") then
      if GetCD("bomb") > 4 and CanUse("rewind") then
         Cast("rewind", me)
         PrintAction("Rewind")
      end
   end

   if CanUse("bomb") then
      UseItem("Deathfire Grasp", GetWeakestEnemy("bomb"))
   end
   if CastBest("bomb") then
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
