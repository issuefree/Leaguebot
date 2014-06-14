require "issuefree/basicUtils"
require "issuefree/telemetry"

local minAttackTime = .4
local meleeRange = 100+15

local ping = 50
local latency = ping * 2 / 1000

function GetAARange()
  return me.range + meleeRange
end

function initAAData()
   local champData = {  
      Ahri         = { projSpeed = 1.6,
                       aaParticles = {"Ahri_BasicAttack_mis", "Ahri_BasicAttack_tar"}, 
                       aaSpellName = {"attack"} },

      Anivia       = { projSpeed = 1.05,
                       aaParticles = {"cryo_BasicAttack"},
                       aaSpellName = {"attack"} },

      Annie        = { projSpeed = 1.0, windup = .33,
                       aaParticles = {"annie_basicattack"},
                       aaSpellName = {"attack"} },

      Ashe         = { projSpeed = 2.0, windup = .31,
                       aaParticles = {"bowmaster", "Ashe_Base_BA_mis"},
                       aaSpellName = {"attack", "frostarrow"} },

      Brand        = { projSpeed = 1.975,
                       aaParticles = {"BrandBasicAttack_cas", "BrandBasicAttack_Frost_tar", "BrandBasicAttack_mis", "BrandBasicAttack_tar", "BrandCritAttack_mis", "BrandCritAttack_tar", "BrandCritAttack_tar"},
                       aaSpellName = {"attack"} },

      Caitlyn      = { projSpeed = 2.5, speed=1,
                       aaParticles = {"caitlyn_Base_mis", "caitlyn_Base_passive"},
                       aaSpellName = {"attack", "CaitlynHeadshotMissile"} },

      Cassiopeia   = { projSpeed = 1.22,
                       aaParticles = {"CassBasicAttack_mis"},
                       aaSpellName = {"attack"} },

      Corki        = { projSpeed = 2.0,
                       aaParticles = {"corki_basicAttack_mis", "Corki_crit_mis"},
                       aaSpellName = {"attack"} },

      Draven       = { projSpeed = 1.4,
                       aaParticles = {"Draven_BasicAttack_mis","Draven_Q_mis", "Draven_Q_mis_bloodless", "Draven_Q_mis_shadow", "Draven_Q_mis_shadow_bloodless", "Draven_Qcrit_mis", "Draven_Qcrit_mis_bloodless", "Draven_Qcrit_mis_shadow", "Draven_Qcrit_mis_shadow_bloodless", "Draven_BasicAttack_mis_shadow", "Draven_BasicAttack_mis_shadow_bloodless", "Draven_BasicAttack_mis_bloodless", "Draven_crit_mis", "Draven_crit_mis_shadow_bloodless", "Draven_crit_mis_bloodless", "Draven_crit_mis_shadow", "Draven_Q_mis", "Draven_Qcrit_mis"},
                       aaSpellName = {"attack"} },

      Ezreal       = { projSpeed = 2.0, windup = .29,
                       aaParticles = {"Ezreal_basicattack_mis", "Ezreal_critattack_mis"},
                       aaSpellName = {"attack"} },

      FiddleSticks = { projSpeed = 1.75,
                       aaParticles = {"FiddleSticks_cas", "FiddleSticks_mis", "FiddleSticksBasicAttack_tar"},
                       aaSpellName = {"attack"} },

      Graves       = { projSpeed = 3.0, windup=.23,
                       aaParticles = {"Graves_BasicAttack_mis"},
                       aaSpellName = {"attack"} },

      Heimerdinger = { projSpeed = 1.4,
                       aaParticles = {"heimerdinger_basicAttack_mis", "heimerdinger_basicAttack_tar"},
                       aaSpellName = {"attack"} },

      Janna        = { projSpeed = 1.2,
                       aaParticles = {"JannaBasicAttack_mis", "JannaBasicAttack_tar", "JannaBasicAttackFrost_tar"},
                       aaSpellName = {"attack"} },

      Jayce        = { projSpeed = 2.2,
                       aaParticles = {"Jayce_Range_Basic_mis", "Jayce_Range_Basic_Crit"},
                       aaSpellName = {"attack"} },

      Jinx         = { projSpeed = 2.4,
                       aaParticles = {"Jinx_Q_Minigun_Mis", "Jinx_Q_Rocket_mis"},
                       aaSpellName = {"attack"} },

      Karma        = { projSpeed = nil,
                       aaParticles = {"karma_basicAttack_cas", "karma_basicAttack_mis", "karma_crit_mis"},
                       aaSpellName = {"attack"} },

      Karthus      = { projSpeed = 1.25,
                       aaParticles = {"LichBasicAttack_cas", "LichBasicAttack_glow", "LichBasicAttack_mis", "LichBasicAttack_tar"},
                       aaSpellName = {"attack"} },

      Kayle        = { projSpeed = 1.8,
                       aaParticles = {"RighteousFury_nova"},
                       aaSpellName = {"attack"} },

      Kennen       = { projSpeed = 1.35,
                       aaParticles = {"KennenBasicAttack_mis"},
                       aaSpellName = {"attack"} },

      KogMaw       = { projSpeed = 1.8,
                       aaParticles = {"KogMawBasicAttack", "KogMawBioArcaneBarrage"},
                       aaSpellName = {"attack"} },

      Leblanc      = { projSpeed = 1.7,
                       aaParticles = {"leBlanc_basicAttack_cas", "leBlancBasicAttack_mis"},
                       aaSpellName = {"attack"} },

      Lulu         = { projSpeed = 2.5,
                       aaParticles = {"lulu_attack_cas", "LuluBasicAttack", "LuluBasicAttack_tar"},
                       aaSpellName = {"attack"} },

      Lux          = { projSpeed = 1.55,
                       aaParticles = {"LuxBasicAttack"},
                       aaSpellName = {"attack"} },

      Malzahar     = { projSpeed = 1.5,
                       aaParticles = {"AlzaharBasicAttack_cas", "AlZaharBasicAttack_mis"},
                       aaSpellName = {"attack"} },

      MissFortune  = { projSpeed = 2.0,
                       aaParticles = {"missFortune_basicAttack_mis", "missFortune_crit_mis"},
                       aaSpellName = {"attack"} },

      Morgana      = { projSpeed = 1.6,
                       aaParticles = {"FallenAngelBasicAttack_mis", "FallenAngelBasicAttack_tar", "FallenAngelBasicAttack2_mis"},
                       aaSpellName = {"attack"} },

      Nidalee      = { projSpeed = 1.7,
                       aaParticles = {"nidalee_javelin_mis"},
                       aaSpellName = {"attack"} },

      Orianna      = { projSpeed = 1.4,
                       aaParticles = {"OrianaBasicAttack_mis", "OrianaBasicAttack_tar"},
                       aaSpellName = {"attack"} },

      Quinn        = { projSpeed = 1.85,  --Quinn's critical attack has the same particle name as his basic attack.
                       aaParticles = {"Quinn_basicattack_mis", "QuinnValor_BasicAttack_01", "QuinnValor_BasicAttack_02", "QuinnValor_BasicAttack_03", "Quinn_W_mis"},
                       aaSpellName = {"attack"} },

      Ryze         = { projSpeed = 2.4,
                       aaParticles = {"ManaLeach_mis"},
                       aaSpellName = {"attack"} },

      Sivir        = { projSpeed = 1.4,
                       aaParticles = {"sivirbasicattack_mis", "sivirbasicattack2_mis", "SivirRicochetAttack_mis"},
                       aaSpellName = {"attack"} },

      Sona         = { projSpeed = 1.6,
                       aaParticles = {"SonaBasicAttack_mis", "SonaBasicAttack_tar", "SonaCritAttack_mis", "SonaPowerChord_AriaofPerseverance_mis", "SonaPowerChord_AriaofPerseverance_tar", "SonaPowerChord_HymnofValor_mis", "SonaPowerChord_HymnofValor_tar", "SonaPowerChord_SongOfSelerity_mis", "SonaPowerChord_SongOfSelerity_tar", "SonaPowerChord_mis", "SonaPowerChord_tar"},
                       aaSpellName = {"attack"} },

      Soraka       = { projSpeed = 1.0,
                       aaParticles = {"SorakaBasicAttack_mis", "SorakaBasicAttack_tar"},
                       aaSpellName = {"attack"} },

      Swain        = { projSpeed = 1.6,
                       aaParticles = {"swain_basicAttack_bird_cas", "swain_basicAttack_cas", "swainBasicAttack_mis"},
                       aaSpellName = {"attack"} },

      Syndra       = { projSpeed = 1.2,
                       aaParticles = {"Syndra_attack_hit", "Syndra_attack_mis"},
                       aaSpellName = {"attack"} },

      Teemo        = { projSpeed = 1.3,
                       aaParticles = {"TeemoBasicAttack_mis", "Toxicshot_mis"},
                       aaSpellName = {"attack"} },

      Tristana     = { projSpeed = 2.25, windup = .22,
                       aaParticles = {"TristannaBasicAttack_mis"},
                       aaSpellName = {"attack"} },

      TwistedFate  = { projSpeed = 1.5,
                       aaParticles = {"TwistedFateBasicAttack_mis", "TwistedFateStackAttack_mis"},
                       aaSpellName = {"attack"} },

      Twitch       = { projSpeed = 2.5,
                       aaParticles = {"twitch_basicAttack_mis",--[[ "twitch_punk_sprayandPray_tar", "twitch_sprayandPray_tar",]] "twitch_sprayandPray_mis"},
                       aaSpellName = {"attack"} },

      Urgot        = { projSpeed = 1.3,
                       aaParticles = {"UrgotBasicAttack_mis"},
                       aaSpellName = {"attack"} },

      Vayne        = { projSpeed = 2.0, windup = .2666,
                       aaParticles = {"vayne_basicAttack_mis", "vayne_critAttack_mis", "vayne_ult_mis" },
                       aaSpellName = {"attack"} },

      Varus        = { projSpeed = 2.0,
                       aaParticles = {},
                       aaSpellName = {"attack"} }, --varusemissiledummy?

      Veigar       = { projSpeed = 1.05,
                       aaParticles = {"permission_basicAttack_mis"},
                       aaSpellName = {"attack"} },

      Viktor       = { projSpeed = 2.25,
                       aaParticles = {"ViktorBasicAttack_cas", "ViktorBasicAttack_mis", "ViktorBasicAttack_tar"},
                       aaSpellName = {"attack"} },

      Vladimir     = { projSpeed = 1.4,
                       aaParticles = {"VladBasicAttack_mis", "VladBasicAttack_mis_bloodless", "VladBasicAttack_tar", "VladBasicAttack_tar_bloodless"},
                       aaSpellName = {"attack"} },

      Xerath       = { projSpeed = 1.2,
                       aaParticles = {"XerathBasicAttack_mis", "XerathBasicAttack_tar"},
                       aaSpellName = {"attack"} },

      Ziggs        = { projSpeed = 1.5,
                       aaParticles = {"ZiggsBasicAttack_mis", "ZiggsPassive_mis"},
                       aaSpellName = {"attack"} },

      Zilean       = { projSpeed = 1.25,
                       aaParticles = {"ChronoBasicAttack_mis"},
                       aaSpellName = {"attack"} },

      Zyra         = { projSpeed = 1.7,
                       aaParticles = {"Zyra_basicAttack"},
                       aaSpellName = {"attack"} },


      Amumu        = { melee=true,
                       aaParticles = {"SadMummyBasicAttack"} },
      
      Blitzcrank   = { melee=true },

      Elise        = { melee=true,
                       aaParticles = {"Elise_spider_basicattack", "Elise_human_BasicAttack_mis"} },

      Garen        = { melee=true,
                       aaParticles = {"Garen_Base_AA_Tar"}},

      JarvanIV     = { melee=true,
                       aaSpellName={"JarvanIVBasicAttack"} },

      Jax          = { melee=true,
                       aaParticles = {"RelentlessAssault_tar", "EmpowerTwoHit"},
                       aaSpellName={"JaxEmpower", "JaxBasicAttack", "JaxCritAttack", "jaxrelentless"} },

      LeeSin       = { melee=true,
                       aaSpellName={"attack"} },

      Leona        = { melee=true,
                       aaParticles={"leona_basicattack_hit"},
                       aaSpellName={"attack"} },

      MasterYi     = { melee=true,
                       aaParticles = {"Wuju_Trail"} },

      Nasus        = { melee=true,
                       aaParticles = {"nassus_siphonStrike_tar"} },

      Olaf         = { melee=true, windup=.33

                      },

      Poppy        = { melee=true,
                       aaParticles = {"Poppy_DevastatingBlow"} },                       

      Tryndamere   = { melee=true,
                       aaParticles = {"tryndamere_weapontrail"},
                       aaSpellName = {"attack", "Bloodlust"} },

      Warwick      = { melee=true }
   }

   aaData = champData[me.name]
   if not aaData then
      if GetAARange() == me.range + meleeRange then      
         aaData = { melee=true }
      end
   end
   if not aaData.aaParticles then
      aaData.aaParticles = {}
      -- aaData.aaParticles = {"globalhit_bloodslash"}
   end
   if not aaData.aaSpellName then
     aaData.aaSpellName = {"attack"}
   end
   table.insert(aaData.aaSpellName, "ItemTiamatCleave")

   if not aaData.windup then
      aaData.windup = .33
   end
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
   return aaData.windup / getAttackSpeed()
