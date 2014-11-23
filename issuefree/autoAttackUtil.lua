require "issuefree/basicUtils"
require "issuefree/telemetry"
require "issuefree/spellUtils"

local ping = 50
local latency = ping * 2 / 1000

-- The most important thing is to register attack spells. Nothing works if the attack spell isn't
-- picked up. 90% of the time the attack spell is just the default of "attack" something.
-- There may be additional ones especially if the character has attack mod skills.

-- The next most important thing on here is the windup time.
-- This is measured by setting it very low (.1)
-- turning on the debugger (which stops attack after the timeout)
-- and swinging at something. If it stops the attack the windup is too low.
-- Try several attacks. It should never cancel. 
-- Round up a bit as losing .05s is nothing but clipping the attack is bad.

-- The third thing is the min move time. If you send a move command too soon it doesn't work.
-- Get some attack speed (like 1.5 total) and orbwalk. If it misses some move commands, up the minMoveTime.

-- attack range can also need some tweaking. 

-- Particles used to be important but it is all timing based now. May as well throw them in...

      -- Ashe         = { speed = 2000, windup = .25,
      --                  extraRange = 0,
      --                  minMoveTime = .25,
      --                  particles = {"Ashe_Base_BA_mis", "Ashe_Base_Q_mis"},
      --                  attacks = {"attack", "frostarrow"} },

function GetAARange(target)
   if not target or IsMe(target) then
      return GetSpellRange("AA")
   else
      return target.range
   end
end

function IsMelee(target)
   return GetAARange(target) < 400
end

local minionAAData = {
   basic={
      delay=400,
   },
   caster={
      delay=484, speed=650
   },
   mech={
      delay=365, speed=1200
   },
   turret={
      delay=150, speed=1200
   },
}

-- local function getAAData()
--    local champData = { 
--       Ahri         = { speed = 1600,
--                        particles = {"Ahri_BasicAttack_mis"} },

--       JarvanIV     = { 
--                        attacks={"JarvanIVBasicAttack"} },

--       Jayce        = { speed = 2200,
--                        particles = {"Jayce_Range_Basic_mis", "Jayce_Range_Basic_Crit"} },


--       Orianna      = { speed = 1400,
--                        particles = {"OrianaBasicAttack_mis", "OrianaBasicAttack_tar"} },

--       Quinn        = { speed = 1850,  --Quinn's critical attack has the same particle name as his basic attack.
--                        particles = {"Quinn_basicattack_mis", "QuinnValor_BasicAttack_01", "QuinnValor_BasicAttack_02", "QuinnValor_BasicAttack_03", "Quinn_W_mis"} },

--       Syndra       = { speed = 1200,
--                        particles = {"Syndra_attack_hit", "Syndra_attack_mis"} },

--       Viktor       = { speed = 2250,
--                        particles = {"ViktorBasicAttack"} },

--       Ziggs        = { speed = 1500,
--                        particles = {"ZiggsBasicAttack_mis", "ZiggsPassive_mis"} },

--    }

--    return champData[me.name] or {}
-- end

function InitAAData(data)
   data = data or {}

   spells["AA"].windup = data.windup or .4
   spells["AA"].minMoveTime = data.minMoveTime or .1
   spells["AA"].particles = data.particles or {}
   spells["AA"].attacks = data.attacks or {"attack"}
   spells["AA"].resets = data.resets or {}
   spells["AA"].speed = data.speed

   -- TOOD check for other attack reset items
   table.insert(spells["AA"].resets, "ItemTiamatCleave")

   if not spells["AA"].duration then
      spells["AA"].duration = 1/me.baseattackspeed

      -- err a bit on the side of attack faster
      spells["AA"].duration = spells["AA"].duration*.95
   end
end

function getAttackSpeed()
   return me.attackspeed / me.baseattackspeed
end

function getAADuration()
   return spells["AA"].duration / getAttackSpeed()
end

function getWindup()
   return spells["AA"].windup / math.max(1, getAttackSpeed()*.85)^2 -- err a bit on the side of don't clip
end

function OrbWalk()
   CURSOR = Point(mousePos())
   local targets = SortByDistance(GetInRange(me, "AA", MINIONS, CREEPS, ENEMIES))
   if targets[1] and CanAttack() then
      if AA(targets[1]) then
         return true
      end
   elseif CanMove() then
      MoveToCursor()
   end
end

-- InitAAData()
local lastAttack = 0 -- last time I cast an attack
shotFired = true -- have I seen the projectile

-- debug stuff
local attackState = 0
local attackStates = {"canAttack", "isAttacking", "justAttacked", "canAct", "canMove"}
local lastAAState = 0

-- local lastAADelta = getAADuration()

local ignoredObjects = {"Minion", "DrawFX", "issuefree", "Cursor_MoveTo", "Mfx", "yikes", "glow", "XerathIdle"}
local aaObjects = {}
local aaObjectTime = {}

