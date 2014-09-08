require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Heimerdinger")

SetChampStyle("caster")

InitAAData({
  projSpeed = 1.4, windup=.25,
  particles = {"Heimerdinger_Base_AA"}
})

function ggt()
   return trunc(GetThreshMP("grenade", .1, 1.5))
end

AddToggle("ult", {on=true, key=112, label="Auto Ult"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}({2})", args={GetAADamage, "grenade", ggt}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["turret"] = {
   key="Q", 
   range=450,
   turretRange=525,
   color=yellow,
   delay=2,
   speed=0,
   radius=100,
   -- cost=20
}
spells["rockets"] = {
   key="W", 
   range=1200, 
   color=violet, 
   base={60,90,120,150,180}, 
   ap=.45,
   delay=2.4,  -- TestSkillShot
   speed=22,
   width=50,
   overShoot=-100,
   noblock=true,
   -- cost={70,80,90,100,110}
}
spells["grenade"] = {
   key="E", 
   range=925, 
   color=blue, 
   base={60,100,140,180,220}, 
   ap=.6,
   delay=2.4, -- TestSkillShot
   speed=12,
   noblock=true,
   radius=150,
   radiusBase=150,
   radiusUp=300,
   -- cost=85
}
spells["upgrade"] = {
   key="R", 
   -- cost=100
}

function Run()
   local sentries = GetPersisted("sentry")

   if StartTickActions() then
      return true
   end

   if P.upgrade then
      PrintState(1, "UPGRADE")
      -- spells["rockets"].noblock = true
      spells["grenade"].radius = spells["grenade"].radiusUp
   else
      -- spells["rockets"].noblock = false
      spells["grenade"].radius = spells["grenade"].radiusBase
   end

   if CheckDisrupt("grenade") then
      return true
   end

   if CanUse("rockets") and CanUse("upgrade") and not P.upgrade then
     local target = CastAtCC("rockets", true, true)
     if target then
        Cast("upgrade", me)
        StartChannel(.25)
        -- CastXYZ("rockets", target)
        PrintAction("Destroy CCd", target)
        return true
     end
  end

   if CastAtCC("rockets") or
      CastAtCC("grenade")
   then
      return true
   end

	if HotKey() then
		if Action() then
			return true
		end
	end

   -- if IsOn("lasthit") and CanUse("rockets") and VeryAlone() then
   --    local targets = SortByDistance(GetInRange(me, "rockets", MINIONS))
   --    if #targets >= 2 and 
   --       WillKill("rockets", targets[1]) and
   --       WillKill("rockets", targets[2])
   --    then
   --       Cast("rockets", me)
   --       PrintAction("Rockets for lasthit")
   --       return true
   --    end
   -- end

   if IsOn("lasthit") then
      if KillMinionsInArea("grenade") then
         return true
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
   -- TestSkillShot("grenade", "Heimerdinger_Base_E_Mis")
   -- TestSkillShot("rockets", nil, {"W_cas"})

   if IsOn("ult") and ( CanUse("upgrade") or P.upgrade ) then

      if CanUse("grenade") then
         spells["grenade"].radius = spells["grenade"].radiusUp
         local hits = GetBestArea(me, "grenade", 1, 0, GetFireaheads("grenade", ENEMIES))
         if #hits >= 2 then
            if not P.upgrade then
               Cast("upgrade", me)
            end
            CastXYZ("grenade", GetAngularCenter(hits))
            PrintAction("Grenade (UPGRADE)", #hits)
            return true
         end
      end

      -- if CanUse("rockets") then
      --    spells["rockets"].noblock = true
      --    local target = GetSkillShot("rockets")
      --    if target then
      --       if not P.upgrade then
      --          Cast("upgrade", me)
      --       end
      --       UseItem("Deathfire Grasp", target)
      --       CastFireahead("rockets", target)
      --       PrintAction("Rockets (UPGRADE)", target)
      --       return true
      --    end
      -- end

   end

   if SkillShot("grenade") then
      PersistTemp("grenade", 1)
      return true
   end

   if not CanUse("grenade") and not P.grenade then
      if SkillShot("rockets") then
         return true
      end
   end

   if P.parts then
      if SkillShot("turret") then
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
   return false
end

local function onObject(object)
   PersistBuff("upgrade", object, "Heimerdinger_Base_R_Beam.troy")
   PersistAll("sentry", object, "H-28G Evolution Turret")
   PersistBuff("parts", object, "Heimer_Q_Ammo")
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")
