require "basicUtils"
require "telemetry"

local minAttackTime = .66
local meleeRange = 100+15

function GetAARange()
  return me.range + meleeRange
end

function GetAAData()
   return {  
      Ahri         = { projSpeed = 1.6, aaParticles = {"Ahri_BasicAttack_mis", "Ahri_BasicAttack_tar"}, aaSpellName = "ahribasicattack", startAttackSpeed = "0.668",  },
      Anivia       = { projSpeed = 1.05, aaParticles = {"cryo_BasicAttack"}, aaSpellName = "aniviabasicattack", startAttackSpeed = "0.625",  },
      Annie        = { projSpeed = 1.0, aaParticles = {"annie_basicattack"}, aaSpellName = "AnnieBasicAttack", startAttackSpeed = "0.579",  },
      Ashe         = { projSpeed = 2.0, aaParticles = {"bowmaster"}, aaSpellName = {"attack", "frostarrow"}, startAttackSpeed = "0.658" },
      Brand        = { projSpeed = 1.975, aaParticles = {"BrandBasicAttack_cas", "BrandBasicAttack_Frost_tar", "BrandBasicAttack_mis", "BrandBasicAttack_tar", "BrandCritAttack_mis", "BrandCritAttack_tar", "BrandCritAttack_tar"}, aaSpellName = "brandbasicattack", startAttackSpeed = "0.625" },
      Caitlyn      = { projSpeed = 2.5, aaParticles = {"caitlyn_passive_mis", "caitlyn_mis"}, aaSpellName = {"CaitlynBasicAttack", "CaitlynHeadshotMissile", "CaitlynPiltoverPeacemaker"}, startAttackSpeed = "0.668", windup=.525, speed=.95 },
      Cassiopeia   = { projSpeed = 1.22, aaParticles = {"CassBasicAttack_mis"}, aaSpellName = "cassiopeiabasicattack", startAttackSpeed = "0.644" },
      Corki        = { projSpeed = 2.0, aaParticles = {"corki_basicAttack_mis", "Corki_crit_mis"}, aaSpellName = "CorkiBasicAttack", startAttackSpeed = "0.658" },
      Draven       = { projSpeed = 1.4, aaParticles = {"Draven_BasicAttack_mis","Draven_Q_mis", "Draven_Q_mis_bloodless", "Draven_Q_mis_shadow", "Draven_Q_mis_shadow_bloodless", "Draven_Qcrit_mis", "Draven_Qcrit_mis_bloodless", "Draven_Qcrit_mis_shadow", "Draven_Qcrit_mis_shadow_bloodless", "Draven_BasicAttack_mis_shadow", "Draven_BasicAttack_mis_shadow_bloodless", "Draven_BasicAttack_mis_bloodless", "Draven_crit_mis", "Draven_crit_mis_shadow_bloodless", "Draven_crit_mis_bloodless", "Draven_crit_mis_shadow", "Draven_Q_mis", "Draven_Qcrit_mis"}, aaSpellName = "dravenbasicattack", startAttackSpeed = "0.679",  },
      Ezreal       = { projSpeed = 2.0, aaParticles = {"Ezreal_basicattack_mis", "Ezreal_critattack_mis"}, aaSpellName = "ezrealbasicattack", startAttackSpeed = "0.625" },
      FiddleSticks = { projSpeed = 1.75, aaParticles = {"FiddleSticks_cas", "FiddleSticks_mis", "FiddleSticksBasicAttack_tar"}, aaSpellName = "fiddlesticksbasicattack", startAttackSpeed = "0.625" },
      Graves       = { projSpeed = 3.0, aaParticles = {"Graves_BasicAttack_mis",}, aaSpellName = "gravesbasicattack", startAttackSpeed = "0.625" },
      Heimerdinger = { projSpeed = 1.4, aaParticles = {"heimerdinger_basicAttack_mis", "heimerdinger_basicAttack_tar"}, aaSpellName = "heimerdingerbasicAttack", startAttackSpeed = "0.625", windup=.575 },
      Janna        = { projSpeed = 1.2, aaParticles = {"JannaBasicAttack_mis", "JannaBasicAttack_tar", "JannaBasicAttackFrost_tar"}, aaSpellName = "jannabasicattack", startAttackSpeed = "0.625" },
      Jayce        = { projSpeed = 2.2, aaParticles = {"Jayce_Range_Basic_mis", "Jayce_Range_Basic_Crit"}, aaSpellName = "jaycebasicattack", startAttackSpeed = "0.658",  },
      Jinx         = { projSpeed = 2.4, aaParticles = {"Jinx_Q_Minigun_Mis", "Jinx_Q_Rocket_mis"}, startAttackSpeed = "0.625" },
      Karma        = { projSpeed = nil, aaParticles = {"karma_basicAttack_cas", "karma_basicAttack_mis", "karma_crit_mis"}, aaSpellName = "karmabasicattack", startAttackSpeed = "0.658",  },
      Karthus      = { projSpeed = 1.25, aaParticles = {"LichBasicAttack_cas", "LichBasicAttack_glow", "LichBasicAttack_mis", "LichBasicAttack_tar"}, aaSpellName = "karthusbasicattack", startAttackSpeed = "0.625" },
      Kayle        = { projSpeed = 1.8, aaParticles = {"RighteousFury_nova"}, aaSpellName = "KayleBasicAttack", startAttackSpeed = "0.638",  }, -- Kayle doesn't have a particle when auto attacking without E buff..
      Kennen       = { projSpeed = 1.35, aaParticles = {"KennenBasicAttack_mis"}, aaSpellName = "kennenbasicattack", startAttackSpeed = "0.690" },
      KogMaw       = { projSpeed = 1.8, aaParticles = {"KogMawBasicAttack", "KogMawBioArcaneBarrage"}, aaSpellName = {"kogmawbasicattack", "KogMawBioArcaneBarrageAttack"}, startAttackSpeed = "0.665", },
      Leblanc      = { projSpeed = 1.7, aaParticles = {"leBlanc_basicAttack_cas", "leBlancBasicAttack_mis"}, aaSpellName = "leblancbasicattack", startAttackSpeed = "0.625" },
      Lulu         = { projSpeed = 2.5, aaParticles = {"lulu_attack_cas", "LuluBasicAttack", "LuluBasicAttack_tar"}, aaSpellName = "LuluBasicAttack", startAttackSpeed = "0.625" },
      Lux          = { projSpeed = 1.55, aaParticles = {"LuxBasicAttack"}, aaSpellName = "luxbasicattack", startAttackSpeed = "0.625" },
      Malzahar     = { projSpeed = 1.5, aaParticles = {"AlzaharBasicAttack_cas", "AlZaharBasicAttack_mis"}, aaSpellName = "malzaharbasicattack", startAttackSpeed = "0.625" },
      MissFortune  = { projSpeed = 2.0, aaParticles = {"missFortune_basicAttack_mis", "missFortune_crit_mis"}, aaSpellName = "missfortunebasicattack", startAttackSpeed = "0.656", windup=.48 },
      Morgana      = { projSpeed = 1.6, aaParticles = {"FallenAngelBasicAttack_mis", "FallenAngelBasicAttack_tar", "FallenAngelBasicAttack2_mis"}, aaSpellName = "Morganabasicattack", startAttackSpeed = "0.579" },
      Nidalee      = { projSpeed = 1.7, aaParticles = {"nidalee_javelin_mis"}, aaSpellName = "nidaleebasicattack", startAttackSpeed = "0.670" },
      Orianna      = { projSpeed = 1.4, aaParticles = {"OrianaBasicAttack_mis", "OrianaBasicAttack_tar"}, aaSpellName = "oriannabasicattack", startAttackSpeed = "0.658" },
      Quinn        = { projSpeed = 1.85, aaParticles = {"Quinn_basicattack_mis", "QuinnValor_BasicAttack_01", "QuinnValor_BasicAttack_02", "QuinnValor_BasicAttack_03", "Quinn_W_mis"}, aaSpellName = "QuinnBasicAttack", startAttackSpeed = "0.668" },  --Quinn's critical attack has the same particle name as his basic attack.
      Ryze         = { projSpeed = 2.4, aaParticles = {"ManaLeach_mis"}, aaSpellName = {"RyzeBasicAttack"}, startAttackSpeed = "0.625", windup=.55 },
      Sivir        = { projSpeed = 1.4, aaParticles = {"sivirbasicattack_mis", "sivirbasicattack2_mis", "SivirRicochetAttack_mis"}, aaSpellName = "sivirbasicattack", startAttackSpeed = "0.658" },
      Sona         = { projSpeed = 1.6, aaParticles = {"SonaBasicAttack_mis", "SonaBasicAttack_tar", "SonaCritAttack_mis", "SonaPowerChord_AriaofPerseverance_mis", "SonaPowerChord_AriaofPerseverance_tar", "SonaPowerChord_HymnofValor_mis", "SonaPowerChord_HymnofValor_tar", "SonaPowerChord_SongOfSelerity_mis", "SonaPowerChord_SongOfSelerity_tar", "SonaPowerChord_mis", "SonaPowerChord_tar"}, aaSpellName = "sonabasicattack", startAttackSpeed = "0.644" },
      Soraka       = { projSpeed = 1.0, aaParticles = {"SorakaBasicAttack_mis", "SorakaBasicAttack_tar"}, aaSpellName = "sorakabasicattack", startAttackSpeed = "0.625" },
      Swain        = { projSpeed = 1.6, aaParticles = {"swain_basicAttack_bird_cas", "swain_basicAttack_cas", "swainBasicAttack_mis"}, aaSpellName = "swainbasicattack", startAttackSpeed = "0.625" },
      Syndra       = { projSpeed = 1.2, aaParticles = {"Syndra_attack_hit", "Syndra_attack_mis"}, aaSpellName = "sorakabasicattack", startAttackSpeed = "0.625",  },
      Teemo        = { projSpeed = 1.3, aaParticles = {"TeemoBasicAttack_mis", "Toxicshot_mis"}, aaSpellName = {"teemobasicattack", "ToxicShotAttack"}, startAttackSpeed = "0.690" },
      Tristana     = { projSpeed = 2.25, aaParticles = {"TristannaBasicAttack_mis"}, aaSpellName = "tristanabasicattack", startAttackSpeed = "0.656", windup=.45 },
      TwistedFate  = { projSpeed = 1.5, aaParticles = {"TwistedFateBasicAttack_mis", "TwistedFateStackAttack_mis"}, aaSpellName = "twistedfatebasicattack", startAttackSpeed = "0.651",  },
      Twitch       = { projSpeed = 2.5, aaParticles = {"twitch_basicAttack_mis",--[[ "twitch_punk_sprayandPray_tar", "twitch_sprayandPray_tar",]] "twitch_sprayandPray_mis"}, aaSpellName = "twitchbasicattack", startAttackSpeed = "0.679" },
      Urgot        = { projSpeed = 1.3, aaParticles = {"UrgotBasicAttack_mis"}, aaSpellName = "urgotbasicattack", startAttackSpeed = "0.644" },
      Vayne        = { projSpeed = 2.0, aaParticles = {"vayne_basicAttack_mis", "vayne_critAttack_mis", "vayne_ult_mis" }, aaSpellName = "vaynebasicattack", startAttackSpeed = "0.658",  },
      Varus        = { projSpeed = 2.0, aaParticles = {"Attack"}, aaSpellName = "basic", startAttackSpeed = "0.658",  },
      Veigar       = { projSpeed = 1.05, aaParticles = {"permission_basicAttack_mis"}, aaSpellName = "veigarbasicattack", startAttackSpeed = "0.625" },
      Viktor       = { projSpeed = 2.25, aaParticles = {"ViktorBasicAttack_cas", "ViktorBasicAttack_mis", "ViktorBasicAttack_tar"}, aaSpellName = "viktorbasicattack", startAttackSpeed = "0.625" },
      Vladimir     = { projSpeed = 1.4, aaParticles = {"VladBasicAttack_mis", "VladBasicAttack_mis_bloodless", "VladBasicAttack_tar", "VladBasicAttack_tar_bloodless"}, aaSpellName = "vladimirbasicattack", startAttackSpeed = "0.658" },
      Xerath       = { projSpeed = 1.2, aaParticles = {"XerathBasicAttack_mis", "XerathBasicAttack_tar"}, aaSpellName = "xerathbasicattack", startAttackSpeed = "0.625" },
      Ziggs        = { projSpeed = 1.5, aaParticles = {"ZiggsBasicAttack_mis", "ZiggsPassive_mis"}, aaSpellName = "ziggsbasicattack", startAttackSpeed = "0.656" },
      Zilean       = { projSpeed = 1.25, aaParticles = {"ChronoBasicAttack_mis"}, aaSpellName = "zileanbasicattack" },
      Zyra         = { projSpeed = 1.7, aaParticles = {"Zyra_basicAttack"}, aaSpellName = "attack", startAttackSpeed = "0.625",  },

      Amumu        = { melee=true, aaParticles = {"SadMummyBasicAttack"} },
      Jax          = { melee=true, aaParticles = {"RelentlessAssault_tar", "EmpowerTwoHit"}, aaSpellName={"JaxEmpowerTwo"} },
      Garen        = { melee=true, aaParticles = {"Garen_Base_AA_Tar"}},
      Nasus        = { melee=true, aaParticles = {"nassus_siphonStrike_tar"} },
      Olaf         = { melee=true },
      LeeSin       = { melee=true, aaSpellName={"LeeSinBasic", "LeeSinCrit"} },
      Leona        = { melee=true, aaParticles={"leona_basicattack_hit"}, aaSpellName={"LeonaBasicAttack", "LeonaCritAttack"} },
      Blitzcrank   = { melee=true, windup=.625 },
      MasterYi     = { melee=true, aaParticles = {"Wuju_Trail"}, windup=.525 },
      Tryndamere   = { melee=true, aaParticles = {"tryndamere_weapontrail"}, aaSpellName = {"attack", "Bloodlust"} },
      Warwick      = { melee=true }
   }
