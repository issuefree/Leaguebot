require "Utils"
require "timCommon"
require "modules"
require "support"

pp("\nTim's Zyra")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=false, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "bloom"}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["bloom"] = {
   key="Q", 
   range=825, 
   color=violet, 
   base={75,115,155,195,235}, 
   ap=.6,
   delay=4,
   speed=0,
   noblock=true,
   radius=250,
   cost={75,80,85,90,95},
   name="ZyraQFissure"
}
spells["seed"] = {
   key="W", 
   range=825, 
   color=green,
   recharge={17,16,15,14,13},
   name="ZyraSeed"
}
spells["roots"] = {
   key="E", 
   range=1100, 
   color=yellow, 
   base={60,95,130,165,200}, 
   ap=.5,
   delay=2,
   speed=11.5, --?
   noblock=true,
   width=90,  --?
   growWidth=315,
   cost={70,75,80,85,90},
   name="ZyraGraspingRoots"
}
spells["strangle"] = {
   key="R", 
   range=700, 
   color=red, 
   base={180,265,350}, 
   ap=.7,
   delay=2,
   speed=0,
   noblock=true,
   area=600,  --?
   cost={100,120,140}
}

local castSeedAt = time()
local seedDelay = .5
local seedCharges = 2
local st = time()

function Run()
   local lvl = GetSpellLevel("W")
   if lvl > 0 then
      if seedCharges == 2 then
         st = time()
      else
         local sTime = spells["seed"].recharge[lvl] * (1+me.cdr)
         if time() - st > sTime then
            st = time()
            seedCharges = seedCharges + 1
         end
      end
   end

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   local seeds = GetPersisted("seed")

   for _,seed in ipairs(seeds) do
      if CanUse("bloom") and GetDistance(seed, GetMousePos()) < spells["bloom"].radius then
         Circle(seed, 75, violet, 3)
         LineBetween(mousePos, seed)
      end
      if CanUse("roots") and GetDistance(seed, GetMousePos()) < spells["roots"].growWidth then
         Circle(seed, 70, yellow, 3)
         LineBetween(mousePos, seed)
      end
   end

   if HotKey() then
      UseItems()
      if Action() then
         return true
      end
   end

   -- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") and Alone() then
      if KillMinionsInArea("bloom", 2) then
         return true
      end
   end


   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   PrintAction()
end

function Action()
   if CanUse("roots") then
      local target = GetSkillShot("roots")
      if target then
         if canSeed() then
            local point = GetSpellFireahead("roots", target)
            if GetDistance(point) > GetSpellRange("seed") then
               point = Projection(me, point, GetSpellRange("seed"))
            end            
            CastXYZ("seed", point)
         end
         CastFireahead("roots", target)
         PrintAction("Roots", target)
         return true
      end
   end

   if CanUse("bloom") then
      local target = GetSkillShot("bloom")
      if target then
         if canSeed() then
            CastXYZ("seed", GetSpellFireahead("bloom", target))
         end
         CastFireahead("bloom", target)
         PrintAction("Bloom", target)
         return true
      end
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillWeakMinion("AA") then
         PrintAction("AA lasthit")
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      -- hit the highest health minion
      local minions = SortByHealth(GetInRange(me, "AA", MINIONS))
      if AA(minions[#minions]) then
         PrintAction("AA clear minions")
         return true
      end
   end

   return false
end

function canSeed()
   return CanUse("seed") and 
          time() - castSeedAt > seedDelay and 
          seedCharges > 0
end

local function onObject(object)
   if PersistAll("seed", object, "Zyra_seed_indicator_team") then
      castSeedAt = time()
      seedCharges = seedCharges - 1
   end
end

local function onSpell(unit, spell)
   -- if ICast("seed", unit, spell) then
      -- pp(unit.name.." "..spell.name)
   -- end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
