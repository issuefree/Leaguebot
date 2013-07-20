require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Lux")
pp("  shield allies")
pp("  bind people")
pp("  singularity people, set it off if they try to get out.")
pp("  steal dragon")

-- I'd like to find a way to use binding and singularity to peel off adc/apc

-- final spark if people line up or for kills



spells["binding"] = {
   key="Q", 
   range=1175, 
   color=violet, 
   base={60,110,160,210,260}, 
   ap=.7,
   delay=2,
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
   delay=2,
   speed=12,
   area=350
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
local Q = spells["binding"]
local W = spells["barrier"]
local E = spells["singularity"]
local R = spells["spark"]

function numHits()
   return #GetInLine(R.width, GetInRange(me, R.range, ENEMIES))
end

AddToggle("barrier", {on=true, key=112, label="Barrier Team"})
AddToggle("bind", {on=true, key=113, label="Auto Bind"})
AddToggle("slow", {on=true, key=114, label="Auto Singularity"})
AddToggle("barrage", {on=false, key=115, label="Barrage", auxLabel="{0}", args={numHits}})
AddToggle("ks", {on=false, key=116, label="Kill Steal Ult"})


local singularity
local lastSingularity = GetClock()

function Run()
   TimTick()
   
   local t = GetMousePos()
   t.y = me.y
   local t2 = {x=t.x+250, y=t.y, z=t.z+150}
   local t3 = {x=t.x-250, y=t.y, z=t.z+150}
   
   local hits = GetInLine(R.width, GetInRange(me, R.range, CREEPS), "hits")
   local x,y,z = GetCenter(hits)
   
  
   DrawThickCircle(x,y,z,25,yellow, 6)
  
   for _,hit in ipairs(hits) do
      DrawThickCircle(hit.x, hit.y, hit.z, 25, violet,4)
   end

   for _,creep in ipairs(CREEPS) do
      DrawCircleObject(creep, GetWidth(creep), blue)
   end
   DrawLineObject(me, 3000, 0, AngleBetween(me, {x=x, y=y, z=z}), 75)   
   if IsOn("barrage") then
      CastSpellXYZ("R", x,y,z)
   end
   

   if Check(DRAGON) then
      if DRAGON[2].visible == 1 and DRAGON[2].health < GetSpellDamage("spark", DRAGON[2]) then
         CastSpellXYZ("R", DRAGON[2].x, DRAGON[2].y, DRAGON[2].z)
      end
   end
   
   local kst = GetWeakEnemy("MAGIC", R.range)
   if kst and CanUse("spark") then
      if kst.health < GetSpellDamage("spark") then
         PlaySound("Beep")
         LineBetween(me, kst, R.width)
         if IsOn("ks") then
            CastSpellXYZ("R", kst.x, kst.y, kst.z)
         end
      end
      local hits = GetInLine(R.width, ENEMIES)
      PrintState(0, "CanUlt: "..#hits)
      local x,y,z = GetCenter(hits)
      if #hits > 2 then
         LineBetween(me, {x=x,y=y,z=z}, R.width)
         if IsOn("barrage") then
            CastSpellXYZ("R", x,y,z)
         end
      end
   end
   
   if HotKey() then
      UseItems()
   
      if IsOn("bind") and CanUse("binding") then
         if not SkillShot("binding", "peel") then
            SkillShot("binding")
         end
      end
      if IsOn("slow") and CanUse("singularity") then
         if GetClock() - lastSingularity > 5000 then
            local target = GetPeel({ADC, APC, me}, ENEMIES)
            if target then
               local x,y,z = GetFireahead(target, E.delay, E.speed)
               CastSpellXYZ("E", x, y, z)
            else
               target = GetWeakEnemy("MAGIC", E.range)
               if target then
                  local x,y,z = GetFireahead(target, E.delay, E.speed)
                  if GetDistance({x=x, y=y, z=z}) < E.range then
                     CastSpellXYZ("E", x, y, z)
                  end
               end
            end
         end

         if Check(singularity) then
            local inRange = GetInRange(singularity[2], E.area, ENEMIES)
            for _,enemy in ipairs(inRange) do
               local x,y,z = GetFireahead(enemy, 2, 20)
               local eAngle = AngleBetween(enemy, {x=x, y=y, z=z})
               local d = 125
               local proj = {x=enemy.x+math.sin(eAngle)*d, z=enemy.z+math.cos(eAngle)*d}
               DrawCircle(proj.x, 0, proj.z, 100, yellow)
               if GetDistance(singularity[2], proj) > E.area then
                  CastSpellTarget("E", me)
                  break
               end
            end
         end
         
      end
   end
end

function checkBarrier(unit, spell)
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
      local x,y,z = GetFireahead(target, W.delay, W.speed)
      CastSpellXYZ("W", x, y, z)
   end
end

local function onObject(object)
   if object and object.charName and find(object.charName, "LuxLightstrike_mis") then
      singularity = {object.charName, object}
   end
end

local function onSpell(object, spell)
   checkBarrier(object, spell)

   if object.name == me.name and find(spell.name, "LuxLightStrikeKugel") then
      lastSingularity = GetClock()
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