end

local aaData = GetAAData()[myHero.name]
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
  aaData.aaSpellName = "attack"
end
if not aaData.windup then
   aaData.windup = .55
end
if not aaData.speed then
   aaData.speed = 1.10
end

function getWindup()
   return math.max(aaData.windup-.325*me.attackspeed, .1)
end
function getAARate()
   return (1 / (me.attackspeed*aaData.speed))
end

local attackState = 0
local attackStates = {"canAttack", "isAttacking", "waitingForAttack", "canAct", "canMove"}
local lastAAState = 0

local lastAADelta = getAARate()
local lastWUDelta = getWindup()

local lastAttack = time() -- last time I cast an attack
local shotFired = true -- have I seen the projectile or waited long enough that it should show


function aaTick()
   -- we asked for an attack but it's been longer than the attackDelayOffset so we must have canceled
   local attackDelayOffset = getWindup()
   if not shotFired and time() - lastAttack > attackDelayOffset then
      if not aaData.melee then -- ranged folks start their cast from out of range so this prevents weirdness
         lastAttack = 0
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
      local aarstr = "AARate "..trunc(getAARate()).." ("..trunc(lastAADelta)..")"
      if getAARate() > lastAADelta then
         aarstr = aarstr.."!!!"
      end
      local wustr = "Windup "..trunc(getWindup()).." ("..trunc(lastWUDelta)..")"
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
      if waitingForAttack() then
         setAttackState(2)
         PrintState(0, "  --")
      end
      if JustAttacked() then
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
   end
