require "timCommon"
require "modules"

pp("\nTim's Xerath")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "bolt"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

local locusRange = 400

spells["bolt"] = {
   key="Q", 
   range=1050,
   baseRange=1050,
   locusRange=1600,
   color=violet, 
   base={75,115,155,195,235}, 
   ap=.6,
   delay=7,
   speed=999,
   width=80,
   noblock=true,
   cost={65,70,75,80,85}
} 
spells["locus"] = {
   key="W",
   duration=8,
   name="XerathLocusOfPower"
} 
spells["chains"] = {
   key="E", 
   range=650,
   baseRange=650,
   locusRange=925,
   color=yellow, 
   base={70,120,170,220,270}, 
   ap=.8,
   cost={70,75,80,85,90}
} 
spells["barrage"] = {
   key="R",
   range=1050,
   baseRange=1050,
   locusRange=1550,
   color=red,
   base={125,200,275},
   ap=.6,
   delay=5,
   speed=0,
   noblock=true,
   radius=200,
   cost={150,180,210}
} 

local locusStart = 0

function Run()
   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   if IsChannelling() then
      return true
   end

   if me.SpellNameW == "XerathLocusOfPower" then
      spells["bolt"].range = spells["bolt"].baseRange
      spells["chains"].range = spells["chains"].baseRange
      spells["barrage"].range = spells["barrage"].baseRange
   else
      spells["bolt"].range = spells["bolt"].locusRange
      spells["chains"].range = spells["chains"].locusRange
      spells["barrage"].range = spells["barrage"].locusRange

      local cd = 99
      if GetSpellLevel(spells["bolt"].key) > 0 then
         cd = math.min(cd, GetCD("bolt"))
      end
      if GetSpellLevel(spells["chains"].key) > 0 then
         cd = math.min(cd, GetCD("chains"))
      end
      if GetSpellLevel(spells["barrage"].key) > 0 then
         cd = math.min(cd, GetCD("barrage"))
      end

      if 8 - (time() - locusStart) < cd then
         Cast("locus", me)
         PrintAction("Power down")
         return true
      end
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

   if IsOn("lasthit") and CanUse("bolt") then
      if VeryAlone() then
         if KillMinionsInLine("bolt", 2) then
            return true
         end
      elseif Alone() then
         if KillMinionsInLine("bolt", 3) then
            return true
         end
      end
   end

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   PrintAction()
end

function Action()
   if CanUse("chains") and
      ( ( CanUse("bolt") and me.mana > GetSpellCost("chains") + GetSpellCost("bolt") ) or
        ( CanUse("barrage") and me.mana > GetSpellCost("chains") + GetSpellCost("barrage") ) )
   then
      local target = GetMarkedTarget() or GetWeakestEnemy("chains")
      if target then
         Cast("chains", target)
         PrintAction("Chains", target)
         return true
      end
   end

   local target = GetWithBuff("unstable", ENEMIES)[1]
   if target then
      if CanUse("barrage") then
         if IsGoodFireahead("barrage", target) then
            CastFireahead("barrage", target)
            PrintAction("Barrage chained", target)
            return true
         end
      end

      if CanUse("bolt") then
         if IsGoodFireahead("bolt", target) then
            CastFireahead("bolt", target)
            PrintAction("Bolt chained", target)
         end
         -- return always. I want this to happen
         return true
      end
   end

   if CanUse("barrage") then
      if SkillShot("barrage") then
         return true
      end
   end

   if CanUse("bolt") then
      if SkillShot("bolt") then
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
      if HitMinion("AA", "strong") then
         return true
      end
   end

   return false
end

local function onObject(object)
   PersistOnTargets("unstable", object, "xerath_magechains_buf", ENEMIES)
end

local function onSpell(unit, spell)
   if ICast("chains", unit, spell) then
      StartChannel()
   end
   if ICast("locus", unit, spell) and me.SpellNameW == "xerathlocusofpowertoggle" then
      StartChannel()
      locusStart = time()
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")

