require "issuefree/timCommon"
require "issuefree/modules"

-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Lee Sin")

InitAAData({ 
   windup=.25
})


local altSpells = {}
altSpells["BlindMonkQOne"] = {
   key="Q", 
   range=1100,
   color=violet, 
   base={50,80,110,140,170}, 
   adBonus=.9,
   type="P",
   delay=2.5, -- tested
   speed=17.5, 
   width=65, -- reticule
   cost=50,
   showFireahead=true
}
altSpells["blindmonkqtwo"] = {
   key="Q", 
   range=1300,
   color=violet, 
   base={50,80,110,140,170}, 
   adBonus=.9,
   targetMissingHealth=.08,
   type="P",
   cost=30
}
spells["sonic"] = spells["BlindMonkQOne"]

altSpells["BlindMonkWOne"] = {
   key="W", 
   range=700, 
   color=blue, 
   base={40,80,120,160,200}, 
   ap=.8,
   type="H",
   cost=50
} 
altSpells["blindmonkwtwo"] = {
   key="W",
   cost=30
} 
spells["safeguard"] = spells["BlindMonkWOne"]

altSpells["BlindMonkEOne"] = {
   key="E", 
   range=400, 
   color=yellow, 
   base={60,95,130,165,200}, 
   adBonus=1,
   cost=50
} 
altSpells["blindmonketwo"] = {
   key="E", 
   range=500, 
   color=yellow, 
   cost=30
} 
spells["tempest"] = spells["BlindMonkEOne"]

spells["kick"] = {
   key="R", 
   range=375, 
   color=red, 
   base={200,400,600}, 
   adBonus=2,
   type="P",
   knockback=1200
} 

harrass = Combo("harrass", 2, function() Toggle("harrass", false) end)
harrass:addState("strike",
   function(combo)
      if CanUse("strike") then
         Cast("strike", me)
         PrintAction(combo, combo.target)
      else
         combo.state = "attack"
      end
   end
)
harrass:addState("attack",
   function(combo)
      AutoAA(watched)
      if JustAttacked() then
         combo.state = "return"
      end
   end
)
harrass:addState("return",
   function(combo)
      if CanUse("safeguard") then
         Cast("safeguard", combo:get("bounceTarget"))
         PrintAction(combo)
      else
         combo:reset()
      end
   end
)


function getBounceLabel()
   return ( GetSpellDamage(altSpells["BlindMonkQOne"]) +
            GetSpellDamage(altSpells["blindmonkqtwo"]) )
end