end

function CanAttack()
   if time() > getNextAttackTime() then
      return true
   end
   return false
end

function IsAttacking()
   return not shotFired
end

function JustAttacked()
   if shotFired and not CanAttack() then
      return true 
   end
   return false
end

function CanAct()
   if shotFired or CanAttack() then
      return true
   end
   return false
end

-- in testing (with teemo) if I moved between attacks I couldn't attack faster than ~.66
-- since "acting" is more important than attacking we can slow down our AA rate
-- to act but not to move.
function CanMove()
    if not waitingForAttack() or CanAttack() then
        return true
    end
    return false
end   

function waitingForAttack()
   if (1 / me.attackspeed) < minAttackTime and os.clock() - lastAttack < minAttackTime then
      return true
   else
      return not shotFired
   end
end

function getNextAttackTime()
   return lastAttack + (1 / me.attackspeed)
end

function setAttackState(state)
   if attackState == 0 and state == 0 then
      lastAAState = time()
      return
   end
   if attackState == 0 and state >= 3 then      
      return
   end
   if (state == 0 and attackState > 0) or
      state > attackState 
   then
      attackState = state
      local delta = time() - lastAAState
      if state == 0 then
         lastAADelta = delta
      end
      if state == 3 then
         lastWUDelta = delta
      end
      pp(state.." "..trunc(delta).." "..attackStates[attackState+1])
      if state == 0 then
         lastAAState = time()
      end
   end
