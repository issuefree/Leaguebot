require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Lux")
pp(" - KS baron and dragon and people")
pp(" - pop singularity for kill or if they try to get out")
pp(" - SS Binding to peel from adc, apc, me or hit weakest")
pp(" - Singularity into groups for hits/kills else at weakest")
pp(" - Spark to hit 3 or more")
pp(" - AA flared people or weakest")
pp("TODO:")
pp(" - improve lasthit")
pp(" - clearminions")

-- I'd like to find a way to use binding and singularity to peel off adc/apc

-- final spark if people line up or for kills

spells["binding"] = {
   key="Q", 
   range=1175, 
   color=violet, 
   base={60,110,160,210,260}, 
   ap=.7,
   delay=2.65,
   speed=12,
   width=80
}
spells["barrier"] = {
   key="W", 
   range=1075, 
   color=green, 
   base={80,105,130,155,180}, 
   ap=.35,
   delay=2,
   speed=14,
   width=80
}
spells["singularity"] = {
   key="E", 
   range=1100, 
   color=yellow, 
   base={60,105,150,195,240}, 
   ap=.6,
   delay=2.65,
   speed=13,
   radius=350
}
spells["spark"] = {
   key="R", 
   range=3000, 
   color=red, 
   base={300,400,500}, 
   ap=.75,
   delay=6,
   speed=99,
   width=75
}
spells["flare"] = {
   base={10},
   lvl=10
}

local flares = {}
local flaredEnemies = {}

function updateFlares()
   flaredEnemies = {}

   Clean(flares, "charName", "LuxDebuff")
   for _,flare in ipairs(flares) do
      for _,enemy in ipairs(ValidTargets(concat(ENEMIES, MINIONS))) do
         if GetDistance(flare, enemy) < 50 then
            flaredEnemies[enemy.charName] = enemy
            DrawBB(enemy, red)
            break
         end
      end
   end
end

function isFlared(object)
   return flaredEnemies[object.charName]
end

function numHits()
   return #GetBestLine(me, "spark", 0, 1, ENEMIES)
end

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("ks", {on=true, key=113, label="Kill Steal Ult", auxLabel="{0}", args={"spark"}})
AddToggle("barrier", {on=true, key=114, label="Barrier Team"})
AddToggle("spark", {on=false, key=115, label="Spark Barrage"}) --, auxLabel="{0}", args={numHits}})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions", auxLabel="{0}", args={"singularity"}})

local singularity

