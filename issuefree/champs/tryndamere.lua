require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Tryndamere")

InitAAData({ 
   windup=.25,
   -- extraRange=-15,
   particles = {"tryndamere_weapontrail"},
})

SetChampStyle("bruiser")

AddToggle("heal", {on=true, key=112, label="AutoHeal", auxLabel="{0}", args={"bloodlust"}})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "spin"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["bloodlust"] = {
   key="Q", 
   base={30,40,50,60,70}, 
   ap=function() return .3 + me.mana*1.2 end,
   mana={.5,.95,1.4,1.85,2.3},
   type="H",
} 
spells["shout"] = {
   key="W", 
   range=850-50, -- reticle
   color=yellow, 
} 
spells["spin"] = {
   key="E", 
   range=675, 
   color=violet, 
   base={70,100,130,160,190}, 
   ap=1,
   adBonus=1.2,
   type="P",
   delay=1.5,   -- testskillshot
   speed=10,  -- ?
   width=175, -- reticle
   overShoot=100,
   noblock=true,
} 
spells["rage"] = {
   key="R", 
} 

local lastFury = 0

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   local decaying = false
   if me.mana == lastFury - 5 then
      decaying = true
   end
   lastFury = me.mana

   if IsOn("heal") then
      if CanUse("bloodlust") then
         
         if Alone() and decaying then
            if GetSpellDamage("bloodlust") < (me.maxHealth - me.health) then
               Cast("bloodlust", me)
               PrintAction("Bloodlust for fury decay")
               return true
            end
         end

         if not P.undying then
            if ( me.mana == me.maxMana and GetHPerc(me) < .5 ) or
               ( me.mana > 10 and GetHPerc(me) < .20 )
            then
               Cast("bloodlust", me)
               PrintAction("Bloodlust for survival")
               return true
            end
         end

      end
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if decaying then
      local target = SortByDistance(GetInRange(me, "AA", ENEMIES, MINIONS, PETS))[1]
      if AA(target) then
         PrintAction("AA for decay prevention")
         return true
      end
   end



   if IsOn("lasthit") then
      if VeryAlone() then
         if CanUse("spin") then
            if KillMinionsInLine("spin", 3) then
               return true
            end
         end
      end
   end

   -- wave clear if low on fury?
   
   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   -- TestSkillShot("spin")

   if CanUse("shout") then

      if EADC and IsInRange("shout", EADC) then
         if #GetInRange(EADC, 600, ALLIES) > 0 then
            Cast("shout", me)
            PrintAction("Shout to scare EADC")
            return true
         end
      end

      if not P.spin then
         for _,target in ipairs(SortByDistance(ENEMIES)) do
            if Chasing(target) and not FacingMe(target) then
               if GetDistance(target) > (GetAARange() + 50) and 
                  GetDistance(target) < 650
               then
                  Cast("shout", me)
                  PrintAction("Shout for chase", target)
                  return true
               end
            end
         end
      end

   end

   if CanUse("spin") then
      -- gap close
      local target = GetWeakestEnemy("spin")
      if target and GetDistance(target) > GetAARange() + 50 then
         CastFireahead("spin", target)
         PrintAction("Spin for gap", target)
         return true
      end
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

local function onCreate(object)
   PersistBuff("undying", object, "UndyingRage_buf.troy")
   PersistBuff("spin", object, "Slash.troy")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