end

function onObjAA(object)
   if ListContains(object.charName, aaData.aaParticles) 
      and GetDistance(object) < GetSpellRange("AA")+100
   then
      if ModuleConfig.aaDebug then
        local delta = time() - lastAAState
         pp("AAP: "..trunc(delta).." "..object.charName)
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
   -- if (lastSpell and spell.name == lastSpell) or
   --    not ( find(me.SpellNameQ, spell.name) or find(spell.name, me.SpellNameQ) ) and
   --    not ( find(me.SpellNameW, spell.name) or find(spell.name, me.SpellNameW) ) and
   --    not ( find(me.SpellNameE, spell.name) or find(spell.name, me.SpellNameE) ) and
   --    not ( find(me.SpellNameR, spell.name) or find(spell.name, me.SpellNameR) )
   -- then
   --    return true
   -- end

   return false
end

local lastSpell
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


      local delta = time() - lastAAState
      if ModuleConfig.aaDebug then
         local tn = "?"
         if spell.target then
            tn = spell.target.charName
         end
         pp("AAS: "..trunc(delta).." "..spell.name.." -> "..tn)
      end
      setAttackState(0)
      lastAttack = time()
      shotFired = false
   end
   -- lastSpell = spell.name
end

RegisterLibraryOnCreateObj(onObjAA)
RegisterLibraryOnProcessSpell(onSpellAA)

SetTimerCallback("aaTick")
