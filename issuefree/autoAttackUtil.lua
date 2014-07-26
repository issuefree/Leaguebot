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
-- It seems to be generally .2s min. Some characters need slightly more (Ashe).
-- Get some move speed (like 1.5 total) and orbwalk. If it misses some move commands, up the minMoveTime.

-- Particles used to be important but it is all timing based now. May as well throw them in...

      -- Ashe         = { projSpeed = 2.0, windup = .25,
      --                  minMoveTime = .25,
      --                  particles = {"Ashe_Base_BA_mis", "Ashe_Base_Q_mis"},
      --                  attacks = {"attack", "frostarrow"} },

local windup = .4  -- this is the slowest I've seen. Shouldn't ever clip with this but not the most responsive.
local minMoveTime = .2  -- this seems to work for almost everyone.

function GetAARange(target)
   target = target or me
   local range = target.range + 85
   if aaData and aaData.extraRange then
      range = range + aaData.extraRange
   end
   if range < 300 then 
      range = range + 15
   end
   return range
end

function IsMelee(target)
   return GetAARange(target) < 350
end

function initAAData()
   local champData = { 
      Ahri         = { projSpeed = 1.6,
                       particles = {"Ahri_BasicAttack_mis", "Ahri_BasicAttack_tar"} },

      Akali        = { windup = .2 },

      Alistar      = { windup=.25 },

      Amumu        = { windup=.30,
                       particles = {"SadMummyBasicAttack"} },

      Annie        = { windup=.30 }, -- untested

      Chogath      = { windup = .35,
                     particles = {"vorpal_spikes_mis"} },

      DrMundo      = { windup = .2 },

      Elise        = { windup=.25,
                       particles = {"Elise_spider_basicattack", "Elise_human_BasicAttack_mis"} },

      Evelynn      = { windup=.3,
                       particles = {"EvelynnBasicAttack_tar"} },

      Garen        = { windup = .35,
                       extraRange=15,
                       particles = {"Garen_Base_AA_Tar", "Garen_Base_Q_Land"},
                       resets = {"GarenQ"} },

      Anivia       = { projSpeed = 1.05, windup = .4,
                       particles = {"cryoBasicAttack"} },

      Annie        = { projSpeed = 1.0, windup = .35,
                       particles = {"annie_basicattack"} },

      Ashe         = { projSpeed = 2.0, windup = .25, -- can attack faster but seems to mess up move
                       minMoveTime = .25, -- ashe can't get move commands too early for some reason
                       particles = {"Ashe_Base_BA_mis", "Ashe_Base_Q_mis"},
                       attacks = {"attack", "frostarrow"} },
      
      Blitzcrank   = { windup=.3, },

      Brand        = { projSpeed = 1.975, windup=.4,
                       particles = {"BrandBasicAttack", "BrandCritAttack"} },



      Caitlyn      = { projSpeed = 2.5, windup=.2,
                       minMoveTime=0,
                       extraRange=40,
                       particles = {"caitlyn_Base_mis", "caitlyn_Base_passive"},
                       attacks = {"attack", "CaitlynHeadshotMissile"} },

      Cassiopeia   = { projSpeed = 1.22,
                       particles = {"CassBasicAttack_mis"} },

      Corki        = { projSpeed = 2.0, windup=.1, -- !
                       particles = {"corki_basicAttack_mis", "Corki_crit_mis"} },

      Draven       = { projSpeed = 1.4,
                       particles = {"Draven_BasicAttack_mis","Draven_Q_mis", "Draven_Q_mis_bloodless", "Draven_Q_mis_shadow", "Draven_Q_mis_shadow_bloodless", "Draven_Qcrit_mis", "Draven_Qcrit_mis_bloodless", "Draven_Qcrit_mis_shadow", "Draven_Qcrit_mis_shadow_bloodless", "Draven_BasicAttack_mis_shadow", "Draven_BasicAttack_mis_shadow_bloodless", "Draven_BasicAttack_mis_bloodless", "Draven_crit_mis", "Draven_crit_mis_shadow_bloodless", "Draven_crit_mis_bloodless", "Draven_crit_mis_shadow", "Draven_Q_mis", "Draven_Qcrit_mis"} },

      Ezreal       = { projSpeed = 2.0, windup=.2,
                       minMoveTime=0,
                       extraRange=-25,
                       particles = {"Ezreal_basicattack_mis", "Ezreal_critattack_mis"} },

      FiddleSticks = { projSpeed = 1.75, windup=.30,
                       particles = {"FiddleSticks_cas", "FiddleSticks_mis", "FiddleSticksBasicAttack_tar"} },

      Gragas       = { windup=.35 },

      Graves       = { projSpeed = 3.0, windup=.25,
                       particles = {"Graves_BasicAttack_mis"} },

      Heimerdinger = { projSpeed = 1.4,
                       particles = {"heimerdinger_basicAttack_mis", "heimerdinger_basicAttack_tar"} },

      Irelia       = { windup=.3 },

      Janna        = { projSpeed = 1.2,
                       particles = {"JannaBasicAttack_mis", "JannaBasicAttack_tar", "JannaBasicAttackFrost_tar"} },

      JarvanIV     = { 
                       attacks={"JarvanIVBasicAttack"} },

      Jayce        = { projSpeed = 2.2,
                       particles = {"Jayce_Range_Basic_mis", "Jayce_Range_Basic_Crit"} },

      Jax          = { windup=.4,
                       particles = {"RelentlessAssault_tar", "EmpowerTwoHit"},
                       attacks={"JaxBasicAttack", "JaxCritAttack", "jaxrelentless"},
                       resets = {me.SpellNameW} },

      Jinx         = { projSpeed = 2.4, windup=.3,
                       particles = {"Jinx_Q_Minigun_mis", "Jinx_Q_Rocket_mis"} },

      Karma        = { projSpeed = nil,
                       particles = {"karma_basicAttack_cas", "karma_basicAttack_mis", "karma_crit_mis"} },

      Karthus      = { projSpeed = 1.25,
                       particles = {"LichBasicAttack_cas", "LichBasicAttack_glow", "LichBasicAttack_mis", "LichBasicAttack_tar"} },

      Kassadin     = { windup=.2,
                       resets = {me.SpellNameW} },

      Kayle        = { projSpeed = 1.8, windup=.3,
                       particles = {"RighteousFury_nova"} },

      Kennen       = { projSpeed = 1.35,
                       particles = {"KennenBasicAttack_mis"} },

      KogMaw       = { projSpeed = 1.8, windup=.2,
                       particles = {"KogMawBasicAttack", "KogMawBioArcaneBarrage_mis"} },

      Leblanc      = { projSpeed = 1.7, windup=.2,
                       extraRange=-10,
                       particles = {"leBlancBasicAttack_mis"} },

      LeeSin       = { windup=.2, },

      Leona        = { windup=.3,
                       particles={"leona_basicattack_hit"} },

      Lulu         = { projSpeed = 2.5, windup=.2,
                       particles = {"lulu_attack_cas", "LuluBasicAttack", "LuluBasicAttack_tar"} },

      Lux          = { projSpeed = 1.55, windup=.15,
                       particles = {"LuxBasicAttack"} },

      Malzahar     = { projSpeed = 1.5,
                       particles = {"AlzaharBasicAttack_cas", "AlZaharBasicAttack_mis"} },

      MasterYi     = { windup=.25,
                       particles = {"Wuju_Trail"} },

      MissFortune  = { projSpeed = 2.0, windup=.25,
                       particles = {"missFortune_basicAttack_mis", "missFortune_crit_mis"} },

      Mordekaiser  = { windup=.3,
                       resets = {me.SpellNameQ}},

      Morgana      = { projSpeed = 1.6,
                       particles = {"FallenAngelBasicAttack_mis", "FallenAngelBasicAttack_tar", "FallenAngelBasicAttack2_mis"} },

      Nasus        = { windup=.3,
                       particles = {"nassus_siphonStrike_tar"},
                       resets = {me.SpellNameQ} },

      Nidalee      = { projSpeed = 1.7,
                       particles = {"nidalee_javelin_mis"} },

      Olaf         = { windup=.3,
                       minMoveTime=0,
                     },

      Orianna      = { projSpeed = 1.4,
                       particles = {"OrianaBasicAttack_mis", "OrianaBasicAttack_tar"} },

      Poppy        = { windup=.3,
                       particles = {"Poppy_DevastatingBlow"} },                       

      Quinn        = { projSpeed = 1.85,  --Quinn's critical attack has the same particle name as his basic attack.
                       particles = {"Quinn_basicattack_mis", "QuinnValor_BasicAttack_01", "QuinnValor_BasicAttack_02", "QuinnValor_BasicAttack_03", "Quinn_W_mis"} },

      Riven        = { windup=.25,
                       resets = {me.SpellNameQ} },

      Ryze         = { projSpeed = 2.4, windup=.25,
                       particles = {"ManaLeach_mis"} },

      Shyvana      = { 
                       resets = {me.SpellNameQ} },

      Sivir        = { projSpeed = 1.4, windup=.15,
                       resets = {me.SpellNameW},
                       particles = {"sivirbasicattack_mis", "sivirbasicattack2_mis", "SivirRicochetAttack_mis"} },

      Sona         = { projSpeed = 1.6,
                       particles = {"SonaBasicAttack_mis", "SonaBasicAttack_tar", "SonaCritAttack_mis", "SonaPowerChord_AriaofPerseverance_mis", "SonaPowerChord_AriaofPerseverance_tar", "SonaPowerChord_HymnofValor_mis", "SonaPowerChord_HymnofValor_tar", "SonaPowerChord_SongOfSelerity_mis", "SonaPowerChord_SongOfSelerity_tar", "SonaPowerChord_mis", "SonaPowerChord_tar"} },

      Soraka       = { projSpeed = 1.0,
                       particles = {"SorakaBasicAttack_mis", "SorakaBasicAttack_tar"} },

      Swain        = { projSpeed = 1.6,
                       particles = {"swain_basicAttack_bird_cas", "swain_basicAttack_cas", "swainBasicAttack_mis"} },

      Syndra       = { projSpeed = 1.2,
                       particles = {"Syndra_attack_hit", "Syndra_attack_mis"} },

      Teemo        = { projSpeed = 1.3, windup=.25,
                       minMoveTime = 0,
                       extraRange=-20,
                       particles = {"TeemoBasicAttack_mis", "Toxicshot_mis"} },

      Tristana     = { projSpeed = 2.25, windup=.15,
                       particles = {"TristannaBasicAttack_mis"} },

      Tryndamere   = { 
                       particles = {"tryndamere_weapontrail"},
                       attacks = {"attack", "Bloodlust"} },

      TwistedFate  = { projSpeed = 1.5, windup=.4,
                       particles = {"TwistedFateBasicAttack_mis", "TwistedFateStackAttack_mis", "PickaCard_blue", "PickaCard_red", "PickaCard_yellow"} },

      Twitch       = { projSpeed = 2.5, windup = .25,
                       particles = {"twitch_basicAttack_mis", "twitch_sprayandPray_mis"} },

      Urgot        = { projSpeed = 1.3, windup=.2,
                       particles = {"UrgotBasicAttack_mis"} },

      Vayne        = { projSpeed = 2.0, windup=.2, -- !
                       particles = {"vayne_basicAttack_mis", "vayne_critAttack_mis", "vayne_ult_mis" } },

      Varus        = { projSpeed = 2.0, windup=.25,
                       particles = {"Varus_basicAttack_mis"} },

      Veigar       = { projSpeed = 1.05,
                       particles = {"permission_basicAttack_mis"} },

      Viktor       = { projSpeed = 2.25,
                       particles = {"ViktorBasicAttack"} },

      Vladimir     = { projSpeed = 1.4,
                       particles = {"VladBasicAttack"} },

      Warwick      = { windup=.35 },

      Xerath       = { projSpeed = 1.2, windup=.35,
                       attacks = {"XerathBasicAttack"},
                       particles = {"Xerath_Base_BA_mis"} },

      XinZhao      = { windup=.35,
                       particles={"xen_ziou_intimidate"},
                       resets={me.SpellNameQ}, },

      Yorick       = { windup=.30,
                       resets = {me.SpellNameQ} },

      Ziggs        = { projSpeed = 1.5,
                       particles = {"ZiggsBasicAttack_mis", "ZiggsPassive_mis"} },

      Zilean       = { projSpeed = 1.25,
                       particles = {"ChronoBasicAttack_mis"} },

      Zyra         = { projSpeed = 1.7, windup=.25,
                       particles = {"Zyra_basicAttack"} },

   }

   aaData = champData[me.name] or {}

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

