require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Fiddlesticks")
pp(" - dark wind on weakest")
pp(" - pause while draining")

AddToggle("", {on=true, key=112, label=""})
AddToggle("drain", {on=false, key=113, label="Drain"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=false, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["fear"] = {
  key="Q", 
  range=575, 
  color=violet,
  cost={65,75,85,95,105}
}
spells["drain"] = {
  key="W", 
  range=475,
  color=green,
  cost={80,90,100,110,120}
}
spells["wind"] = {
  key="E", 
  range=750, 
  color=red, 
  base={65,85,105,125,145},
  ap=.45,
  cost={50,70,90,110,130}
}
spells["crow"] = {
  key="R", 
  range=800, 
  color=yellow,
  cost={150,200,250},
  radius=600
}

-- block spells while drain is on
-- beep for good crowstorm
-- auto zhonias

local drainObj = nil

function Run()
	TimTick()

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   UseAutoItems()

   if Check(drain) then
      PrintAction("Draining")
      return
   end

	if HotKey() and CanAct() then
		if Action() then
			return
		end
	end

	-- always stuff here

   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end

   PrintAction()
end

function Action()
   UseItems()
   
   if Cast("wind", GetWeakestEnemy("wind")) then
      PrintAction("Wind Harass")
      return true
   end

-- seems better to use manually
   -- if IsOn("drain") and CanUse("drain") and 
   --    GetCD("fear") >= 3 and GetCD("wind") >= 3
   -- then
   --    if Cast("drain", GetWeakestEnemy("drain")) then
   --       PrintAction("Drain weakest")
   --       return true
   --    end
   -- end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         PrintAction("AA lasthit")
         return true
      end
   end

   -- clear with wind if there's 3 or more
   if IsOn("clearminions") and Alone() and
      me.mana/me.maxMana > .5 
   then
      if CanUse("wind") then
         local minions = SortByHealth(GetInRange(me, "wind", MINIONS))
         if #minions > 2 then
            Cast("wind", minions[1])
            PrintAction("Dark wind clearing")
            return true
         end
      end
   end

   return false
end

local function onObject(object)
   if find(object.charName,"Drain.troy") and 
      GetDistance(object) < 75 
   then
      drain = StateObj(object)
   end
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
