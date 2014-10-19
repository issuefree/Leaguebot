require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Thresh")

InitAAData({
   windup=.35+.1,  -- fundge because of his very poor speed scaling.
   extraRange=15,
   particles = {"Thresh_ba"} 
})

local souls = 0
local function setSouls(val)
   souls = val
   config["souls"] = souls
   SaveConfig("thresh", config)
end

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} ~ {1} / {2}", args={GetAADamage, function() return souls end, "flay"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move to Mouse"})

spells["hook"] = {
   key="Q", 
   range=1075, 
   color=violet, 
   base={80,120,160,200,240}, 
   ap=.5,

   delay=5,       -- tss
   speed=19,      -- tss
   width=65,      -- reticle
   
   cost=80
} 
spells["lantern"] = {
   key="W", 
   range=950, 
   color=blue, 
   base={60,100,140,180,220}, 
   ap=.4,
   
   delay=.5,      -- tss
   speed=14,      -- tss
   radius=300,    -- reticle

   cost={50,55,60,65,70}
} 
spells["flay"] = {
   key="E", 
   range=400+100, 
   color=yellow, 
   base={65,95,125,155,185}, 
   ap=.4,

   delay=.3,      --tss
   speed=15,      --tss
   width=150,     --reticle
   noblock=true,

   buildup=10,
   flayScale={.80,1.10,1.40,1.70,2.00},

   cost={60,65,70,75,80}
} 
spells["box"] = {
   key="R",
   range=450,
   color=red,
   base={250,400,550},
   ap=1
}

spells["AA"].bonus = function()
   return souls + GetLVal(spells["flay"], "flayScale")*(me.baseDamage+me.addDamage) * math.min(time() - aaTime, 9) / 9
end

spells["flayAA"] = {
   base=function() return souls end,
}

spells["box"] = {
   key="R", 
   range=450, 
   color=red, 
   base={250,400,550}, 
   ap=1,
   cost=100
} 

aaTime = 0
souls = 0
config = LoadConfig("thresh")
if config and config["souls"] then
   souls = config["souls"]
else
   config = {}
end

if GetSpellLevel("E") == 0 then
   setSouls(0)
end

local health = 0

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("flay") or
      CheckDisrupt("hook")
   then
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
      if Alone() then
         if KillMinionsInShape("flay", nil, getBestFlay) then
            return true
         end
      end
   end

   if IsOn("clear") then
      if VeryAlone() then
         if HitMinionsInShape("flay", nil, getBestFlay) then
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

   EndTickActions()
end

function Action()
   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   return false
end

local function onCreate(object)
   if find(object.charName, "Thresh_Soul_Eat_buf") then
      pp(object)
      setSouls(souls+1)
      PrintAction("Gathered soul "..souls)
   end
end

local function onSpell(unit, spell)
   if IAttack(unit, spell) then
      aaTime = time()+1.5
   end
end

function getBestFlay(source, thing, hitScore, killScore, ...)
   local spell = GetSpell(thing)
   local width = spell.width

   local targets = GetInRange(source, spell, concat(...))

   local bestS = 0
   local bestT = {}
   local bestK = {}
   for _,target in ipairs(targets) do
      local backswing = OverShoot(target, source, spell.range)
      local hits = GetInLineR(backswing, spell, target, targets)
      local score, kills = scoreHits(spell, hits, hitScore, killScore)
      if not bestT or score > bestS then
         bestS = score
         bestT = hits
         bestK = kills
      end
   end

   return bestT, bestK, bestS
end

function onKey(msg, key)
   if msg == KEY_UP then
      if key == 107 then         
         setSouls(souls + 1)
      elseif key == 109 then
         setSouls(souls - 1)
      end
   end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnKey(onKey)
SetTimerCallback("Run")

