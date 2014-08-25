require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Nidalee")

AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"heal"}})
AddToggle("trap", {on=true, key=113, label="Auto Trap", auxLabel="{0}", args={"trap"}})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["jav"] = {
   key="Q", 
   range=1500, 
   color=violet, 
   base={50,75,100,125,150}, 
   ap=.4,
   cost={50,60,70,80,90},
   width=40,  -- from patch notes
   delay=1.5,  -- testskillshot
   speed=12.5,  -- testskillshot
   cd=6
}
spells["takedown"] = {
   key="Q",
   range=function() return GetAARange() + 75 end,
   color=violet,
   base=function()
      base={4,20,50,90}
      return base[GetSpellLevel("R")]
   end,
   ad=1,
   ap=.24,
   modAA="takedown",
   object="Nidalee_Base_Cougar_Q_Buf.troy",
   damOnTarget=function(target)
      if target then
         local dam = GetSpellDamage("takedown")
         local bonus = 0
         if HasBuff("prowl", target) then
            bonus = bonus + dam*.33
         end
         bonus = bonus + dam*(1-GetHPerc(target))*1.5
         return bonus
      end
      return 0
   end,
   cd=5
}

spells["trap"] = {
   key="W", 
   range=900,
   color=yellow,
   base={20,40,60,80,100},
   targetHealth={.10,.12,.14,.16,.18},
   targetHealthAP=.0002,
   delay=5, -- 2.5 to land ~2.5 to arm
   speed=0,
   radius=85, -- reticle
   noblock=true,
   cost={40,45,50,55,60},
   cd={13,12,11,10,9}
}
spells["pounce"] = {
   key="W",
   range=375,
   color=yellow,
   base=function()
      base={50,100,150,200}
      return base[GetSpellLevel("R")]
   end,
   ap=.3,
   radius=140+75, -- plus cougar size I imagine (reticle is close)
   cd=5
}
spells["pounceProwl"] = copy(spells["pounce"])
spells["pounceProwl"].range = 750

spells["heal"] = {
   key="E", 
   range=600, 
   color=green, 
   base={45,85,125,165,205}, 
   ap=.5,
   type="H",
   cost={60,75,90,105,120},
   cd=12
}
spells["swipe"] = {
   key="E",
   range=300+75+1, -- reticle
   color=red,   
   base=function()
      base={70,130,190,250}
      return base[GetSpellLevel("R")]
   end,
   ap=.45,
   cone=180, -- reticle
   noblock=true,
   cd=5
}
spells["cougar"] = {
   key="R"
}

local isCougar = false

function Run()
   PrintState(0, GetSpellDamage("takedown", GetGolem()))
   if me.SpellNameQ == "Takedown" then
      isCougar = true
   else
      isCougar = false
   end

   if isCougar then
      InitAAData({ -- cougar
         projSpeed = 1.7, windup=.2,
         resets = {me.SpellNameQ},   
      })
      spells["jav"].key = "--"
      spells["trap"].key = "--"
      spells["heal"].key = "--"
      spells["takedown"].key = "Q"
      spells["pounce"].key = "W"
      spells["pounceProwl"].key = "W"
      spells["swipe"].key = "E"

   else
      InitAAData({
         projSpeed = 1.7, windup=.25,
         particles = {"nidalee_javelin_mis"},
      })
      spells["jav"].key = "Q"
      spells["trap"].key = "W"
      spells["heal"].key = "E"
      spells["takedown"].key = "--"
      spells["pounce"].key = "--"
      spells["pounceProwl"].key = "--"
      spells["swipe"].key = "--"

   end   

   if StartTickActions() then
      return true
   end
   
   if CastAtCC("spear") then
      return true
   end
   if CastAtCC("trap") then
      return true
   end

   if IsOn("healTeam") and not isCougar then
      if HealTeam("heal") then
         return true
      end
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") then
      if isCougar then
         if Alone() then
            if KillMinionsInCone("swipe", 2) then
               return true
            end

            if KillMinionsInArea("pounce", 3) then -- save pounces a bit more than swipes
               return true
            end

            if ModAAFarm("takedown") then
               return true
            end
         end
      end
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end
   EndTickActions()
end

function Action()
   if not isCougar then
      if SkillShot("jav") then
         return true
      end      
      
      if CanUse("cougar") then
         local target = GetWeakest("pounce", GetInRange(me, "pounceProwl", GetWithBuff("prowl", ENEMIES)))
         if target then
            MarkTarget(target)
            Cast("cougar", me)
            PrintAction("Coxugar for big pounce", target)
            return true
         end
      end

      if IsOn("trap") and CanUse("trap") then
         -- plant traps
         local target = GetWeakestEnemy("trap")
         if target then
            if CastFireahead("trap", target) then
               PrintAction("It's a trap")
               return true
            end
         end
      end

      local target = GetMarkedTarget() or GetWeakestEnemy("AA")
      if AutoAA(target) then
         return true
      end
      
   else 
      
      if CanUse("pounce") then
         local target = GetMarkedTarget() or GetWeakestEnemy("pounce", spells["pounce"].radius)
         if target and not IsInRange("AA", target) then
            CastXYZ("pounce", target)
            PrintAction("Pounce toward", target)
            return true
         end
      end

      -- check for execute, those are good
      if CanUse("takedown") then
         local target = SortByHealth(GetKills("takedown", GetInRange(me, "takedown", ENEMIES)), "takedown")[1]
         if target then
            Cast("takedown", target)
            AttackTarget(target)
            PrintAction("Takedown for execute", target)
            return true
         end
      end

      if CanUse("swipe") then
         local target = GetMarkedTarget()
         if not target then
            target = GetWeakest("swipe", GetInRange(me, "swipe", GetWithBuff("prowl", ENEMIES)))
         end
         if not target then
            local hits, kills, score = GetBestCone(me, "swipe", 1, 1, ENEMIES)
            if #hits >= 1 then
               target = GetAngularCenter(hits)
            end
         end
         if target then
            CastXYZ("swipe", target)
            PrintAction("Swipe")
            return true
         end
      end

      if CanUse("takedown") then
         local target = GetMarkedTarget() or GetWeakestEnemy("takedown")  -- GetWeakestEnemy should take intou account prowl
         if target then
            Cast("takedown", target)
            AttackTarget(target)
            PrintAction("Takedown", target)
            return true
         end
      end

      local target = GetMarkedTarget() or GetMeleeTarget()
      if AutoAA(target) then
         return true
      end

   end


   return false
end

function FollowUp()
   if IsOn("clear") then
      if isCougar then
         if VeryAlone() then
            if CanUse("swipe") then
               if HitMinionsInCone("swipe", 3) then
                  return true
               end
            end
         end
      end
   end

   if isCougar then
      if IsOn("move") then
         if MeleeMove() then
            return true
         end
      end      
   end

   return false
end

local function onObject(object)
   PersistOnTargets("prowl", object, "Nidalee_Base_Q_Buf.troy", ENEMIES)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
