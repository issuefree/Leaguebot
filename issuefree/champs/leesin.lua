require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Lee Sin")

local altSpells = {}
altSpells["BlindMonkQOne"] = {
   key="Q", 
   range=975,
   color=violet, 
   base={50,80,110,140,170}, 
   adBonus=.9,
   type="P",
   delay=2.5,
   speed=18,
   width=90,
   cost=50
}
altSpells["blindmonkqtwo"] = {
   key="Q", 
   range=1100,
   color=violet, 
   base={50,80,110,140,170}, 
   adBonus=.9,
   percMissingHealth=.08,
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
   range=350, 
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
   bonusAd=2,
   type="P"
} 

qrq = {
   state=nil,
   target=nil,
   timeout=0,

   getLabel =
      function()
         return ( GetSpellDamage(altSpells["BlindMonkQOne"]) +
                  GetSpellDamage("kick") +
                  GetSpellDamage(altSpells["blindmonkqtwo"]) )
      end,

   run =
      function()
         if qrq.state then
            if time() > qrq.timeout then
               PrintAction("QRQ: timeout")
               qrq.reset()
               return false
            end
            qrq[qrq.state]()
            return true
         end
         return false
      end,

   reset =
      function()
         qrq.target = nil
         qrq.pos = nil
         qrq.state = nil
         qrq.timeout = 0
      end,   

   start =
      function(target)
         if CanUse("sonic") and CanUse("kick") and
            me.mana > GetSpellCost("sonic") + altSpells["blindmonkqtwo"].cost
         then
            qrq.target = target
            qrq.pos = Point(me)
            qrq.state = "sonic"
            qrq.timeout = time() + 3.5

            return true
         end
         return false
      end,

   startInsec =
      function(target, pos)
         if CanUse("safeguard") and CanUse("sonic") and CanUse("kick") and
            me.mana > GetSpellCost("sonic") + altSpells["blindmonkqtwo"].cost + GetSpellCost("safeguard")
         then
            qrq.target = target
            qrq.pos = pos
            qrq.state = "ward"
            qrq.timeout = time() + 3.5

            return true
         end
         return false
      end,

   ward =
      function()
         local wTarg = SortByDistance(GetAllInRange(qrq.pos, 100, ALLIES, MYMINIONS, WARDS), qrq.pos)[1]
         if wTarg then
            Cast("safeguard", wTarg)
            PrintAction("QRQ: jump to position")
            qrq.state = "sonic"
            qrq.timeout = time() + 3.5
            return true
         else
            WardJump("safeguard", qrq.pos)
            return true
         end
         return false
      end,

   sonic = 
      function()
         if CanUse("sonic") and
            GetDistance(qrq.target) < GetSpellRange("sonic") and
            GetDistance(qrq.pos) < 100
         then
            CastXYZ("sonic", qrq.target)
            DoIn(function() CastXYZ("sonic", qrq.target) end, .25)
            PrintAction("QRQ: sonic", qrq.target)
            qrq.state = "kick"
            return true
         end
         return false
      end,

   kick =
      function()
         if CanUse("kick") and 
            GetDistance(qrq.target) < GetSpellRange("kick") and
            HasBuff("watched", qrq.target)
         then
            Cast("kick", qrq.target)
            PrintAction("QRQ: kick", qrq.target)
            qrq.state = "strike"
            return true
         end
         return false
      end,

   strike = 
      function()
         if CanUse("strike") and 
            GetDistance(qrq.target) < GetSpellRange("strike") and
            GetDistance(qrq.target) > 350
         then
            Cast("strike", me)
            PrintAction("QRQ: strike", qrq.target)
            qrq.reset()
            return true
         end
         return false
      end
}

function getBounceLabel()
   return ( GetSpellDamage(altSpells["BlindMonkQOne"]) +
            GetSpellDamage(altSpells["blindmonkqtwo"]) )
end

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("bounce", {on=false, key=113, label="Bounce Harrass", auxLabel="{0}", args={getBounceLabel}})
AddToggle("qrq", {on=false, key=114, label="QRQ Combo", auxLabel="{0}", args={qrq.getLabel}})
AddToggle("jungle", {on=true, key=115, label="Jungle"})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})



-- Harrass combo
  -- if Q lands follow up with strike and safeguard out.
