require "Utils"
require "timCommon"
require "modules"

pp("\nTim's Ezreal")

AddToggle("farm", {on=true, key=112, label="Farm", auxLabel="{0} / {1}", args={GetAADamage, "shot"}})
AddToggle("harrass", {on=true, key=113, label="Harrass"})

spells["shot"]    = {key="Q", range=1100, width=75, color=violet, base={35,55,75,95,115}, ad=1, ap=.2, type="P"}
spells["flux"]    = {key="W", range=900, color=yellow, base={70,115,160,205,250}, ap=.8}
spells["arrow"]   = {key="E", range=475+750, color=violet, base={75,125,175,225,275}, ap=.75}
spells["shift"]   = {key="E", range=475, color=green}
spells["barrage"] = {key="R", range=99999, base={350, 500, 650}, ad=1, ap=.9}


function Run()
   TimTick()  
  
   -- TODO something with ult
   local target = GetWeakEnemy("MAGIC", 99999)
   if target then
      local x,y,z = GetFireahead(target, 1.2, 20)
      DrawCircle(x,y,z,100, red )
   end
  
   if HotKey() then
      UseItems()
      if combo() then
         return
      end
   end           
   
   if IsOn("harrass") then
      if mysticEnemy() then
         return
      end
   end
   
   local nearEnemy = GetWeakEnemy("MAGIC", 1100)
   if IsOn("farm") and not nearEnemy then
      lastHit()
   end
   
end

function lastHit()
   if KillWeakMinion("AA", 50) then
--      OrbWalk(500)
      return true
   end
   if CanUse("shot") then
      for _,minion in ipairs(GetUnblocked(me, spells["shot"].range, spells["shot"].width, MINIONS)) do
         if GetSpellDamage("shot", minion) > minion.health and
--            ( GetDistance(minion) > spells["AA"].range+50 or                 
--              GetSpellDamage("AA", minion) < minion.health ) 
            GetDistance(minion) > spells["AA"].range+50 
         then
            LineBetween(me, minion, spells["shot"].width)
            CastSpellXYZ("Q", minion.x, minion.y, minion.z)
--            OrbWalk(250)
            return true
         end   
      end
   end
   return false
end

function mysticEnemy()
   local target = GetWeakEnemy("PHYSICAL", spells["shot"].range)
   if target and CanUse("shot") then
      local unblocked = GetUnblocked(me, spells["shot"].range, spells["shot"].width, MINIONS, ENEMIES)

      unblocked = FilterList(unblocked, function(item) return not IsMinion(item) end)

      target = GetWeakest("shot", unblocked)

      if target then
         local x,y,z = GetFireahead(target,2,17)
         if GetDistance({x=x, y=y, z=z}) < spells["shot"].range then
            CastSpellXYZ('Q', x, y, z)
--            OrbWalk(250)
            return true            
         end
      end            
   end
   return false
end

function combo()
   -- flux enemy if flux is over level 1 (waste of mana at low levels)
   local target 
   target = GetWeakEnemy("PHYSICAL", spells["flux"].range)
   if GetSpellLevel("W") > 1 and target and CanUse("flux") then
      local x,y,z = GetFireahead(target,2,14)
      if GetDistance({x=x, y=y, z=z}) < spells["flux"].range then
         CastSpellXYZ('W', x, y, z)
--         OrbWalk(250)
         return true
      end            
   end
   
   -- mystic shot   
   if mysticEnemy() then
      return true
   end

   -- attack
   target = GetWeakEnemy("PHYSICAL", spells["AA"].range)
   if target and CanUse("AA") then
      AttackTarget(target)
--      OrbWalk()
      return true
   end
   return false
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
