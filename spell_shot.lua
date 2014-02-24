--[[

Tim's modified version of...
    Spell Shot Library 1.2 by Chad Chen
    			This script is modified from lopht's skillshots.
    -------------------------------------------------------
            Usage:
            			require "spell_shot"

            			function OnProcessSpell(unit,spell)
            				local spellShot = SpellShotTarget(unit, spell, target)
            				if spellShot then
            					-- spell will hit the target
            				end
            			end
--]]

require "telemetry"
require "walls"

-- "hardness" of the cc
local GRAB = 4
local TAUNT = 4
local STUN = 3
local KNOCK = 3
local FEAR = 3
local BIND = 2
local SLOW = 1
local SILENCE = 1

local spells = {
	Ahri = {
		{name="AhriOrbofDeception", range=880, radius=80, time=1, ss=true, isline=true},
		{name="AhriSeduce", range=975, radius=80, time=1, ss=true, isline=true, cc=TAUNT, nodamage=true},
	},
	Akali = {
		{name="akalimota"},
	},
	Alistar = {
		{name="headbutt", cc=KNOCK},
	},
	Amumu = {
		{name="BandageToss", range=1100, radius=80, time=1, ss=true, isline=true, cc=STUN},
	},
	Annie = {
		{name="Disintegrate", key="Q", cc=STUN},
		{name="InfernalGuardian", key="R", range=600, perm=true, cc=STUN},
	},
	Anivia = {
		{name="FlashFrostSpell", range=1100, radius=90, time=2, ss=true, show=true, isline=true, cc=STUN},
		{name="Frostbite"},
	},
	Ashe = {
		{name="volley", cc=SLOW, physical=true},
		{name="EnchantedCrystalArrow", range=50000, radius=120, time=4, ss=true, show=true, isline=true, cc=STUN},
	},
	Blitzcrank = {
		{name="RocketGrabMissile", key="Q", range=925, radius=90, time=1, ss=true, block=true, perm=true, show=true, isline=true, cc=GRAB},
	},
	Brand = {
		{name="BrandBlazeMissile", range=1050, radius=70, time=1, ss=true, isline=true, cc=STUN},
		{name="brandconflagration"},
		{name="BrandFissure", range=900, radius=250, time=4, ss=true, isline=false},
		{name="brandwildfire"},
	},
	Caitlyn = {
		{name="CaitlynEntrapmentMissile", range=1000, radius=50, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		{name="CaitlynPiltoverPeacemaker", range=1300, radius=80, time=1, ss=true, isline=true},
		{name="caitlynaceinthehole", physical=true},
	},
	Cassiopeia = {
		{name="CassiopeiaMiasma", range=850, radius=175, time=1, ss=true, isline=false},
		{name="CassiopeiaNoxiousBlast", range=850, radius=75, time=1, ss=true, isline=false},
	},
	Chogath = {
		{name="Rupture", range=950, radius=275, time=2, ss=true, show=true, isline=false, cc=SLOW},
		{name="feralscream", cc=SILENCE},			
		{name="feast"},			
	},
	Corki = {
		{name="MissileBarrageMissile", range=1225, radius=80, time=1, ss=true, isline=true},
		{name="MissileBarrageMissile2", range=1225, radius=100, time=1, ss=true, isline=true},
		{name="CarpetBomb", range=800, radius=150, time=1, ss=true, isline=true, point=true},
	},
	Darius = {
		{name="dariusaxegrabcone", key="E", range=540, perm=true, cc=GRAB, nodamage=true},
		{name="dariusexecute"},			
	},
	Diana = {
		{name="DianaArc", range=900, radius=205, time=1, ss=true, isline=true},
	},
	Draven = {
		{name="DravenDoubleShot", range=1050, radius=125, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		{name="DravenRCast", range=50000, radius=100, time=4, ss=true, show=true, isline=true, physical=true},
	},
	DrMundo = {
		{name="InfectedCleaverMissileCast", key="Q", range=1000, radius=60, time=1, ss=true, perm=true, block=true, isline=true, cc=SLOW},
	},
	Elise = {
		{name="EliseHumanE", range=1075, radius=100, time=1, ss=true, block=true, perm=true, isline=true},
	},
	Ezreal = {
		{name="EzrealMysticShotMissile", key="Q", range=1100, radius=80, time=1, ss=true, block=true, perm=true, isline=true, physical=true},
		{name="EzrealEssenceFluxMissile", range=900, radius=100, time=1, ss=true, isline=true},
		{name="EzrealTrueshotBarrage", range=50000, radius=150, time=4, ss=true, show=true, isline=true},
	},
	FiddleSticks = {
		{name="terrify", cc=FEAR, nodamage=true},
		{name="drain"},			
		{name="Crowstorm", range=800, radius=600, time=1.5, ss=true, isline=false},
	},
	Fizz = {
		{name="FizzMarinerDoom", range=1275, radius=100, time=1.5, ss=true, isline=true, point=true, cc=SLOW},
	},
	Galio = {
		{name="GalioResoluteSmite", range=905, radius=200, time=1.5, ss=true, isline=false, cc=SLOW},
		{name="GalioRighteousGust", range=1000, radius=120, time=1.5, ss=true, isline=true},
	},
	Gangplank = {
		{name="parley", physical=true},
	},
	Garen = {
		{name="garenjustice"},
	},
	Graves = {
		{name="GravesClusterShot", range=750, radius=50, time=1, ss=true, isline=true, physical=true},
		{name="GravesSmokeGrenade", range=700, radius=275, time=1.5, ss=true, isline=false},
		{name="GravesChargeShot", range=1000, radius=110, time=1, ss=true, isline=true, physical=true},
	},
	Gragas = {
		{name="GragasBarrelRoll", range=1100, radius=320, time=2.5, ss=true, show=true, isline=false},
		{name="GragasBodySlam", range=650, radius=150, time=1.5, ss=true, isline=true, point=true, cc=SLOW},
		{name="GragasExplosiveCask", range=1050, radius=400, time=1.5, ss=true, isline=false, cc=KNOCK},
	},
	Heimerdinger = {
		{name="CH1ConcussionGrenade", range=950, radius=225, time=2, ss=true, show=true, isline=false, cc=STUN},
		{name="hextechmicrorockets"},
	},
	Irelia = {
		{name="IreliaTranscendentBlades", range=1200, radius=80, time=0.8, ss=true, isline=true},
		{name="ireliaequilibriumstrike", cc=STUN},
	},
	Janna = {
		{name="HowlingGale", range=1700, radius=100, time=3, ss=true, show=true, isline=true},
		{name="sowthewind", cc=SLOW}
	},
	JarvanIV = {
		{name="JarvanIVDragonStrike", range=770, radius=70, time=1, ss=true, isline=true, cc=KNOCK, physical=true},
		{name="JarvanIVDemacianStandard", range=830, radius=150, time=2, ss=true, isline=false},
		{name="JarvanIVCataclysm", range=650, radius=300, time=1.5, ss=true, isline=false, physical=true},
	},
	Jayce = {
		{name="jayceshockblast", range=1470, radius=100, time=1, ss=true, show=true, isline=true, physical=true},
	},
	Jinx = {
		{name="JinxQ", key="Q"},
		{name="JinxWMissile", key="W", range=1500, radius=80, time=1.5, ss=true, show=true, isline=true, block=true, perm=true, physical=true, cc=SLOW},
		{name="JinxE", key="E"},
		{name="JinxR", key="R", range=50000, radius=150, time=4, ss=true, show=true, isline=true, physical=true}
	},
	Karthus = {
		{name="LayWaste", range=875, radius=150, time=1, ss=true, isline=false},
		{name="fallenone"},
	},
	Kassadin = {
		{name="nulllance", cc=SILENCE},
		{name="forcepulse", cc=SLOW},
		{name="RiftWalk", range=700, radius=150, time=1, ss=true, isline=true, point=true},
	},
	Katarina = {
	},
	Kayle = {
		{name="judicatorreckoning", cc=SLOW},
	},	
	Kennen = {
		{name="KennenShurikenHurlMissile1", range=1050, radius=75, time=1, ss=true, isline=true},
	},
	Khazix = {
		{name="KhazixW", range=1000, radius=120, time=0.5, ss=true, isline=true, cc=SLOW, physical=true},
		{name="khazixwlong", range=1000, radius=150, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		{name="KhazixE", range=600, radius=200, time=1, ss=true, isline=false, physical=true},
		{name="khazixelong", range=900, radius=200, time=1, ss=true, isline=false, physical=true},
	},
	KogMaw = {
		{name="KogMawVoidOozeMissile", range=1115, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		{name="KogMawLivingArtillery", range=2200, radius=200, time=1.5, ss=true, show=true, isline=false},
	},
	Leblanc = {
		{name="LeblancSoulShackle", range=1000, radius=80, time=1, ss=true, isline=true, cc=BIND},
		{name="LeblancSoulShackleM", range=1000, radius=80, time=1, ss=true, isline=true, cc=BIND},
		{name="LeblancSlide", range=600, radius=250, time=1, ss=true, isline=false},
		{name="LeblancSlideM", range=600, radius=250, time=1, ss=true, isline=false},
		{name="leblancslidereturn", range=1000, radius=50, time=1, ss=true, isline=false},
		{name="leblancslidereturnm", range=1000, radius=50, time=1, ss=true, isline=false},
	},
	LeeSin = {
		{name="BlindMonkQOne", key="Q", range=975, radius=150, time=1, ss=true, block=true, perm=true, isline=true, physical=true},
		{name="BlindMonkRKick", range=1200, radius=100, time=1, ss=true, isline=true, physical=true},
	},
	Leona = {
		{name="LeonaZenithBladeMissile", range=700, radius=150, time=1, ss=true, isline=true},
		{name="leonasolarflare", cc=STUN},
	},
	Lissandra = {
		{name="LissandraQMissile", range=725, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		{name="LissandraE", range=1050, radius=100, time=1.5, ss=true, isline=true},
	},
	Lucian = {
		{name="LucianQ", range=1100, radius=100, time=0.75, ss=true, isline=true, physical=true},
		{name="LucianW", range=1000, radius=150, time=1.5, ss=true, isline=true},
		{name="LucianR", range=1400, radius=250, time=3, ss=true, isline=true, physical=true},
	},
	Lux = {
		{name="LuxLightBinding", key="Q", range=1175, radius=150, time=1, ss=true, isline=true, cc=BIND},
		{name="LuxLightStrikeKugel", range=1100, radius=300, time=2.5, ss=true, show=true, isline=false, cc=SLOW},
		{name="LuxMaliceCannon", range=3000, radius=180, time=1.5, ss=true, isline=true},
	},
	Lulu = {
		{name="LuluQ", range=925, radius=50, time=1, ss=true, isline=true, cc=SLOW},
	},
	Malphite = {
		{name="seismicshard", cc=SLOW},
		{name="UFSlash", range=1000, radius=325, time=1, ss=true, show=true, isline=false, cc=KNOCK},
	},
	Malzahar = {
		{name="AlZaharCalloftheVoid", range=900, radius=100, time=1, ss=true, isline=false, cc=SILENCE},
		{name="AlZaharNullZone", range=800, radius=250, time=1, ss=true, isline=false},
		{name="alzaharmaleficvisions"},
		{name="alzaharnethergrasp", cc=STUN},		
	},
	Maokai = {
	 	{name="maokaiunstablegrowth", cc=STUN},
		{name="MaokaiTrunkLineMissile", range=600, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		{name="MaokaiSapling2", range=1100, radius=350, time=1, ss=true, isline=false},
	},
	MissFortune = {
		{name="missfortunericochetshot", physical=true},
		{name="MissFortuneScattershot", range=800, radius=400, time=3, ss=true, isline=false},
	},
	Morgana = {
		{name="DarkBindingMissile", key="Q", range=1300, radius=90, time=1.5, ss=true, show=true, perm=true, block=true, isline=true, cc=BIND},
		{name="TormentedSoil", range=900, radius=300, time=1.5, ss=true, isline=false},
	},
	Nami = {
		{name="NamiQ", range=875, radius=200, time=1.5, ss=true, show=true, isline=false, cc=STUN},
		{name="NamiR", range=2550, radius=350, time=3, ss=true, isline=true, cc=KNOCK},
	},
	Nasus = {
		{name="wither", cc=SLOW, nodamage=true},
	},
	Nautilus = {
		{name="NautilusAnchorDrag", key="Q", range=950, radius=80, time=1.5, ss=true, perm=true, block=true, isline=true},
		{name="nautilusgrandline", cc=KNOCK},
	},
	Nidalee = {
		{name="JavelinToss", key="Q", range=1500, radius=120, time=1.5, ss=true, block=true, perm=true, show=true, isline=true},
	},
	Nocturne = {
		{name="NocturneDuskbringer", range=1200, radius=150, time=1.5, ss=true, isline=true, physical=true},
	},
	Olaf = {
		{name="OlafAxeThrow", range=1000, radius=100, time=1.5, ss=true, isline=true, point=true, cc=SLOW, physical=true},
	},
	Orianna = {
		{name="OrianaIzunaCommand", range=825, radius=90, time=1.5, ss=true, isline=false},
	},
	Pantheon = {
		{name="pantheon_throw", physical=true},
		{name="pantheon_leapbash", cc=STUN},
	},
	Quinn = {
		{name="QuinnQMissile", range=1025, radius=40, time=1, ss=true, isline=true, cc=BLIND, physical=true},
	},
	Rammus = {
		{name="puncturingtaunt", cc=TAUNT, nodamage=true},
	},
	Renekton = {
		{name="RenektonSliceAndDice", range=450, radius=80, time=1, ss=true, isline=true, physical=true},
		{name="renektondice", range=450, radius=80, time=1, ss=true, isline=true, physical=true},
	},
	Rengar = {
		{name="rengarE", cc=STUN, physical=true},
	},
	Rumble = {
		{name="RumbleGrenadeMissile", range=1000, radius=100, time=1.5, ss=true, isline=true},
		{name="RumbleCarpetBomb", range=1700, radius=100, time=1.5, ss=true, isline=true},
	},
	Ryze = {
		{name="runeprison", cc=STUN},
		{name="overload"},
	},
	Sejuani = {
		{name="SejuaniGlacialPrison", range=1150, radius=180, time=1, ss=true, isline=true, cc=STUN},
	},
	Shaco = {
		{name="Deceive", range=500, radius=100, time=3.5, ss=true, isline=false, nodamage=true},
	},
	Shen = {
		{name="ShenShadowDash", range=600, radius=150, time=1, ss=true, isline=true, point=true, cc=TAUNT, nodamage=true},
	},
	Shyvana = {
		{name="ShyvanaTransformLeap", range=925, radius=150, time=1.5, ss=true, isline=true},
		{name="ShyvanaFireballMissile", range=1000, radius=80, time=1, ss=true, isline=true},
	},
	Sion = {
		{name="crypticgaze", cc=STUN},
	},
	Sivir = {
		{name="SpiralBlade", key="Q", range=1000, radius=100, time=1, ss=true, isline=true, physical=true},
	},
	Singed = {
		{name="MegaAdhesive", range=1000, radius=350, time=1.5, ss=true, isline=false, cc=SLOW},
	},
	Skarner = {
		{name="SkarnerFracture", range=600, radius=100, time=1, ss=true, isline=true},
		{name="skarnerimpale", cc=GRAB},
	},
	Sona = {
		{name="SonaCrescendo", range=1000, radius=150, time=1, ss=true, isline=true, cc=STUN},
	},
	Swain = {
		{name="SwainShadowGrasp", range=900, radius=265, time=1.5, ss=true, isline=false, cc=STUN},
	},
	Syndra = {
		{name="SyndraQ", range=800, radius=200, time=1, ss=true, isline=false},
		{name="syndrawcast", range=950, radius=200, time=1, ss=true, isline=false, cc=SLOW},
		{name="SyndraE", range=650, radius=100, time=0.5, ss=true, isline=true, cc=STUN},
	},
	Taric = {
		{name="dazzle", cc=STUN},
	},
	Teemo = {
		{name="blindingdart", cc=BLIND},
	},
	Thresh = {
		{name="ThreshQ", key="Q", range=1100, radius=100, time=1.5, ss=true, show=true, block=true, perm=true, isline=true, cc=STUN},
	},
	Tristana = {
		{name="detonatingshot"},
		{name="RocketJump", range=900, radius=200, time=1, ss=true, isline=false},
		{name="bustershot", cc=KNOCK},
	},
	Tryndamere = {
		{name="Slash", range=600, radius=100, time=1, ss=true, isline=true, point=true, physical=true},
	},
	TwistedFate = {
		{name="redcard", cc=SLOW},
		{name="yellowcard", cc=STUN},
		{name="WildCards", range=1450, radius=80, time=1, ss=true, show=true, isline=true},
	},
	Twitch = {
		{name="TwitchVenomCask", cc=SLOW, nodamage=true},
	},
	Urgot = {
		{name="UrgotHeatseekingLineMissile", range=1000, radius=80, time=0.8, ss=true, isline=true, physical=true},
		{name="UrgotPlasmaGrenade", range=950, radius=300, time=1, ss=true, isline=false, physical=true},
	},
	Vayne = {
		{name="VayneCondemn", cc=KNOCK, physical=true},
		-- {name="VayneTumble", range=250, radius=100, time=1, ss=true, isline=false},
	},
	Varus = {
		{name="VarusQ", range=1475, radius=50, time=1, ss=true, isline=true, physical=true},
		{name="VarusR", range=1075, radius=80, time=1.5, ss=true, isline=true, cc=STUN},
	},
	Veigar = {
		{name="veigarbalefulstrike"},
		{name="VeigarDarkMatter", range=900, radius=225, time=2, ss=true, show=true, isline=false},
		{name="veigareventhorizon", cc=STUN},	
		{name="veigarprimordialburst"},
	},
	Volibear = {
		{name="volibearq", cc=KNOCK, physical=true},
	},
	Vi = {
		{name="ViQ", range=900, radius=150, time=1, ss=true, isline=true, physical=true},
		{name="assaultandbattery", cc=KNOCK, physical=true},
	},
	Viktor = {
		--{name="ViktorDeathRay", range=700, radius=80, time=2, ss=true, isline=true},
	},
	Xerath = {
		{name="xeratharcanopulsedamage", range=900, radius=80, time=1, ss=true, show=true, isline=true},
		{name="xeratharcanopulsedamageextended", range=1300, radius=80, time=1, ss=true, show=true, isline=true},
		{name="xeratharcanebarragewrapper", range=900, radius=250, time=1, ss=true, isline=false},
		{name="xeratharcanebarragewrapperext", range=1300, radius=250, time=1, ss=true, isline=false},
	},
	Zac = {
		{name="ZacQ", range=550, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		{name="ZacE", range=1550, radius=200, time=2, ss=true, isline=false, cc=KNOCK},
	},
	Zed = {
		{name="ZedShuriken", range=900, radius=100, time=1, ss=true, isline=true, physical=true},
		{name="ZedShadowDash", range=550, radius=150, time=1, ss=true, isline=true, point=true, physical=true},
		{name="zedw2", range=550, radius=150, time=0.5, ss=true, isline=false, physical=true},
	},
	Ziggs = {
		{name="ZiggsQ", range=1100, radius=160, time=1.5, ss=true, show=true, isline=true},
		{name="ZiggsW", range=1000, radius=225, time=1, ss=true, isline=false, cc=KNOCK},
		{name="ZiggsE", range=900, radius=250, time=1, ss=true, isline=false, cc=SLOW},
		{name="ZiggsR", range=5300, radius=550, time=3, ss=true, isline=false},
	},
	Zyra = {
		{name="ZyraQFissure", range=800, radius=275, time=1.5, ss=true},
		{name="ZyraGraspingRoots", range=1100, radius=90, time=2, ss=true, show=true, isline=true, cc=BIND},
	},
}

function find(source, target)
   if not source then
      return false
   end
   if string.len(target) == 0 then
      return false
   end
   return string.find(string.lower(source), string.lower(target))
end

function GetSpellDef(name, spellName)
	local spellTable = spells[name]
	if spellTable ~= nil then
		for i=1, #spellTable, 1 do
			if find(spellName, spellTable[i].name) then
				return spellTable[i]
			end
		end
	end
	return nil
end

function GetSpellShots(name)
	return spells[name] or {}
end

function GetSpellShot(unit, spell)

	local spellShot = GetSpellDef(unit.name, spell.name)
	if spellShot then
		if not spellShot.time then
			spellShot.time = 1
		end
		if not spellShot.radius then
			spellShot.radius = 0
		end
		spellShot.timeOut = os.clock()+spellShot.time
		spellShot.startPoint = Point(unit)
		spellShot.endPoint = spell.endPos

		if spellShot.point or not spellShot.isline then
			spellShot.maxDist = GetDistance(spellShot.startPoint, spellShot.endPoint) + spellShot.radius
		else
			spellShot.maxDist = spellShot.range + spellShot.radius
			spellShot.endPoint = Projection(spellShot.startPoint, spellShot.endPoint, spellShot.maxDist)
		end

		return spellShot
	else
		return nil
	end
end

local function isSafe(safePoint, spell, spellShot)
	if not safePoint then
		return false
	end

	if spellShot.isline and not spellShot.point then
		local dist = GetDistance(spellShot.startPoint, safePoint)

		if dist < spellShot.maxDist then
			local impactPoint = Projection(spellShot.startPoint, spellShot.endPoint, dist)
			local impactDistance = GetDistance(impactPoint, safePoint)
			if impactDistance <= spellShot.safeDist then -- hit
				return false
			end
		end
	else
		if GetDistance(safePoint, spellShot.endPoint) < spellShot.safeDist then
			return false
		end
	end
	return true
end

function SpellShotTarget(unit, spell, target)
	if unit and spell and unit.team ~= target.team then
		local shot = GetSpellShot(unit, spell)
		if shot and shot.ss then
			
			shot.safeDist = shot.radius + GetWidth(target)/2
			
			-- calculate a safe points if I'm the target
			if IsMe(target) and not isSafe(me, spell, shot) then
				
				local impactPoint = shot.endPoint
				if shot.isline and not shot.point then
					impactPoint = Projection(shot.startPoint, shot.endPoint, GetDistance(shot.startPoint))
				end
				
				-- is where I'll be in half a second clear?
				local safePoint = ProjectionA(me, GetMyDirection(), me.movespeed/2)

				if not isSafe(safePoint, spell, shot) then					
					safePoint = Projection(impactPoint, target, shot.safeDist)
				end

				if IsSolid(safePoint) then -- if safe is into a wall go the other direction
					safePoint = nil
					local locs = SortByDistance(GetCircleLocs(impactPoint, shot.safeDist))
					for _,loc in ipairs(locs) do
						if not IsSolid(loc) and isSafe(loc, spell, shot) then
							safePoint = loc
							break
						end
					end
				end

				if safePoint then
					shot.safePoint = Projection(me, safePoint, GetDistance(safePoint)+50)
				else
					pp("No safe point dodging "..spell.name)
				end

				return shot
			end

		end
	end
	return nil
end