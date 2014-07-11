require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Lux")
pp(" - KS baron and dragon and people")
pp(" - pop singularity for kill or if they try to get out")
pp(" - SS Binding to peel from adc, apc, me or hit weakest")
pp(" - Singularity into groups for hits/kills else at weakest")
pp(" - Spark to hit 3 or more")
pp(" - AA flared")

SetChampStyle("caster")

-- I'd like to find a way to use binding and singularity to peel off adc/apc

-- final spark if people line up or for kills
AddToggle("ks", {on=true, key=112, label="Kill Steal Ult", auxLabel="{0}", args={"spark"}})
AddToggle("barrier", {on=true, key=113, label="Barrier Team"})
AddToggle("spark", {on=false, key=114, label="Auto Spark Barrage"}) --, auxLabel="{0}", args={numHits}})
AddToggle("", {on=false, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions", auxLabel="{0}", args={"singularity"}})
AddToggle("move", {on=true, key=118, label="Move"})

spells["binding"] = {
   key="Q", 
   range=1175, 
   color=violet, 
   base={60,110,160,210,260}, 
   ap=.7,
   delay=2.65,
   speed=12,
   width=80,
   cost={50,60,70,80,90}
}
spells["barrier"] = {
   key="W", 
   range=1075, 
   color=green, 
   base={80,105,130,155,180}, 
   ap=.35,
   delay=2,
   speed=14,
   width=80,
   cost=60
}
spells["singularity"] = {
   key="E", 
   range=1100, 
   color=yellow, 
   base={60,105,150,195,240}, 
   ap=.6,
   delay=2.65,
   speed=13,
   noblock=true,
   radius=350,
   cost={70,85,100,115,130}
}
spells["spark"] = {
   key="R", 
   range=3000, 
   color=red, 
   base={300,400,500}, 
   ap=.75,
   delay=6,
   speed=0,
   width=75,
   cost=100
}
spells["flare"] = {
   base={10},
   lvl=10,
   type="M"
}

spells["AA"].damOnTarget = 
   function(target)
      if HasBuff("flare", target) then
         return GetSpellDamage("flare")
      end
   end

function numHits()
   return #GetBestLine(me, "spark", 0, 1, ENEMIES)
end

local singularity

function Run()
   if StartTickActions() then
      return true
   end

   Circle(P.singularity, nil, blue)

   if KillSteal(P.BARON) then
      return true
   end
   if KillSteal(P.DRAGON) then
      return true
   end

   if CastAtCC("singularity") or
      CastAtCC("binding")
   then
      return true
   end

   -- check for instakills with spark. Alert and kill if toggled.
   if CanUse("spark") then
      local spell = GetSpell("spark")
      local target = GetWeakestEnemy("spark")
      if target and target.health < GetSpellDamage("spark", target) then
         LineBetween(me, Projection(me, target, spell.range), spell.width)
         if IsOn("ks") or HotKey() then
            if IsGoodFireahead(spell, target) then
               CastFireahead("spark", target)
               PrintAction("KS", target)
               return true
            end
         end
      end
   end

   -- if anyone tries to get out of my singularity pop it
   -- don't return, this is free
   if P.singularity and activeSingularity() then
      local spell = GetSpell("singularity")
      local enemies = GetInRange(P.singularity, spell.radius, ENEMIES)
      for _,enemy in ipairs(enemies) do
         if GetSpellDamage("singularity", enemy) > enemy.health then
            Cast(spell, me, true)
            PrintAction("Pop to kill", enemy)
            break
         end
         local nextPos = Point(GetFireahead(enemy, 4, 0))
         if GetDistance(P.singularity, nextPos) > spell.radius then
            Cast(spell, me, true)
            PrintAction("Pop escapees")
            break
         end
      end

      local minions = GetInRange(P.singularity, spell.radius, MINIONS)
      local kills = GetKills("singularity", minions)
      if ( Alone() and #kills >= 2 ) or
         #kills >= 3
      then
         Cast(spell, me, true)
         PrintAction("Pop to kill "..#kills.." minions")
      end
   end


   if HotKey() then
      if Action() then
         return true
      end
   end
   
   if IsOn("lasthit") and CanUse("singularity") and not activeSingularity() then
      -- lasthit with singularity if it kills 3 minions or more
      if KillMinionsInArea("singularity", 3) then
         return true
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
   -- try to deal some damage with singularity
   if CanUse("singularity") and not activeSingularity() then
      -- look for a big group or some kills.
      local hits, kills, score = GetBestArea(me, "singularity", 1, 3, ENEMIES)
      if score >= 3 then
         CastXYZ("singularity", GetAngularCenter(hits))
         PrintAction("Singularity for AoE")
         return true
      end

      -- barring that throw it at the weakest single
      local target = GetWeakestEnemy("singularity")
      if target then
         CastFireahead("singularity", target)
         PrintAction("Singularity", target)
         return true
      end
   end

   -- peel if necessary, else hit someone weak
   if CanUse("binding") then
      if SkillShot("binding", "peel") then
         UseItem("Deathfire Grasp", GetWeakestEnemy("binding"))
         return true
      end
      if SkillShot("binding") then
         UseItem("Deathfire Grasp", GetWeakestEnemy("binding"))
         return true
      end
   end

   -- try to hit a bunch of people with spark
   -- I'll want to give bonus points for flares
   if CanUse("spark") then
      -- don't care about kills because I already killed them if I could
      local hits = GetBestLine(me, "spark", 1, 0, ENEMIES)
      if #hits > 2 then
         local center = GetAngularCenter(hits)
         LineBetween(me, center, spells["spark"].width)
         if IsOn("spark") then
            UseItem("Deathfire Grasp", GetWeakest("spark", hits))
            CastXYZ("spark", center)
            PrintAction("Spark for AoE")
            return true
         end
      end
   end

   -- try to hit the loweset health target with a flare on em
   if CanAttack() then
      local targets = GetWeakest("flare", GetWithBuff("flare", GetInRange(me, "AA", ENEMIES)))
      if target then
         AA(target)
         PrintAction("AA for flare", target)
         return true
      end
   end

   return false
end

function FollowUp()
   local aaMinions = SortByHealth(GetInRange(me, "AA", MINIONS))
   local flaredMinions = GetWithBuff("flare", aaMinions)

   if IsOn("lasthit") and Alone() then
      for _,target in ipairs(flaredMinions) do
         local aaDam = GetAADamage(target)
         local flareDam = GetSpellDamage("flare", target)
         if aaDam + flareDam > target.health then
            AA(target)
            PrintAction("AA flared for lasthit")
            return true
         end
      end

      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clear") and Alone() then
      if CanUse("singularity") then
         local hits, kills, score = GetBestArea(me, "singularity", 1, 1, MINIONS)
         if score >= 7 then
            CastXYZ("singularity", GetAngularCenter(hits))
            PrintAction("Singularity for clear")
            return true
         end
      end

      for _,target in rpairs(flaredMinions) do
         AA(target)
         PrintAction("AA flared minion for clear")
         return true
      end

   end

end

function activeSingularity()
   return me.SpellNameE == "luxlightstriketoggle"
end

function checkBarrier(unit, spell)
   local W = GetSpell("barrier")
   if IsOn("barrier") and
      spell.target and
      not find(unit.name, "Minion") and
      not find(spell.target.name, "Minion") and
      CanUse("barrier") and
      unit.team ~= me.team and
      GetDistance(spell.target) < W.range and
      spell.target.team == me.team
   then
      -- don't bother shielding people near full health
      if spell.target.health/spell.target.maxHealth > .85 then
         return
      end
      
      -- Try to shield the target of the spell
      -- if I'm the target shoot it at the lowest health ally in range
      -- if there isn't anyone shoot it at the caster
      
      local target = spell.target      
      if spell.target.name == me.name then
         target = unit
         local minPH = 2
         for _,ally in ipairs(GetInRange(me, W.range, ALLIES)) do
            local lMinPH = ally.health,ally.maxHealth
            if lMinPH < minPH then
               target = ally
               minPH = lMinPH
            end
         end
      end
      CastFireahead("barrier", target)
      PrintAction("Shield", target)
   end
end

-- for baron and dragon
function KillSteal(target)
   if not target then return false end
   if #GetInRange(target, 1000, ENEMIES) < 2 then
      return false
   end
   if ValidTarget(target) and target.health < GetSpellDamage("spark", target) then
      CastXYZ("spark", target)
      PrintAction("KS", target)
      return true
   end
   return false
end


local function onObject(object)
   Persist("singularity", object, "LuxLightstrike_mis")
   PersistOnTargets("flare", object, "LuxDebuff", MINIONS, ENEMIES)   
end

local function onSpell(object, spell)
   checkBarrier(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