AddToggle("dive", {on=false, key=112, label="Dive"})
AddToggle("harrass", {on=false, key=113, label="Bounce Harrass", auxLabel="{0}", args={getBounceLabel}})
AddToggle("jungle", {on=true, key=114, label="Jungle"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move to Mouse"})



-- Harrass combo
  -- if Q lands follow up with strike and safeguard out.
-- Tempest for last hits?
-- strike for execute
-- kick for execute
-- strike -> kick for execute
-- strike -> tempest -> kick for execute

local bounceTarget
local watched
local watchedTime = 0

function Run()
   -- DrawReticule("sonic")
   if me.SpellNameQ == "BlindMonkQOne" then      
      spells["sonic"] = altSpells[me.SpellNameQ]
      spells["strike"] = nil
   else
      spells["sonic"] = nil
      spells["strike"] = altSpells[me.SpellNameQ]
   end
   if me.SpellNameW == "BlindMonkWOne" then      
      spells["safeguard"] = altSpells[me.SpellNameW]
      spells["will"] = nil
   else
      spells["safeguard"] = nil
      spells["will"] = altSpells[me.SpellNameW]
   end
   if me.SpellNameE == "BlindMonkEOne" then
      spells["tempest"] = altSpells[me.SpellNameE]
      spells["cripple"] = nil
   else
      spells["tempest"] = nil
      spells["cripple"] = altSpells[me.SpellNameE]
   end

   watched = GetWithBuff("watched", ENEMIES)[1]

   if watched then
      PrintState(0, watched.charName)
   end

   if StartTickActions() then
      return true
   end

   if IsKeyDown(string.byte("X")) == 1 then
      if CanUse("safeguard") then
         WardJump("safeguard")
         return true
      end
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if CanUse("tempest") then
         local kills = GetKills("tempest", GetInRange(me, "tempest", MINIONS))
         if #kills >= 2 then
            Cast("tempest", me)
            PrintAction("Tempest for AoE LH")
            return true
         end
         if JustAttacked() and #kills >= 1 then
            Cast("tempest", me)
            PrintAction("Tempest for LH")
            return true
         end
      end

      if VeryAlone() then
         if CanUse("sonic") then
            for _,minion in ipairs(GetUnblocked("sonic", me, MINIONS)) do
               if GetDistance(minion) > GetSpellRange("AA") + 50 and 
                  WillKill("sonic", minion)
               then
                  LineBetween(me, minion, spells["sonic"].width)
                  CastXYZ("sonic", minion)
                  PrintAction("Sonic minion LH")
                  return true
               end
            end
         end
      end

   end

   if IsOn("jungle") then
      local near = GetInRange(me, GetSpellRange("AA")+25, CREEPS)
      if #near > 0 and not P.flurry and JustAttacked() then
         
         if CanUse("sonic") then
            for _,creep in ipairs(GetInRange(me, "sonic", CREEPS)) do
               if creep.maxHealth > 1000 and IsGoodFireahead("sonic", creep) then                  
                  CastXYZ("sonic", creep)
                  PrintAction("Sonic in the jungle")
                  return true
               end
            end
         end

         if CanUse("strike") then
            Cast("strike", me)
            PrintAction("Strike in jungle")
            return true
         end

         if CanUse("tempest") and 
            #GetInRange(me, "tempest", CREEPS) >= 2 
         then
            Cast("tempest", me)
            PrintAction("Tempest for jungle AOE")
            return true
         end

         if CanUse("safeguard") and Alone() and GetHPerc(me) < .9 then
            Cast("safeguard", me)
            StartChannel(.25)
            PrintAction("Safeguard me in jungle")
            return true
         end
      end
   end

   if GetMPerc(me) > .5 and 
      not P.flurry and
      #GetInRange(me, GetSpellRange("AA")+25, ENEMIES, MINIONS, CREEPS) >= 1
   then
      if VeryAlone() and IsOn("clear") then
         if GetHPerc(me) < .75 and CanUse("safeguard") then
            Cast("safeguard", me)
            PrintAction("safeguard while clear")
            return true
         end

         if CanUse("tempest") and #GetInRange(me, "tempest", MINIONS) >= 3 then
            Cast("tempest", me)
            PrintAction("tempest for clear")
            return true
         end
      end

      if CanUse("will") then
         Cast("will", me)
         PrintAction("will for passive")
         return true
      end

      if CanUse("cripple") then
         Cast("cripple", me)
         PrintAction("Cripple for passive")
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
   -- TestSkillShot("sonic", "Q_mis")

   if harrass:run() then
      return true
   end

   if CanUse("strike") then
      if watched and WillKill("strike", "AA", watched) then
         Cast("strike", me)
         PrintAction("Strike for kill", watched)
         return true
      end
   end

   if IsOn("harrass") then
      if watched and 
         CanUse("safeguard") and CanUse("strike") and
         CanAttack() and
         GetSpellCost("strike") + GetSpellCost("safeguard") < me.mana 
      then
         local rt = SortByDistance(GetInRange(watched, altSpells["BlindMonkWOne"].range, ALLIES), me)[2] -- closest ally to me
         if not rt then
            rt = SortByDistance(GetInRange(watched, altSpells["BlindMonkWOne"].range, MYMINIONS, WARDS), me)[1]
         end

         if rt and GetDistance(rt) < 500 then
            LineBetween(me, watched)
            LineBetween(watched, rt)
            harrass:set("bounceTarget", rt)
            harrass:start()         
         end
      end
   end

   if SkillShot("sonic") then
      return true
   end

   if not P.flurry and CastBest("tempest") then
      return true
   end

   if CanUse("kick") then
      local target = GetWeakestEnemy("kick")
      if target and WillKill("kick", target) then
         Cast("kick", target)
         PrintAction("Kick for execute", target)
         return true
      end

      local targets = GetInRange(me, "kick", ENEMIES)
      local target, score = SelectFromList(targets, 
                               function(item) 
                                  local collisions = getKickCollisions(item)
                                  collisions = RemoveFromList(collisions, {item})
                                  local kills = GetKills("kick", collisions)
                                  return #collisions + 2*#kills
                               end
                            )
      if target and score >= 2 then
         Cast("kick", target)
         PrintAction("Kick for collateral damage")
         return true
      end

      if watched and IsInRange("kick", watched) and CanUse("strike") then
         local tt = cloneTarget(watched)
         tt.health = tt.health - GetSpellDamage("kick", tt)
         if WillKill("strike", tt) then
            Cast("kick", watched)
            PrintAction("Kick for strike execute", watched)
            return true
         end
      end
   end

   if IsOn("dive") then
      if CanUse("strike") and watched then
         if GetDistance(watched) > GetAARange()+25 then
            Cast("strike", me)
            PrintAction("Strike to close", watched)
            return true
         end
         if watchedTime + 2.5 < time() then
            Cast("strike", me)
            PrintAction("Strike for timeout", watched)
            return true
         end
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if target and not P.flurry and IsInRange("AA", target) and CanUse("will") then
      Cast("will", me)
      PrintAction("Will for autos", target)
      return true
   end

   if AutoAA(target) then
      return true
   end

   if CanUse("safeguard") then

      local allies
      if IsOn("dive") then
         allies = concat(ALLIES, MYMINIONS, WARDS)
      else
         allies = ALLIES
      end

      local target = GetMarkedTarget()
      if not target then
         local eir = GetInRange(me, GetAARange()+50, ENEMIES)
         for _,ally in ipairs(GetInRange(me, "safeguard", ALLIES, MYMINIONS, WARDS)) do
            for _,e in ipairs(GetInRange(ally, GetAARange()+50, ENEMIES)) do
               table.insert(eir, e)
            end
         end
         target = GetWeakest("AA", eir)
         if target and GetDistance(target, mousePos) > 200 then
            target = nil
         end
      end

      if target then
         local ally = SortByDistance(GetInRange(target, GetAARange()+50, ALLIES, MYMINIONS, WARDS))[1]
         if ally and GetDistance(ally) > 100 then
            Cast("safeguard", ally)
            PrintAction("Safeguard for improved position", ally)
            return true
         end
      end

      if CanUse("tempest") or CanUse("kick") then
         if #GetInRange(me, GetAARange()+25, ENEMIES) == 0 then
            local target = GetWeakest("AA", GetInRange(me, 525, ENEMIES))

            if target then
               if WillKill("AA", "tempest", "kick", target) --or
                  --IsOn("dive") 
               then
                  WardJump("safeguard", OverShoot(me, target, 75))
                  PrintAction("Wardjump to gap close", target)
                  return true
               end
            end
         end
      end
   end


   return false
end

function FollowUp()
   if VeryAlone() then
      if P.flurry then
         if HitObjectives() then
            return true
         end

         if HitMinion("AA", "weak") then
            return true
         end
      end
   end

   if IsOn("move") then
      if MeleeMove() then
         return true
      end
   end

   return false
end

function getKickCollisions(target)
   return GetInLine( target, 
                     {width=GetWidth(target)}, 
                     OverShoot(me, target, spells["kick"].knockback), 
                     GetInRange(target, spells["kick"].kockback, ENEMIES) )
end

local function onCreate(object)
   if PersistOnTargets("watched", object, "blindMonk_Q_tar_indicator", MINIONS, ENEMIES, CREEPS) then
      watchedTime = time()
   end

   PersistBuff("flurry", object, "blindMonk_passive")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")