end

initAAData()
local lastAttack = 0 -- last time I cast an attack
local shotFired = true -- have I seen the projectile or waited long enough that it should show

-- debug stuff
local attackState = 0
local attackStates = {"canAttack", "isAttacking", "justAttacked", "canAct", "canMove"}
local lastAAState = 0

local lastAADelta = getAADuration()
local lastWUDelta = getWindup()


local ignoredObjects = {"Minion", "PurpleWiz", "BlueWiz", "DrawFX", "issuefree", "Cursor_MoveTo", "Mfx", "yikes"}
local aaObjects = {}

local testDurs = {}
local testWUs = {}

local estimatedDuration = aaData.duration
local estimatedWU = aaData.windup


function aaTick()
   -- we asked for an attack but it's been longer than the windup and we haven't gotten a shot so we must have clipped or something
   if not shotFired and time() - lastAttack > getWindup() then
      -- I'm not sure if I need this
      -- if not aaData.melee then -- ranged folks start their cast from out of range so this prevents weirdness
      --    lastAttack = time()
      -- end 

      if ModuleConfig.aaDebug then
         pp("< -- Potential clip -- >")
      end

      shotFired = true
   end

   if ModuleConfig.aaDebug then
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


      local wustr = "Windup "..trunc(getWindup()).." ("..trunc(lastWUDelta)..") - "..trunc(estimatedWU, 3)
      if getWindup() < lastWUDelta then
         wustr = wustr.."!!!"
      end

      PrintState(1, aarstr) 
      PrintState(2, wustr)

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

      for i = 1, objManager:GetMaxObjects(), 1 do
         local object = objManager:GetObject(i)
         if object and object.x and object.charName and
            GetDistance(object, me) < 100 
         then
            if not ListContains(object.charName, ignoredObjects) and
               not ListContains(object.charName, aaObjects)
            then
               table.insert(aaObjects, object.charName)
            end
         end
      end

      PrintState(10, "AA Objects")
      for i,ocn in ipairs(aaObjects) do
         PrintState(10+i, ocn)
      end
   end
