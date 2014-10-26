require "issuefree/basicUtils"
require "issuefree/telemetry"

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

      -- Ashe         = { projSpeed = 2.0, windup = .25,
      --                  extraRange = 0,
      --                  minMoveTime = .25,
      --                  particles = {"Ashe_Base_BA_mis", "Ashe_Base_Q_mis"},
      --                  attacks = {"attack", "frostarrow"} },

local windup = .4  -- this is the slowest I've seen. Shouldn't ever clip with this but not the most responsive.
local minMoveTime = .1

function GetAARange(target)
   target = target or me
   local range = target.range + ( aaData.extraRange or 0)
   return range
end

function IsMelee(target)
   return GetAARange(target) < 400
end

local function getAAData()
   local champData = { 
      Ahri         = { projSpeed = 1.6,
                       particles = {"Ahri_BasicAttack_mis"} },

      JarvanIV     = { 
                       attacks={"JarvanIVBasicAttack"} },

      Jayce        = { projSpeed = 2.2,
                       particles = {"Jayce_Range_Basic_mis", "Jayce_Range_Basic_Crit"} },

      Karma        = { projSpeed = nil,
                       particles = {"karma_basicAttack_cas", "karma_basicAttack_mis", "karma_crit_mis"} },


      MissFortune  = { projSpeed = 2.0, windup=.25,
                       particles = {"missFortune_basicAttack_mis", "missFortune_crit_mis"} },

      Mordekaiser  = { windup=.3,
                       resets = {me.SpellNameQ}},

      Olaf         = { windup=.35,
                       minMoveTime=0,
                     },

      Orianna      = { projSpeed = 1.4,
                       particles = {"OrianaBasicAttack_mis", "OrianaBasicAttack_tar"} },

      Quinn        = { projSpeed = 1.85,  --Quinn's critical attack has the same particle name as his basic attack.
                       particles = {"Quinn_basicattack_mis", "QuinnValor_BasicAttack_01", "QuinnValor_BasicAttack_02", "QuinnValor_BasicAttack_03", "Quinn_W_mis"} },

      Shyvana      = { 
                       resets = {me.SpellNameQ} },

      Sivir        = { projSpeed = 1.4, windup=.15,
                       resets = {me.SpellNameW},
                       particles = {"sivirbasicattack_mis", "sivirbasicattack2_mis", "SivirRicochetAttack_mis"} },

      Syndra       = { projSpeed = 1.2,
                       particles = {"Syndra_attack_hit", "Syndra_attack_mis"} },

      TwistedFate  = { projSpeed = 1.5, windup=.4,
                       particles = {"TwistedFateBasicAttack_mis", "TwistedFateStackAttack_mis", "PickaCard_blue", "PickaCard_red", "PickaCard_yellow"} },

      Veigar       = { projSpeed = 1.05,
                       particles = {"permission_basicAttack_mis"} },

      Viktor       = { projSpeed = 2.25,
                       particles = {"ViktorBasicAttack"} },

      XinZhao      = { windup=.35,
                       particles={"xen_ziou_intimidate"},
                       resets={me.SpellNameQ}, },

      Ziggs        = { projSpeed = 1.5,
                       particles = {"ZiggsBasicAttack_mis", "ZiggsPassive_mis"} },

      Zilean       = { projSpeed = 1.25,
                       particles = {"ChronoBasicAttack_mis"} },

   }

   return champData[me.name] or {}
end

function InitAAData(data)
   if data then
      aaData = data
   else
      aaData = getAAData()
   end

   if IsMelee(me) then
      aaData.melee = true
   end   

   aaData.windup = aaData.windup or windup
   aaData.minMoveTime = aaData.minMoveTime or minMoveTime

   aaData.particles = aaData.particles or {}
   aaData.attacks = aaData.attacks or {"attack"}
   aaData.resets = aaData.resets or {}

   table.insert(aaData.resets, "ItemTiamatCleave") -- TODO verify this spell name
   -- TODO check if tiamat and hydra use the same spellname and reset name
   -- TOOD check for other attack reset items

   if not aaData.duration then
      aaData.duration = 1/me.baseattackspeed
      aaData.duration = aaData.duration*.95
   end

end

function getAttackSpeed()
   return me.attackspeed / me.baseattackspeed
end

function getAADuration()
   return aaData.duration / getAttackSpeed()
end

function getWindup()
   return aaData.windup / math.max(1, getAttackSpeed()*.9)^2 -- err a bit on the side of don't clip
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

InitAAData()
local lastAttack = 0 -- last time I cast an attack
shotFired = true -- have I seen the projectile or waited long enough that it should show

-- debug stuff
local attackState = 0
local attackStates = {"canAttack", "isAttacking", "justAttacked", "canAct", "canMove"}
local lastAAState = 0

local lastAADelta = getAADuration()


local ignoredObjects = {"Minion", "PurpleWiz", "BlueWiz", "DrawFX", "issuefree", "Cursor_MoveTo", "Mfx", "yikes", "glow", "XerathIdle"}
local aaObjects = {}
local aaObjectTime = {}

local testDurs = {}
local testWUs = {}

local estimatedDuration = aaData.duration
local estimatedWU = aaData.windup

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
   -- PrintState(23, aaData.windup)
   -- PrintState(24, getWindup())

   -- we asked for an attack but it's been longer than the windup and we haven't gotten a shot so we must have clipped or something
   if not shotFired and time() - lastAttack > getWindup() then
      shotFired = true
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
         pp("No object. Windup "..aaData.windup.." too short. Incrementing")
         for wu,_ in ipairs(windups) do
            if wu <= aaData.windup then
               windups[wu] = windups[wu] - 5
               if windups[wu] < 1 then
                  windups[wu] = nil
               end
            end
         end

         aaData.windup = aaData.windup + .01
         gotObj = true
      end

      -- AARate is how long to wait between attacks. 
      --  This should be less than actual delta (try not to wait too long some wiggle room here) 
      --  but close to it (don't stop doing other things before I should attack)
      -- Windup is how long between I cast the attack and the actual attack.
      --  This MUST be greater than the actual windup (don't clip attacks)
      --  but close to it (don't wait too long to do other things)
      
      local aarstr = "AARate "..trunc(getAADuration()).." ("..trunc(lastAADelta)..") - "..trunc(estimatedDuration, 3)
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
   return not shotFired or
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
   if not aaData.minMoveTime then
      return CanAct()
   end
   if time() - lastAttack > aaData.minMoveTime then
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
   if ListContains(object.charName, aaData.particles) 
      and GetDistance(object) < GetWidth(me)+250
   then
      -- shotFired = true -- TODO for now this is timing based. ignore particles

      if time() - lastAttack > 2 then
         pp("Got a weird object "..object.charName)
      end

      if ModuleConfig.aaDebug then
         gotObj = true
         pp("Windup "..aaData.windup.." good. Decrementing.")
         if windups[aaData.windup] then
            windups[aaData.windup] = windups[aaData.windup] + 1
         else
            windups[aaData.windup] = 1
         end
         for wu,count in pairs(windups) do
            pp(wu.." "..count)
         end
         aaData.windup = aaData.windup - .01

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
            not ListContains(object.charName, aaData.particles)
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

   local spellName = aaData.attacks
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
   local spellName = aaData.resets
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