local testDurs = {}
local testWUs = {}

-- local estimatedWU = spells["AA"].windup

function AfterAttack()
   -- needMove = true
   -- pp("UNBLOCK")
   UnblockOrders()
   if ModuleConfig.aaDebug then
      UnblockOrders()
      StopMove()
   end
end

local gotObj = true
local windups = {}

function aaTick()
   -- PrintState(0, getAADuration())
   -- PrintState(1, 1/getAADuration())

   -- PrintState(20, me.attackspeed)
   -- PrintState(21, me.baseattackspeed)
   -- PrintState(22, getAttackSpeed())   
   -- PrintState(23, spells["AA"].windup)
   -- PrintState(24, getWindup())

   -- we asked for an attack but it's been longer than the windup and we haven't gotten a shot so we must have clipped or something
   if not shotFired and time() - lastAttack > getWindup() then
      woundUp = true
   end

   if CanAttack() or
      ( IsEnemy(lastAATarget) and time() > lastAttack + getWindup()*2 )
   then
      lastAATarget = nil
   end

   if lastAATarget and find(lastAATarget.name, "Minion") and
      not IsValid(lastAATarget) and 
      time() < lastAttack + (getWindup()/2)
   then
      PrintAction("RESET kia")
      lastAATarget = nil
      ResetAttack()
   end

   if CanAttack() then
      canSendAttacked = true
   end
   if JustAttacked() and canSendAttacked then
      AfterAttack()
      canSendAttacked = false
   end

   if ModuleConfig.aaDebug then
      if not IsMelee(me) and not gotObj and time() - lastAttack > 1 then
         pp("No object. Windup "..spells["AA"].windup.." too short. Incrementing")
         for wu,_ in ipairs(windups) do
            if wu <= spells["AA"].windup then
               windups[wu] = windups[wu] - 5
               if windups[wu] < 1 then
                  windups[wu] = nil
               end
            end
         end

         spells["AA"].windup = spells["AA"].windup + .01
         gotObj = true
      end

      -- AARate is how long to wait between attacks. 
      --  This should be less than actual delta (try not to wait too long some wiggle room here) 
      --  but close to it (don't stop doing other things before I should attack)
      -- Windup is how long between I cast the attack and the actual attack.
      --  This MUST be greater than the actual windup (don't clip attacks)
      --  but close to it (don't wait too long to do other things)
      
      local aarstr = "AARate "..trunc(getAADuration()).." ("..trunc(lastAADelta)..") - "..trunc(spells["AA"].duration, 3)
      if getAADuration() > lastAADelta then
         aarstr = aarstr.."!!!"
      end


      PrintState(1, aarstr) 

      if CanAttack() then
         setAttackState(0)
         PrintState(0, "!")
      end
      if IsAttacking() then
         setAttackState(1)
         PrintState(0, "  -")
      end
      if JustAttacked() then
         setAttackState(2)
         PrintState(0, "    :")
      end
      if CanAct() then
         setAttackState(3)
         PrintState(0, "       )")
      end
      if CanMove() then
         setAttackState(4)
         PrintState(0, "         >")
      end

      PrintState(10, "AA Objects")
      for i,ocn in ipairs(aaObjects) do
         PrintState(10+i, ocn.." "..aaObjectTime[i])
      end
   end

end

function ResetAttack(spell)
   needMove = false
   if ModuleConfig.aaDebug then
      if spell and spell.name then
         PrintAction("Reset", spell.name)
      end
   end
   lastAttack = time() - getAADuration()
end

function CanAttack()
   if P.blind then
      return false
   end
   if time() > getNextAttackTime() - latency then
      -- PrintAction("CANATTACK")
   end
   return time() > getNextAttackTime() - latency
end

function IsAttacking()
   return -- not shotFired or -- TODO for now this is timing based. ignore particles
          time() < lastAttack + getWindup()
end

function JustAttacked()
   return not IsAttacking() and 
          not CanAttack()
end

function CanAct()
   return not IsAttacking() or
          CanAttack()
end

-- in testing (with teemo) if I moved between attacks I couldn't attack faster than ~.66
-- since "acting" is more important than attacking we can slow down our AA rate
-- to act but not to move.
function CanMove()
   if not spells["AA"].minMoveTime then
      return CanAct()
   end
   -- the goal with this is to not interrupt attack
   -- What I think is happening is I get in range, throw the attack, the target moves out of aa range
   -- the windup time passes, CanMove enables, I chase.
   -- So if I tried to attack an enemy don't try to move until the AA timer resets rather than the windup is over
   if IsEnemy(lastAATarget) and not IsInAARange(lastAATarget) and not shotFired then
      -- pp("don't abort have target "..lastAATarget.name)      
      return false
   end
   if time() - lastAttack > spells["AA"].minMoveTime then
      return CanAct()
   end
   return false
end   

function getNextAttackTime()
   return lastAttack + getAADuration()
end

function setAttackState(state)
   if attackState == 0 and state == 0 then
      -- pp(debug.traceback())
      lastAAState = time()
      return
   end
   if attackState == 0 and state >= 3 then      
      return
   end

   if (state == 0 and attackState > 0) or -- moving to the next attack state
      state > attackState 
   then
      attackState = state

      local delta = time() - lastAAState

      if state == 0 then
         lastAAState = time()
      end

      pp(state.." "..trunc(delta).." "..attackStates[attackState+1])

   end
end

function onObjAA(object)
   if ListContains(object.charName, spells["AA"].particles) 
      and GetDistance(object) < GetWidth(me)+250
   then
      shotFired = true 

      if time() - lastAttack > 2 then
         pp("Got a weird object "..object.charName)
      end

      if ModuleConfig.aaDebug then
         gotObj = true
         pp("Windup "..spells["AA"].windup.." good. Decrementing.")
         if windups[spells["AA"].windup] then
            windups[spells["AA"].windup] = windups[spells["AA"].windup] + 1
         else
            windups[spells["AA"].windup] = 1
         end
         for wu,count in pairs(windups) do
            pp(wu.." "..count)
         end
         spells["AA"].windup = spells["AA"].windup - .01

         local delta = time() - lastAAState         
         pp("AAP: "..trunc(delta).." "..object.charName)

      end

   end
   if ModuleConfig.aaDebug then
      if object and object.x and object.charName and
         GetDistance(object, me) < 250 
      then
         if not ListContains(object.charName, ignoredObjects) and
            not ListContains(object.charName, aaObjects) and
            not ListContains(object.charName, spells["AA"].particles)
         then         
            if time() - lastAttack < .5 then
               table.insert(aaObjects, object.charName)
               table.insert(aaObjectTime, time() - lastAttack)
               pp(object.charName)
            end
         end
      end
   end

end

function IAttack(unit, spell)
   if not unit or not IsMe(unit) then
      return false
   end

   local spellName = spells["AA"].attacks
   if type(spellName) == "table" then
      if ListContains(spell.name, spellName) then
         return true
      end
   else
      if find(spell.name, spellName) then                       
         return true
      end
   end

   return false
end

function isResetSpell(spell)
   local spellName = spells["AA"].resets
   if not spellName then return false end
   if type(spellName) == "table" then
      if ListContains(spell.name, spellName, true) then
         if ModuleConfig.aaDebug then
            pp("Reset "..spell.name)
         end
         return true
      end
   else
      if find(spell.name, spellName) then                       
         if ModuleConfig.aaDebug then
            pp("Reset "..spell.name)
         end
         return true
      end
   end
   return false
end

lastAATarget = nil

function onSpellAA(unit, spell)

   if unit.team == me.team and IsMinion(unit) and GetDistance(unit) < 1000 then
      if spell.target and IsMinion(spell.target) then
         local delay, speed
         if IsBasicMinion(unit) then
            delay = minionAAData.basic.delay
         elseif IsCasterMinion(unit) then
            delay = minionAAData.caster.delay
            speed = minionAAData.caster.speed
         elseif IsBigMinion(unit) then
            delay = minionAAData.mech.delay
            speed = minionAAData.mech.speed  
         end

         if delay then
            AddIncomingDamage(spell.target, unit.baseDamage+unit.addDamage, GetImpactTime(unit, spell.target, delay, speed))
         end
      end
   end

   if not unit or not IsMe(unit) then
      return false
   end
   
   if isResetSpell(spell) then
      ResetAttack(spell)
   end

   if IAttack(unit, spell) then
      if IsValid(spell.target) then
         lastAATarget = spell.target

         if ModuleConfig.aaDebug then
            gotObj = false
         end

      end

      -- if I attack a minion and I won't kill it try to find an enemy to hit instead.
      -- if I can't hit an enemy try to hit a minion I could kill instead
      if spell.target and IsMinion(spell.target) then
         if not WillKill("AA", spell.target) then
            local target = GetWeakestEnemy("AA")
            if target then
               if AA(target) then
                  PrintAction("Override AA", target)
               end
            else
               KillMinion("AA")
            end
         else
            AddWillKill(minion, "AA")
         end
      end


      if ModuleConfig.aaDebug then
         local delta = time() - lastAAState
         local tn = "?"
         if spell.target then
            tn = spell.target.charName
         end
         pp("AAS: "..trunc(delta).." "..spell.name.." -> "..tn)

         setAttackState(0)
         lastAADelta = time() - lastAttack
      end

      if BLOCK_FOR_AA and Alone() then
         -- pp("BLOCK")
         -- BlockOrders()
      end

      lastAttack = time()
      shotFired = false
   end
end

RegisterLibraryOnCreateObj(onObjAA)
RegisterLibraryOnProcessSpell(onSpellAA)

SetTimerCallback("aaTick")
