require "utils"

ITEMS = {}
--Active offense
ITEMS["Entropy"]                  = {id=3184, range=me.range+50, type="active"}
ITEMS["Bilgewater Cutlass"]       = {id=3144, range=500,         type="active", color=violet}
ITEMS["Hextech Gunblade"]         = {id=3146, range=700,         type="active", color=violet}
ITEMS["Blade of the Ruined King"] = {id=3153, range=500,         type="active", color=violet}
ITEMS["Deathfire Grasp"]          = {id=3128, range=750,         type="active", color=violet}
ITEMS["Tiamat"]                   = {id=3077, range=350,         type="active", color=red}
ITEMS["Ravenous Hydra"]           = {id=3074, range=350,         type="active", color=red}
ITEMS["Youmuu's Ghostblade"]      = {id=3142, range=me.range+50, type="active"}
ITEMS["Randuin's Omen"]           = {id=3143, range=500,         type="active", color=yellow}

--Active defense
ITEMS["Locket of the Iron Solari"] = {id=3190, range=700, type="active", color=green}
ITEMS["Guardian's Horn"] = {id=2051, type="active"}
ITEMS["Zhonya's Hourglass"] = {id=3157, type="active"}
ITEMS["Wooglet's Witchcap"] = {id=3090, type="active"}

--Aura offense
ITEMS["Abyssal Scepter"] = {id=3001, range=700, type="aura", color=violet}
ITEMS["Frozen Heart"]    = {id=3110, range=700, type="aura", color=blue}

--Aura Defense
ITEMS["Mana Manipulator"]     = {id=3037, range=1200, type="aura", color=blue}
ITEMS["Aegis of Legion"]      = {id=3105, range=1200, type="aura", color=green}
ITEMS["Banner of Command"]    = {id=3060, range=1000, type="aura", color=yellow}
ITEMS["Emblem of Valor"]      = {id=3097, range=1200, type="aura", color=green}
ITEMS["Runic Bulwark"]        = {id=3107, range=1200, type="aura", color=green}
ITEMS["Shard of True Ice"]    = {id=3092, range=1200, type="aura", color=blue}
ITEMS["Will of the Ancients"] = {id=3152, range=1200, type="aura", color=yellow}
ITEMS["Zeke's Herald"]        = {id=3050, range=1200, type="aura", color=yellow}

--Active cleanse
ITEMS["Quicksilver Sash"]   = {id=3140,            type="active"}
ITEMS["Mercurial Scimitar"] = {id=3139,            type="active"}
ITEMS["Mikael's Crucible"]  = {id=3222, range=750, type="active"}

--On Hit
ITEMS["Malady"] = {id=3114, base={15}, ap=.1}
ITEMS["Wit's End"] = {id=3091, base={42}}

ITEMS["Sheen"]         = {id=3057, base={0}, adBase=1}
ITEMS["Trinity Force"] = {id=3078, base={0}, adBase=1.5}
ITEMS["Lich Bane"]     = {id=3100, base={50}, ap=.75}

-- Tear
ITEMS["Tear of the Goddess"] = {id=3070}
ITEMS["Archangel's Staff"] = {id=3003}
ITEMS["Manamune"] = {id=3004}

function UseItems(target)
   for item,_ in pairs(ITEMS) do
      UseItem(item, target)
   end
end

function UseItem(itemName, target)
   local item = ITEMS[itemName]
   local slot = GetInventorySlot(item.id)
   if not slot then return end   
   slot = tostring(slot)
   if not CanCastSpell(slot) then return end

   if itemName == "Entropy" or
      itemName == "Bilgewater Cutlass" or
      itemName == "Hextech Gunblade" or
      itemName == "Blade of the Ruined King" or
      itemName == "Deathfire Grasp" or
      itemName == "Tiamat" or
      itemName == "Ravenous Hydra" or
      itemName == "Youmuu's Ghostblade" or
      itemName == "Randuin's Omen"
   then
      if target and GetDistance(target) > item.range then
         return
      end
      if not target then
         target = GetWeakEnemy("MAGIC", item.range)
      end
      if target then
         CastSpellTarget(slot, target)
      end

   elseif itemName == "Shard of True Ice" then
      -- shard
      -- look at all nearby heros in range and target the one with the most nearby enemies
      local shardRadius = 300

      local nearCount = 0
      target = nil
      for i,hero in ipairs(ALLIES) do
         if GetDistance(me, hero) < 750 then
            local near = #GetInRange(hero, shardRadius, ENEMIES)
            if near > nearCount then
               target = hero
               nearCount = near
            end
         end
      end
      if target then
         CastSpellTarget(slot, target)
      end

   elseif itemName == "Guardian's Horn" then
      target = GetWeakEnemy("MAGIC", 600)
      if target then
         CastSpellTarget(slot, me)
      end

   elseif itemName == "Locket of the Iron Solari" then
      -- how about 3 nearby allies and 2 nearby enemies
      local locketRange = 700
      if #GetInRange(me, locketRange, ALLIES) >= 3 and
      #GetInRange(me, locketRange, ENEMIES) >= 2 
      then
         CastSpellTarget(slot, me)
      end

   elseif itemName == "Zhonya's Hourglass" or 
          itemName == "Wooglet's Witchcap"
   then
      -- use it if I'm at 10% and there's an enemy nearby
      -- may expand this to trigger when a spell is cast on me that will kill me
      local target = GetWeakEnemy("MAGIC", 1000)
      if target and me.health < me.maxHealth/10 then
         CastSpellTarget(slot, me)
      end

   elseif itemName == "Mikael's Crucible" then
      -- It can heal or it can cleans
      -- heal is better the lower they are so how about scan in range heros and heal the lowest under 25%
      -- the cleanse is trickier. should I save it for higher priority targets or just use it on the first who needs it?\
      -- I took (or tried to) take out the slows so it will only work on harder cc.
      -- how about try to free adc then apc then check for heals on all in range.

      local crucibleRange = 750

      local target = ADC
      if target and target.name ~= me.name and 
         GetDistance(target, me) < crucibleRange and
         #GetInRange(target, 50, CCS) > 0
      then 
         CastSpellTarget(slot, target)
         pp("uncc adc "..target.name) 
      else
         target = APC
         if target and target.name ~= me.name and 
         GetDistance(target, me) < crucibleRange and
         #GetInRange(target, 50, CCS) > 0
         then 
            CastSpellTarget(slot, target)
            pp("uncc apc "..target.name)
         end
      end

      for _,hero in ipairs(ALLIES) do
         if hero.health/hero.maxHealth < .25 then
            CastSpellTarget(slot, hero)
            pp("heal "..hero.name.." "..hero.health/hero.maxHealth)            
         end
      end
   end
end
