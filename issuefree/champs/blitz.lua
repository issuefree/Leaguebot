require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Blitz")

AddToggle("pull", {on=false, key=112, label="Pull"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "fist"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["grab"] = {
   key="Q", 
   range=1050, 
   color=violet, 
   base={80,135,190,245,300}, 
   ap=1,
   delay=2,
   speed=17,
   width=80,
   cost=100
}
spells["drive"] = {
   key="W", 
   cost=75
}
spells["fist"] = {
   key="E", 
   base=0,
   ad=1,
   modAA="fist",
   object="Powerfist_buf",
   range=GetAARange,
   type="P",
   cost=25
}
spells["field"] = {
   key="R", 
   range=600, 
   color=yellow, 
   base={250,375,500}, 
   ap=1,
   cost=100
}

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") and Alone() then
      if ModAAFarm("fist") then
         return true
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

   if IsOn("pull") and CanUse("pull") then

      if IsGoodFireahead("pull", EADC) and         
         GetDistance(EADC) > 350
      then
         CastFireahead("pull", EADC)
         PrintAction("Pull ADC", EADC)
         return true
      end

      if IsGoodFireahead("pull", EAPC) and         
         GetDistance(EAPC) > 350
      then
         CastFireahead("pull", EAPC)
         PrintAction("Pull APC", EAPC)
         return true
      end

   end


   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target, "fist") then
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
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")