end

function ResetAttack()
   lastAttack = time() - getAADuration()
end

function CanAttack()
   return time() + latency > getNextAttackTime()
end

function IsAttacking()
   return not shotFired or
          time() + latency < lastAttack + getWindup()
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
   return CanAct()
end   

function getNextAttackTime()
   return lastAttack + getAADuration()
end

function setAttackState(state)
   if attackState == 0 and state == 0 then
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
      if state == 2 then
         lastWUDelta = delta
      end

      if state == 0 then
         lastAAState = time()
      end

      pp(state.." "..trunc(delta).." "..attackStates[attackState+1])

   end
end

function onObjAA(object)
   if ListContains(object.charName, aaData.aaParticles) 
      and GetDistance(object) < GetWidth(me)+150
   then
      if ModuleConfig.aaDebug then
         local delta = time() - lastAAState
         pp("AAP: "..trunc(delta).." "..object.charName)

         lastWUDelta = time() - lastAttack
         trackWindup(lastWUDelta)
      end

      shotFired = true
   end
end

function IAttack(unit, spell)
   if not unit or not IsMe(unit) then
      return false
   end

   local spellName = aaData.aaSpellName
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

function trackAADuration()
   local testDur = lastAADelta*getAttackSpeed()

   if testDur < 2.25 then
      table.insert(testDurs, testDur)
   end

   if #testDurs > 0 then
      estimatedDuration = sum(testDurs)/#testDurs
   end
end

function trackWindup()
   local testWU = lastWUDelta*getAttackSpeed()
   table.insert(testWUs, testWU)
   if #testWUs > 0 then
      estimatedWU = sum(testWUs)/#testWUs
   end
end


function onSpellAA(unit, spell)

   if not unit or not IsMe(unit) then
      return false
   end
   
   if IAttack(unit, spell) then

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


      lastAttack = time()
      shotFired = false
   end
end

RegisterLibraryOnCreateObj(onObjAA)
RegisterLibraryOnProcessSpell(onSpellAA)

SetTimerCallback("aaTick")