initAAData()
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
   -- PrintState(20, me.attackspeed)
   -- PrintState(21, me.baseattackspeed)
   -- PrintState(22, getAttackSpeed())   
   -- PrintState(23, aaData.windup)
   -- PrintState(24, getWindup())

   -- we asked for an attack but it's been longer than the windup and we haven't gotten a shot so we must have clipped or something
   if not shotFired and time() - lastAttack > getWindup() then
      shotFired = true
   end

   if IsMinion(lastAATarget) and not ValidTarget(lastAATarget) and IsAttacking() then
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
      if not gotObj and time() - lastAttack > 1 then
         pp("No object. Windup "..aaData.windup.." too short. Incrementing")
         if windups[aaData.windup] then
            windups[aaData.windup] = windups[aaData.windup] - 2
            if windups[aaData.windup] < 1 then
               windups[aaData.windup] = nil
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


      PrintState(-1, GetAARange())
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

function ResetAttack()
   needMove = false
   lastAttack = time() - getAADuration()
end

function CanAttack()
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
      shotFired = true

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

         if object and object.x and object.charName and
            GetDistance(object, me) < 100 
         then
            if not ListContains(object.charName, ignoredObjects) and
               not ListContains(object.charName, aaObjects)
            then
               if time() - lastAttack < .5 then
                  table.insert(aaObjects, object.charName)
                  table.insert(aaObjectTime, time() - lastAttack)
               end
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
         attackTarget = spell.target
         return true
      end
   else
      if find(spell.name, spellName) then                       
         attackTarget = spell.target
         return true
      end
   end

   return false
end

function trackAADuration()

   pp("APS: "..trunc(1/lastAADelta,2))

   local testDur = lastAADelta*getAttackSpeed()

   if testDur < 2.25 then
      table.insert(testDurs, testDur)
   end

   if #testDurs > 0 then
      estimatedDuration = sum(testDurs)/#testDurs
   end
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
      ResetAttack()
   end

   if IAttack(unit, spell) then
      if ValidTarget(spell.target) then
         lastAATarget = spell.target

         if ModuleConfig.aaDebug then
            pp("AA at distance "..trunc(GetDistance(spell.target)))
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
            AddWillKill(minion)
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
         trackAADuration()         
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