function Run()
   TimTick()

   updateFlares()

   -- local targets = TestTargets()

   -- local hits, score = GetBestArea(me, "singularity", 1, 0, targets)
   -- pp(score)

   -- local center = ToPoint(GetCenter(hits))
   -- DrawBB(center, violet)
   -- center.width = GetSpell("singularity").radius
   -- DrawBB(center, violet)

   -- for _,hit in ipairs(hits) do
   --    -- DrawText(math.floor(GetDistance(hit, center)), hit.x*.7-GetWorldX()+1300, GetWorldY()-hit.z*.7+400, 0xFFCCEECC)
   --    hit.width = 65
   --    DrawBB(hit, red)
   -- end


   if me.dead == 1 then
      return true
   end


   if KillSteal(GetObj(BARON)) then
      return true
   end
   if KillSteal(GetObj(DRAGON)) then
      return true
   end

   if IsRecalling(me) then
      return true
   end

   -- check for instakills with spark. Alert and kill if toggled.
   if CanUse("spark") then
      local spell = GetSpell("spark")
      local target = GetWeakestEnemy("spark")
      if target and target.health < GetSpellDamage("spark", target) then
         PlaySound("Beep")
         LineBetween(me, Projection(me, target, spell.range), spell.width)
         if IsOn("ks") or HotKey() then
            CastXYZ("spark", target)
            return true
         end
      end
   end

   -- if anyone tries to get out of my singularity pop it
   -- don't return, this is free
   if Check(singularity) then
      local spell = GetSpell("singularity")
      local enemies = GetInRange(GetObj(singularity), spell.radius, ENEMIES)
      for _,enemy in ipairs(enemies) do
         if GetSpellDamage("singularity", enemy) > enemy.health then
            Cast(spell, me)
            break
         end
         local nextPos = ToPoint(GetFireahead(enemy, 2, 99))
         if GetDistance(singularity[2], nextPos) > spell.radius then
            Cast(spell, me)
            break
         end
      end

      local minions = GetInRange(GetObj(singularity), spell.radius, MINIONS)
      local kills = GetKills("singularity", minions)
      if #kills > 2 then
         pp("KILLED "..#kills.." MINIONS")
         Cast(spell, me)
      end
   end


   if HotKey() then
      if Action() then
         return true
      end
   end
   

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
end

function Action()
   UseItems()

   -- peel if necessary, else hit someone weak
   if CanUse("binding") then
      if SkillShot("binding", "peel") then
         return true
      end
      if SkillShot("binding") then
         return true
      end
   end

   -- try to deal some damage with singularity
   if CanUse("singularity") and not activeSingularity() then
      -- look for a big group or some kills.
      local hits, kills, score = GetBestArea(me, "singularity", 1, 3, ENEMIES)
      if score >= 3 then
         CastXYZ("singularity", GetCenter(hits))
         return true
      end

      -- barring that throw it at the weakest single
      local target = GetWeakestEnemy("singularity")
      if target then
         CastSpellFireahead("singularity", target)
         return true
      end
   end

   -- try to hit a bunch of people with spark
   -- I'll want to give bonus points for flares
   if CanUse("spark") then
      -- don't care about kills because I already killed them if I could
      local hits = GetBestLine(me, "spark", 1, 0, ENEMIES)
      if #hits > 2 then
         local center = ToPoint(GetCenter(hits))
         LineBetween(me, center, spells["spark"].width)
         if IsOn("spark") then
            CastXYZ("spark", center)
            return true
         end
      end
   end

   -- try to hit the loweset health target with a flare on em
   local targets = SortByHealth(GetInRange(me, "AA", ENEMIES))
   for _,target in ipairs(targets) do
      if isFlared(target) then
         AA(target)
         return true
      end
   end
   -- -- otherwise just hit the weakest guy in range
   -- local target = GetWeakestEnemy("AA")
   -- if target and AA(target) then
   --    return true
   -- end


   return false
end

function FollowUp()
   local aaMinions = SortByHealth(GetInRange(me, "AA", MINIONS))
   local flaredMinions = FilterList(aaMinions, isFlared)

   if IsOn("lasthit") and Alone() then
      -- lasthit with singularity if it kills 3 minions or more
      if CanUse("singularity") then
         local hits, kills, score = GetBestArea(me, "singularity", 0, 1, MINIONS)
         if #kills >= 3 then
            CastXYZ("singularity", GetCenter(hits))
            return true
         end
      end


      for _,target in ipairs(flaredMinions) do
         local aaDam = GetAADamage(target)
         local flareDam = GetSpellDamage("flare", target)
         if aaDam + flareDam > target.health then
            AA(target)
            return true
         end
      end

      if KillWeakMinion("AA") then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      if CanUse("singularity") then
         local hits, kills, score = GetBestArea(me, "singularity", 1, 1, MINIONS)
         if score >= 7 then
            pp("hit: "..#hits.." killed "..#kills.." score "..score)
            CastXYZ("singularity", GetCenter(hits))
            return true
         end
      end

      for _,target in rpairs(flaredMinions) do
         AA(target)
         return true
      end

   end

   if IsOn("move") then
      MoveToCursor() 
      return true
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
      pp(unit.name.." : "..spell.name.." -> "..spell.target.name)
      
      -- don't bother shielding people near full health
      if spell.target.health / spell.target.maxHealth > .85 then
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
            local lMinPH = ally.health / ally.maxHealth
            if lMinPH < minPH then
               target = ally
               minPH = lMinPH
            end
         end
      end
      CastSpellFireahead("barrier", target)
   end
end

function KillSteal(target)
   if not target then return false end
   if #GetInRange(target, 1000, ENEMIES) < 2 then
      return false
   end
   if ValidTarget(target) and target.health < GetSpellDamage("spark", target) then
      CastXYZ("spark", target)
      return true
   end
   return false
end


local function onObject(object)
   if object and object.charName and find(object.charName, "LuxLightstrike_mis") then
      singularity = StateObj(object)
   end
   
   if object and object.charName and find(object.charName, "LuxDebuff") then
      table.insert(flares, object)
   end 
end

local function onSpell(object, spell)
   checkBarrier(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