-- Tempest for last hits?
-- strike for execute
-- kick for execute
-- strike -> kick for execute
-- strike -> tempest -> kick for execute

local bounceTarget
local watched

function Run()

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

   if IsOn("bounce") then
      if bounceHarrass() then
         return true
      end
   end

   if qrq.run() then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if CanUse("tempest") then
         if #GetKills("tempest", GetAllInRange(me, "tempest", MINIONS)) >= 1 then
            Cast("tempest", me)
            PrintAction("Tempest for lasthit")
            return true
         end
      end

      if Alone() and CanUse("sonic") then
         for _,minion in ipairs(GetUnblocked(me, "sonic", MINIONS)) do
            if GetDistance(minion) > GetSpellRange("AA") and 
               WillKill("sonic", minion)
            then
               LineBetween(me, minion, spells["sonic"].width)
               CastXYZ("sonic", minion)
               PrintAction("Butcher minion")
               return true
            end
         end
      end

   end

   if IsOn("jungle") then
      local near = GetAllInRange(me, GetSpellRange("AA")+25, CREEPS)
      if #near > 0 and not P.flurry and JustAttacked() then
         
         if CanUse("strike") then
            Cast("strike", me)
            PrintAction("Strike in jungle")
            return true
         end

         if CanUse("tempest") and 
            #GetAllInRange(me, "tempest", CREEPS) >= 2 
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
      #GetAllInRange(me, GetSpellRange("AA")+25, ENEMIES, MINIONS, CREEPS) >= 1
   then
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
   if IsOn("qrq") then
      local target = GetWeakestEnemy("kick")
      if target then
         local tt = {}
         tt.health = target.health
         tt.maxHealth = target.maxHealth
         tt.armor = target.armor
         tt.magicArmor = target.magicArmor
         tt.health = tt.health - GetSpellDamage("kick", target)
         tt.health = tt.health - GetSpellDamage("sonic", target)

         if WillKill(altSpells["blindmonkqtwo"], tt) then
            if qrq.start(target) then
               return true
            end
            -- if qrq.startInsec(target, Projection(me, target, GetDistance(target)+100)) then
            --    return true
            -- end
         end
      end
   end

   if CanUse("strike") then
      local target = GetWithBuff("watched", ENEMIES)[1]
      if target then
         if WillKill("strike", "AA", "tempest", "kick", target) then
            Cast("strike", target)
            AA(target)
            PrintAction("Strike for execute", target)
            return true
         end
      end
   end

   if CanUse("tempest") then
      local target = GetWeakestEnemy("tempest")
      if target then
         Cast("tempest", target)
         PrintAction("Tempest", target)
         return true
      end
   end

   if CanUse("kick") then
      local target = GetWeakestEnemy("kick")
      if target and WillKill("kick", target) then
         Cast("kick", target)
         PrintAction("Kick for execute", target)
         return true
      end
   end


   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
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

function bounceHarrass()
   if watched and 
      CanUse("safeguard") and CanUse("strike") and
      GetSpellCost("strike") + GetSpellCost("safeguard") < me.mana 
   then
      local rt = SortByDistance(GetInRange(watched, 1100, ALLIES), me)[2]
      if not rt then
         rt = SortByDistance(GetAllInRange(watched, 1100, MYMINIONS, WARDS), me)[1]
      end

      if rt and GetDistance(rt) < 500 then
         LineBetween(me, watched)
         LineBetween(watched, rt)
         Cast("strike", watched)
         bounceTarget = rt
         PrintAction("BOUNCE")
         DoIn(function() bounceTarget = nil end, 4)
         return true
      end
   end
   return false
end



-- pre: Spells are ready, have target, have enough energy
-- if no ward: lay ward -> set target
-- safeguard to ward
-- sonic target
-- kick target
-- strike target

local function onCreate(object)
   PersistOnTargets("watched", object, "blindMonk_Q_tar_indicator", MINIONS, ENEMIES, CREEPS)

   PersistBuff("flurry", object, "blindMonk_passive")

   if find(object.charName, "blindmonk_resonatingstrike_tar") then
      if bounceTarget then
         DoIn(function() Cast("safeguard", bounceTarget) end, .1)
         Cast("safeguard", bounceTarget)
         PrintAction("Bounce back")
      end
   end
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

