require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Gnar")

-- TODO
-- hop for change and aoe bounce crunch
-- gnar into walls
-- track aa stacks

-- SetChampStyle("marksman")
-- SetChampStyle("caster")

function getBoDam()
   if mega then
      return GetSpellDamage("boulder")
   else
      return GetSpellDamage("boomerang")
   end
end

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, getBoDam}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["boomerang"] = {
   key="Q", 
   range=1100, 
   color=violet, 
   base={10,45,80,115,150}, 
   ad=1,
   delay=2.4, -- testskillshot
   speed=18,  -- testskillshot
   width=60,  -- reticle
} 
spells["boulder"] = {
   key="--", 
   range=1100+45, 
   color=violet, 
   base={10,50,90,130,170}, 
   ad=1.2,
   delay=4.9, -- testskillshot
   speed=20,  -- testskillshot
   width=90,  -- wiki
   radius=45
} 
spells["hyper"] = {
   base={25,30,35,40,45}, 
   ap=1,
   targetMaxHealth={.06,.08,.10,.12,.14},
} 
spells["wallop"] = {
   key="--", 
   range=500, -- seems close
   color=yellow, 
   base={25,45,65,85,105}, 
   ad=1,
   delay=6,   -- testskillshot
   speed=50,  -- instant but line
   width=125, -- visual
   noblock=true,
} 
spells["hop"] = {
   key="E", 
   range=475, 
   color=blue, 
   base={20,60,100,140,180}, 
   maxHealth=.06,
   delay=2.4,  -- ?
   speed=12,   -- ?
   radius=150, -- reticle
} 
spells["crunch"] = {
   key="--", 
   range=475, 
   color=blue, 
   base={20,60,100,140,180}, 
   maxHealth=.06,
   radius=350, -- visual
} 
spells["crunchBounce"] = copy(spells["crunch"])
spells["crunchBounce"].range = spells["crunch"].range*2

spells["gnar"] = {
   key="R", 
   range=425, -- 590?
   color=red, 
   base={200,300,400}, 
   adBonus=.2,
   ap=.5,
   knockback=590-425+75
} 

spells["AA"].damOnTarget = 
   function(target)
      if HasBuff("twoRing", target) then
         return GetSpellDamage("hyper", target, true)
      end
      return 0
   end

local mega = false
local mini = true

function Run()
   if me.SpellNameE == "gnarbige" then
      mega = true
   else
      mega = false
   end

   mini = not mega
   if mega then
      spells["boomerang"].key = "--"
      spells["boulder"].key = "Q"
      spells["wallop"].key = "W"
      spells["hop"].key = "--"
      spells["crunch"].key = "E"
      spells["gnar"].key = "R"

      InitAAData({ 
         windup=.4,
         particles = {} 
      })      
   else
      spells["boomerang"].key = "Q"
      spells["boulder"].key = "--"
      spells["wallop"].key = "--"
      spells["hop"].key = "E"
      spells["crunch"].key = "--"
      spells["gnar"].key = "--"

      InitAAData({ 
         windup=.2,
         particles = {"Gnar_Base_BA_mis.troy"} 
      })      
   end

   if mega then
      PrintState(0, "MEGA")
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   -- if CheckDisrupt("gnar") then
   --    return true
   -- end

   if CastAtCC("boomerang") or
      CastAtCC("boulder")
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
         if CanUse("boomerang") then
            if KillMinion("boomerang") then
               return true
            end
         end

         if CanUse("boulder") then
            if KillMinionsInArea("boulder") then
               return true
            end
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
   -- TestSkillShot("boomerang", "Gnar_Base_Q_mis.troy")
   -- TestSkillShot("hop")
   -- TestSkillShot("wallop", nil, {"Gnar_Base_W_Big_Beam.troy", "GnarBig_Base_W_Swoosh.troy"})
   -- TestSkillShot("boulder")

   if SkillShot("boomerang") then
      return true
   end
   if SkillShot("boulder") then
      return true
   end
   if SkillShot("wallop") then
      return true
   end

   if CanUse("crunch") then
      local hits, kills, score = GetBestArea(me, "crunch", 1, 5, ENEMIES)

      local near = SortByDistance(hits)[1]
      if near and GetDistance(near) > GetAARange() then
         local point = Projection(me, near, GetDistance(near), GetSpellRange("crunch"))
         CastXYZ("crunch", point)
         PrintAction("Crunch for gap close", near)
         return true
      end

      if score >= 3 then
         CastXYZ("crunch", GetCastPoint(hits, "crunch"))
         PrintAction("Crunch for AoE", score)
         return true
      end
   end

   if mini and me.SpellNameQ == "gnarbigq" then
      local bestS
      local bestH = 1
      local starts = SortByDistance(GetInRange(me, GetSpellRange("hop")+spells["hop"].radius-25, ENEMIES))
      for _,start in ipairs(starts) do
         local hits = GetInLine(start, "crunch", OverShoot(me, start, 100), ENEMIES)
         if #hits > bestH then
            bestS = start
            bestH = #hits
         end
      end
      -- bestS = starts[1]
      if bestS then
         CastXYZ("hop", GetCastPoint(bestS, "hop"))
         PrintAction("CHARGE", bestS)
         return true
      end
   end

   if CanUse("gnar") then
      local targets = SortByDistance(GetInRange(me, "gnar", ENEMIES))
      for _,target in ipairs(targets) do
         local cp = NearWall(target, spells["gnar"].knockback)
         if cp then
            local angle = AngleBetween(target, cp)
            CastXYZ("gnar", ProjectionA(me, angle, 100))
            PrintAction("GNAR into wall", gnar)
            return true
         end
      end
   end

   local target 
   if mega then
      target = GetMarkedTarget() or GetMeleeTarget()
   else
      target = GetMarkedTarget() or GetWeakestEnemy("AA")
   end
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   if mega then
      if IsOn("move") then
         if MeleeMove() then
            return true
         end
      end
   end
   return false
end

local function onCreate(object)
   PersistOnTargets("oneRing", object, "Gnar_Base_P_Counter1.troy", ENEMIES, MINIONS)
   PersistOnTargets("twoRing", object, "Gnar_Base_P_Counter2.troy", ENEMIES, MINIONS)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

