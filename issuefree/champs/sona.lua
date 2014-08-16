require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Sona")

InitAAData({ 
   projSpeed = 1.6, windup=.2,
   extraRange=-20,
   particles = {"Sona_Base_BA", "PowerChord_mis"}
})

AddToggle("healTeam", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"green"}})
AddToggle("", {on=true, key=113, label=""})
AddToggle("tear", {on=true, key=114, label="Charge Tear / Fastwalk"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "blue"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})


spells["chord"] = {
   base=0,
   lvl={13,20,27,35,43,52,62,72,82,92,102,112,122,132,147,162,177,192},
   ap=.2
}
spells["blue"] = {
   key="Q", 
   range=650, 
   color=blue, 
   base={40,80,120,160,200}, 
   ap=.5
}
spells["valor"] = {
   base={40,50,60,70,80},
   ap=.25,
   bonus=function() 
      base={10,20,30}
      return base[GetSpellLevel("R")]
   end
}
spells["green"] = {
   key="W", 
   range=1000, 
   color=green, 
   base={25,45,65,85,105}, 
   ap=.2,
   damOnTarget=
      function(target)
         if target then
            return GetSpellDamage("green")*(1-GetHPerc(target))
         end
         return 0
      end,
   type="H"
}
spells["shield"] = {
   key="W",
   range=350,
   color=green,
   base={40,60,80,100,120},
   ap=.2,
   bonus=function() 
      base={10,20,30}
      return base[GetSpellLevel("R")]
   end   
}
spells["violet"] = {
   key="E", 
   range=350, 
   color=violet,
   cost=65
}
spells["yellow"] = {
   key="R", 
   range=1000, 
   color=yellow, 
   base={150,250,350}, 
   ap=.5
}


-- TODO track power chord and change AA target depending.

function Run()
   spells["AA"].bonus = 0

   if P.pcBlue or P.pcGreen or P.pcViolet then
      spells["AA"].bonus = GetSpellDamage("chord")
      if P.pcBlue then
         spells["AA"].bonus = spells["AA"].bonus * 1.5
      end
   end

   if P.valor then
      spells["AA"].bonus = spells["AA"].bonus + GetSpellDamage("valor")
   end

   if StartTickActions() then
      return true
   end

   if IsOn("healTeam") and CanUse("green") then
      local closeAllies = SortByHealth(GetInRange(me, "green", ALLIES))
      local target
      for _,ca in ipairs(closeAllies) do
         if not IsMe(ca) and
            not IsRecalling(ca)
         then
            target = ca
            break
         end
      end
      
      if GetMPerc(me) > .9 then
         -- TODO check if there's an OOR heal that I should wait for
         -- else top off
         if target and
            target.health + GetSpellDamage("green", target) < target.maxHealth*.9 or
            me.health + GetSpellDamage("green", me) < me.maxHealth*.9
         then
            Cast("green", me)
            PrintAction("Top off")
            return true
         end
      end

      local score = 0      
      if target then
         if target.health + GetSpellDamage("green", target) < target.maxHealth*.75 then
            score = score + 2
         elseif target.health + GetSpellDamage("green", target) < target.maxHealth*.9 then
            score = score + 1
         end
      end
      if me.health + GetSpellDamage("green", me) < me.maxHealth*.75 then
         score = score + 2
      elseif me.health + GetSpellDamage("green", me) < me.maxHealth*.9 then
         score = score + 1
      end

      if score >= 2 then
         Cast("green", me)
         PrintAction("Heal because I should", score)
         return true
      end

   end

   if HotKey() then
      if Action() then
         return true
      end
   end
   
   if IsOn("lasthit") and Alone() and CanUse("blue") then
      local minionRays = 2
      local targets = SortByDistance(GetInRange(me, "blue", MINIONS))
      for _,minion in ipairs(targets) do
         if minionRays <= 0 then
            break
         end
         if WillKill("blue", minion) then
            Cast("blue", me)
            PrintAction("Blue for lasthit")
            return true
         end
         minionRays = minionRays - 1
      end
   end

   if IsOn("tear") then
      if CanUse("violet") and Alone() then
         if GetDistance(HOME) > 1000 and GetMPerc(me) > .9 then
            Cast("violet", me)
            return true
         elseif CanChargeTear() and GetMPerc(me) > .75 then
            Cast("violet", me)
            return true
         end
      end

      if CanUse("blue") and not CanUse("violet") and VeryAlone() then
         if #GetInRange(me, "blue", CREEPS, MINIONS) == 0 then
            if GetMPerc(me) > .75 and CanChargeTear() then
               Cast("blue", me)
               return true
            end
         end
      end
   end

   EndTickActions()
end

function Action()
   if CanUse("blue") then
      local target = GetWeakestEnemy("blue")
      if target then
         Cast("blue", me)
         PrintAction("Blue", target)
         return true
      end
   end

   if CanUse("violet") and not VeryAlone() and GetMPerc(me) > .5 then
      if #GetInRange(me, "violet", ALLIES) >= 2 then
         Cast("violet", me)
         PrintAction("Violet in teamfight")
         return true
      end
   end

   local target = GetMarkedTarget()
   if not target then
      if P.pcGreen then
         if IsInRange(EADC) then 
            target = EADC
         elseif IsInRange(EAPC) then
            target = EAPC
         end
      end
   end
   if not target then
      if me.selflevel <= 5 or 
         P.pcBlue or 
         P.pcGreen or 
         P.pcViolet or 
         P.valor or
         P.lichbane or
         P.iceborn or
         P.enrage
      then
         target = GetWeakestEnemy("AA")
      end
   end

   if AutoAA(target) then
      return true
   end

end

local function onObject(object)
   if PersistBuff("pcBlue", object, "Sona_Base_Q_PCReady_CoreRings") then
      ResetAttack()
   end
   if PersistBuff("pcGreen", object, "Sona_Base_W_PCReady_CoreRings") then
      ResetAttack()
   end
   if PersistBuff("pcViolet", object, "Sona_Base_E_PCReady_CoreRings") then
      ResetAttack()
   end

   PersistBuff("valor", object, "Sona_Base_Q_Buff.troy")
end

local function onSpell(object, spell)
   if CheckShield("shield", unit, spell, "CHECK") then
      local allies = GetInRange(me, "heal", ALLIES)
      for _,ally in ipairs(allies) do
         if GetHPerc(ally) < .9 then
            Cast("green", me)
            PrintAction("Shield")
            break
         end
      end
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")