require "issuefree/basicUtils"

-- "hardness" of the cc
local GRAB = 4
local TAUNT = 4
local STUN = 3
local KNOCK = 3
local FEAR = 3
local BIND = 2
local SLOW = 1
local SILENCE = 1

ignoredSpells = {
	"attack", "recall", "potion", "summoner", "IronStylus", "item", "ZhonyasHourglass",
	"DeathfireGrasp", "totem", "ward", "BilgewaterCutlass", "ItemSwordOfFeastAndFamine",
	"trinket", "HealthBomb", "RanduinsOmen", "YoumusBlade",
}

SPELL_DEFS = {
   Aatrox={
      AatroxQ={type="dash", ends="point", range=650},
      keys={"Q"}
   },
	Ahri = {
		AhriOrbofDeception={range=880, radius=80, time=1, ss=true, isline=true},
		AhriSeduce={range=975, radius=80, time=1, ss=true, isline=true, block=true, cc=TAUNT, nodamage=true},
      AhriTumble={type="dash", ends="max", range=450, key="R"},
      keys={"R"}
	},
	Akali = {
		akalimota={},
      AkaliShadowDance={type="dash", ends="target", key="R"},
	},
	Alistar = {
		headbutt={
			cc=KNOCK,
			type="dash", ends="target",
		},
	},
	Amumu = {
		BandageToss={
			range=1100, radius=80, time=1, ss=true, isline=true, block=true, cc=STUN, 
			type="dash", ends="target"
		},
	},
	Annie = {
		Disintegrate={key="Q", cc=STUN},
		InfernalGuardian={key="R", range=600, perm=true, cc=STUN},
	},
	Anivia = {
		FlashFrostSpell={range=1100, radius=90, time=2, ss=true, show=true, isline=true, cc=STUN},
		Frostbite={},
	},
	Ashe = {
		volley={block=true, cc=SLOW, physical=true},
		EnchantedCrystalArrow={range=50000, radius=120, time=4, ss=true, show=true, isline=true, cc=STUN, dodgeByObject=true},
	},
   Azir={
      keys={"E"} -- TODO shifting sands
   }, 
	Blitzcrank = {
		RocketGrabMissile={
			key="Q", range=925, radius=90, time=1, ss=true, block=true, perm=true, show=true, isline=true, cc=GRAB,
			type="stall",
		},
	},
	Brand = {
		BrandBlazeMissile={range=1050, radius=70, time=1, ss=true, isline=true, block=true, cc=STUN},
		brandconflagration={},
		BrandFissure={range=900, radius=250, time=4, ss=true, isline=false},
		brandwildfire={},
	},
	Braum = {
		SpellNameQ={range=1000, radius=175, time=1, ss=true, isline=true, block=true, cc=SLOW},
		keys={"W"} -- TODO stand behind me
	},
	Caitlyn = {
		CaitlynHeadshotMissile={},
		CaitlynEntrapmentMissile={range=1000, radius=50, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		CaitlynPiltoverPeacemaker={
			range=1300, radius=80, time=1, ss=true, isline=true, physical=true,
			type="stall"
		},
      CaitlynEntrapment={type="dash", ends="reverse", range=400},
      CaitlynYordleTrap={key="W"},
		CaitlynAceintheHole={
			physical=true,
			type="stall", duration=2
		},
	},
	Cassiopeia = {
		CassiopeiaMiasma={range=850, radius=175, time=1, ss=true, isline=false},
		CassiopeiaNoxiousBlast={range=850, radius=75, time=1, ss=true, isline=false},
		CassiopeiaTwinFang={},
		CassiopeiaPetrifyingGaze={type="stall"},
	},
	Chogath = {
		Rupture={
			range=950, radius=275, time=2, ss=true, show=true, isline=false, cc=SLOW,
			type="stall"
		},
		feralscream={cc=SILENCE},
		feast={},
	},
	Corki = {
		MissileBarrageMissile={range=1225, radius=80, time=1, ss=true, isline=true, block=true},
		MissileBarrageMissile2={range=1225, radius=100, time=1, ss=true, isline=true, block=true},
		CarpetBomb={
			--range=800, radius=150, time=1, ss=true, isline=true, point=true,
			type="dash", ends="point", range=800
		},
	},
	Darius = {
		DariusAxeGrabCone={
			key="E", range=540, perm=true, cc=GRAB, nodamage=true,
			type="stall"
		},
      DariusExecute={type="dash", ends="target"},
	},
	Diana = {
		DianaArc={range=900, radius=205, time=1, ss=true, isline=true},
      DianaTeleport={type="dash", ends="target"},
      keys={"R"}      
	},
	Draven = {
		DravenDoubleShot={range=1050, radius=125, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		DravenRCast={range=50000, radius=100, time=4, ss=true, show=true, isline=true, physical=true},
	},
	DrMundo = {
		InfectedCleaverMissileCast={key="Q", range=1000, radius=60, time=1, ss=true, perm=true, block=true, isline=true, block=true, cc=SLOW},
	},
	Elise = {
		EliseHumanE={range=1075, radius=100, time=1, ss=true, block=true, perm=true, isline=true, block=true},
      EliseSpiderQCast={type="dash", ends="target"},
	},
	Ezreal = {
		EzrealMysticShot={key="Q", range=1100, radius=80, time=1, ss=true, block=true, perm=true, isline=true, block=true, physical=true},
		EzrealEssenceFluxMissile={range=900, radius=100, time=1, ss=true, isline=true},
      EzrealArcaneShift={type="dash", ends="point", range=475},
		EzrealTrueshotBarrage={
			range=50000, radius=150, time=4, ss=true, show=true, isline=true, dodgeByObject=true,
			type="stall", duration=1
		},
	},
	FiddleSticks = {
		Terrify={cc=FEAR, nodamage=true},
      Drain={type="stall"},
      DrainChannel={type="stall"},
		Crowstorm={
			range=800, radius=300, time=1.5, ss=true, isline=false,
			type="dash", ends="point"
		},
		FiddlesticksDarkWind={cc=SILENCE},
	},
   Fiora={
      FioraQ={type="dash", ends="target"},
      keys={"Q"}
   },
	Fizz = {
		FizzMarinerDoom={range=1275, radius=100, time=1.5, ss=true, isline=true, point=true, block=true, cc=SLOW},
		FizzJump={},
		FizzPiercingStrike={},
		FizzSeastonePassive={},
	},
	Galio = {
		GalioResoluteSmite={range=905, radius=200, time=1.5, ss=true, isline=false, cc=SLOW},
		GalioRighteousGust={range=1000, radius=120, time=1.5, ss=true, isline=true},
      GalioIdolOfDurand={type="stall"},
      GalioBulwark={},
	},
	Gangplank = {
		Parley={physical=true},
		RemoveScurvy={},
		RaiseMorale={},
	},
	Garen = {
		GarenQ={},
		GarenE={},
		GarenR={},
	},
	Graves = {
		GravesClusterShot={range=750, radius=50, time=1, ss=true, isline=true, physical=true},
		GravesSmokeGrenade={range=700, radius=275, time=1.5, ss=true, isline=false},
      GravesMove={type="dash", ends="max", range=425},
		GravesChargeShot={range=1000, radius=110, time=1, ss=true, isline=true, physical=true},
      keys={"E"}
	},
	Gragas = {
		GragasQ={range=850, radius=320, time=2.5, ss=true, show=true, isline=false},
		GragasW={},
		GragasE={range=650, radius=150, time=1.5, ss=true, isline=true, point=true, block=true, cc=STUN},
		GragasExplosiveCask={range=1050, radius=400, time=1.5, ss=true, isline=false, cc=KNOCK},
	},
   Hecarim={
      HecarimUlt={type="dash", ends="point", range=1000},
      keys={"R"}
   },
	Heimerdinger = {
		CH1ConcussionGrenade={range=950, radius=225, time=2, ss=true, show=true, isline=false, cc=STUN},
		hextechmicrorockets={},
	},
	Irelia = {
		IreliaTranscendentBlades={range=1200, radius=80, time=0.8, ss=true, isline=true},
		ireliaequilibriumstrike={cc=STUN},
      IreliaGatotsu={type="dash", ends="target"},
	},
	Janna = {
		HowlingGale={range=1700, radius=100, time=3, ss=true, show=true, isline=true, dodgeByObject=true},
		sowthewind={cc=SLOW},
      ReapTheWhirlwind={type="stall"},
	},
	JarvanIV = {
		JarvanIVDragonStrike={range=770, radius=70, time=1, ss=true, isline=true, cc=KNOCK, physical=true},
		JarvanIVDemacianStandard={range=830, radius=150, time=2, ss=true, isline=false},
		JarvanIVCataclysm={
			range=650, radius=300, time=1.5, ss=true, isline=false, physical=true,
			type="dash", ends="point"
		},
	},
   Jax={
      JaxLeapStrike={type="dash", ends="target", overShoot=-50},
      JayceToTheSkies={type="dash", ends="target"},
      keys={"Q"}
   },
	Jayce = {
		jayceshockblast={range=1470, radius=100, time=1, ss=true, show=true, isline=true, block=true, physical=true},
	},
	Jinx = {
		JinxQ={key="Q"},
      JinxW={type="stall"},
		JinxWMissile={key="W", range=1500, radius=80, time=1.5, ss=true, show=true, isline=true, block=true, perm=true, physical=true, cc=SLOW},
		JinxE={key="E"},
		JinxR={
			key="R", range=50000, radius=150, time=4, ss=true, show=true, isline=true, physical=true, dodgeByObject=true,
			type="stall"
		},
      keys={"W","R"}
	},
	Karthus = {
		LayWaste={range=875, radius=150, time=1, ss=true, isline=false},
		fallenone={},
	},
	Kassadin = {
		nulllance={cc=SILENCE},
		forcepulse={cc=SLOW},
		RiftWalk={
			range=700, radius=150, time=1, ss=true, isline=true, point=true,
			type="dash", ends="point"
		},
      keys={"R"}
	},
	Katarina = {
		KatarinaQ={},
		KatarinaW={},
      KatarinaE={type="dash", ends="target"},
      KatarinaR={type="stall"},
	},
	Kayle = {
		judicatorreckoning={cc=SLOW},
	},	
	Kennen = {
		KennenShurikenHurlMissile1={range=1050, radius=75, time=1, ss=true, isline=true, block=true},
		KennenShurikenStorm={}, --TODO
	},
	Khazix = {
		KhazixW={range=1000, radius=120, time=0.5, ss=true, isline=true, cc=SLOW, physical=true},
		khazixwlong={range=1000, radius=150, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		KhazixE={
			range=600, radius=200, time=1, ss=true, isline=false, physical=true,
			type="dash", ends="point"
		},
		khazixelong={
			range=900, radius=200, time=1, ss=true, isline=false, physical=true,
			type="dash", ends="point"
		},
	},
	KogMaw = {
		KogMawQ={},--TODO
		KogMawVoidOoze={},
		KogMawVoidOozeMissile={range=1150, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		KogMawLivingArtillery={range=2200, radius=200, time=1.5, ss=true, show=true, isline=false},
		KogMawBioArcaneBarrage={},
	},
	Leblanc = {
		LeblancSoulShackle={range=1000, radius=80, time=1, ss=true, isline=true, block=true, cc=BIND},
		LeblancSoulShackleM={range=1000, radius=80, time=1, ss=true, isline=true, block=true, cc=BIND},
		LeblancSlide={
			range=600, radius=250, time=1, ss=true, isline=false,
			type="dash", ends="point"
		},
		LeblancSlideM={
			range=600, radius=250, time=1, ss=true, isline=false,
			type="dash", ends="point"
		},
		leblancslidereturn={range=1000, radius=50, time=1, ss=true, isline=false},
		leblancslidereturnm={range=1000, radius=50, time=1, ss=true, isline=false},
	},
	LeeSin = {
		BlindMonkQOne={key="Q", range=975, radius=150, time=1, ss=true, block=true, perm=true, isline=true, block=true, physical=true},
		BlindMonkRKick={range=1200, radius=100, time=1, ss=true, isline=true, physical=true},
      blindmonkqtwo={type="dash", ends="target"},
      BlindMonkWOne={type="dash", ends="target"},
      keys={"Q", "W"}
	},
	Leona = {
		LeonaZenithBladeMissile={range=700, radius=150, time=1, ss=true, isline=true},
      -- LeonaZenithBlade={type="dash", ends="target?"}, -- TODO
		leonasolarflare={cc=STUN},
	},
	Lissandra = { -- todo dash
		LissandraQMissile={range=725, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		LissandraE={range=1050, radius=100, time=1.5, ss=true, isline=true},
	},
	Lucian = {
		LucianQ={range=1100, radius=100, time=0.75, ss=true, isline=true, physical=true},
		LucianW={range=1000, radius=150, time=1.5, ss=true, isline=true, physical=true},
      LucianE={type="dash", ends="point", range=450},
		LucianR={range=1400, radius=250, time=3, ss=true, isline=true, physical=true},
	},
	Lux = {
		LuxLightBinding={key="Q", range=1175, radius=150, time=1, ss=true, isline=true, cc=BIND},
		luxlightstriketoggle={},
		LuxLightStrikeKugel={range=1100, radius=300, time=2.5, ss=true, show=true, isline=false, cc=SLOW},
		LuxMaliceCannon={
			range=3000, radius=180, time=1.5, ss=true, isline=true,
			type="stall"
		},
		LuxMaliceCannonMis={},
		LuxPrismaticWave={},
	},
	Lulu = {
		LuluQ={range=925, radius=50, time=1, ss=true, isline=true, cc=SLOW},
	},
	Malphite = {
		seismicshard={cc=SLOW},
		UFSlash={
			range=1000, radius=325, time=1, ss=true, show=true, isline=false, cc=KNOCK,
			type="dash", ends="point"
		},
	},
	Malzahar = {
		AlZaharCalloftheVoid={range=900, radius=100, time=1, ss=true, isline=false, cc=SILENCE},
		AlZaharNullZone={range=800, radius=250, time=1, ss=true, isline=false},
		alzaharmaleficvisions={},
      AlZaharNetherGrasp={
	      cc=STUN,
      	type="stall"
      },
	},
	Maokai = {
	 	MaokaiUnstableGrowth={
	 		cc=STUN,
	 		type="dash", ends="target"
	 	},
		MaokaiTrunkLineMissile={range=600, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		MaokaiSapling2={range=1100, radius=350, time=1, ss=true, isline=false},
	},
   MasterYi={
      Meditate={type="stall"},
   },
	MissFortune = {
		missfortunericochetshot={physical=true},
		MissFortuneScattershot={range=800, radius=400, time=3, ss=true, isline=false},
      MissFortuneBulletTime={tupe="stall"},
	},
	Morgana = {
		DarkBindingMissile={key="Q", range=1300, radius=110, time=1.5, ss=true, show=true, perm=true, block=true, isline=true, cc=BIND},
		TormentedSoil={range=900, radius=300, time=1.5, ss=true, isline=false},
	},
	Nami = {
		NamiQ={range=875, radius=200, time=1.5, ss=true, show=true, isline=false, cc=STUN},
		namiqmissile={}, --TODO
		NamiR={range=2550, radius=350, time=3, ss=true, isline=true, cc=KNOCK},
		NamiRMissile={},
		NamiW={},
		NamiE={},
	},
	Nasus = {
		wither={cc=SLOW, nodamage=true},
	},
	Nautilus = {
		NautilusAnchorDrag={key="Q", range=950, radius=80, time=1.5, ss=true, perm=true, block=true, isline=true},
		nautilusgrandline={cc=KNOCK},
	},
	Nidalee = {
		JavelinToss={key="Q", range=1500, radius=40, time=1.5, ss=true, block=true, perm=true, show=true, isline=true},
      Pounce={type="dash", ends="max", range=375},
      Bushwhack={},
      AspectOfTheCougar={},
      Swipe={},
      Takedown={},
      PrimalSurge={},
      keys={"W"}
	},
	Nocturne = {
		NocturneDuskbringer={range=1200, radius=150, time=1.5, ss=true, isline=true, physical=true},
      keys={"R"}
	},
   Nunu={
      Consume={type="stall"},
      AbsoluteZero={type="stall"},
   },
	Olaf = {
		OlafAxeThrow={range=1000, radius=100, time=1.5, ss=true, isline=true, point=true, cc=SLOW, physical=true},
	},
	Orianna = {
		OrianaIzunaCommand={range=825, radius=90, time=1.5, ss=true, isline=false},
	},
	Pantheon = {
		pantheon_throw={physical=true},
      PantheonW={type="dash", ends="target", overShoot=-50},
	},
   Poppy={
      PoppyHeroicCharge={type="dash", ends="target", overShoot=300},
      keys={"E"}
   },
  	Quinn = {
		QuinnQMissile={range=1025, radius=40, time=1, ss=true, isline=true, cc=BLIND, physical=true},
	},
	Rammus = {
		puncturingtaunt={cc=TAUNT, nodamage=true},
	},
	Renekton = {
		-- RenektonSliceAndDice={range=450, radius=80, time=1, ss=true, isline=true, physical=true},
		-- renektondice={range=450, radius=80, time=1, ss=true, isline=true, physical=true},
      RenektonSliceAndDice={type="dash", ends="max", range=450},
      renektondice={type="dash", ends="max", range=450},
  	},
	Rengar = {
		rengarE={cc=STUN, physical=true},
	},
   Riven={
      RivenFeint={type="dash", ends="max", range=325},
      RivenMartyr={},
      RivenTriCleave={},
      RivenFengShuiEngine={},
      rivenizunablade={},
      keys={"E"}
   },
 	Rumble = {
		RumbleGrenadeMissile={range=1000, radius=100, time=1.5, ss=true, isline=true},
		RumbleCarpetBomb={range=1700, radius=100, time=1.5, ss=true, isline=true},
	},
	Ryze = {
		runeprison={cc=STUN},
		overload={},
	},
	Sejuani = {
		SejuaniGlacialPrison={range=1150, radius=180, time=1, ss=true, isline=true, cc=STUN},
	},
	Shaco = {
		Deceive={
			range=400, radius=100, time=3.5, ss=true, isline=false, nodamage=true,
			type="dash", ends="point"
		},
		HallucinateFull={},
      keys={"Q"}
	},
	Shen = {
		ShenShadowDash={
			range=600, radius=150, time=1, ss=true, isline=true, point=true, cc=TAUNT, nodamage=true,
			type="dash", ends="max"
		},
      ShenStandUnited={type="stall"},
	},
	Shyvana = {
   	ShyvanaTransformCast={type="dash", ends="point", range=1000},	
		ShyvanaTransformLeap={range=925, radius=150, time=1.5, ss=true, isline=true},
		ShyvanaFireball={},
		ShyvanaFireballMissile={range=1000, radius=80, time=1, ss=true, isline=true},
		ShyvanaImmolationAura={},
		shyvanaimmolatedragon={},
	},
	Sion = {
		SionQ={type="stall"},
  	},
	Sivir = {
		SpiralBlade={key="Q", range=1000, radius=100, time=1, ss=true, isline=true, physical=true},
	},
	Singed = {
		MegaAdhesive={range=1000, radius=350, time=1.5, ss=true, isline=false, cc=SLOW},
	},
	Skarner = {
		SkarnerFracture={range=600, radius=100, time=1, ss=true, isline=true},
		skarnerimpale={cc=GRAB},
	},
	Sona = {
		SonaCrescendo={range=1000, radius=350, time=1, ss=true, isline=true, cc=STUN},
	},
	Swain = {
		SwainShadowGrasp={range=900, radius=265, time=1.5, ss=true, isline=false, cc=STUN},
	},
	Syndra = {
		SyndraQ={range=800, radius=200, time=1, ss=true, isline=false},
		syndrawcast={range=950, radius=200, time=1, ss=true, isline=false, cc=SLOW},
		SyndraE={range=650, radius=100, time=0.5, ss=true, isline=true, cc=STUN},
	},
	Talon={
		TalonCutthroat={type="dash", ends="target"},
      keys={"E"}
	},
	Taric = {
		dazzle={cc=STUN},
	},
	Teemo = {
		MoveQuick={},
		BlindingDart={cc=BLIND},
		BantamTrap={},
	},
	Thresh = {
		ThreshQ={key="Q", range=1100, radius=100, time=1.5, ss=true, show=true, block=true, perm=true, isline=true, cc=STUN},
		threshqinternal={},
		threshqleap={--[[type="dash"]]},
		ThreshW={},
		lanternwally={},
      ThreshE={type="stall"},
      ThreshRPenta={type="stall"},
      keys={"Q","E"}
  	},
	Tristana = {
		RapidFire={},
		DetonatingShot={},
		RocketJump={
			range=900, radius=200, time=1, ss=true, isline=false,
			type="dash", ends="point"
		},
		BusterShot={cc=KNOCK},
	},
	Tryndamere = {
		Slash={
			range=660, radius=100, time=1, ss=true, isline=true, point=true, physical=true,
			type="dash", ends="point"
		},
      keys={"E"}   	
	},
	TwistedFate = {
		redcard={cc=SLOW},
		yellowcard={cc=STUN},
		WildCards={range=1450, radius=80, time=1, ss=true, show=true, isline=true},
	},
	Twitch = {
		TwitchVenomCask={cc=SLOW, nodamage=true},
	},
	Urgot = {
		UrgotHeatseekingLineMissile={range=1000, radius=80, time=0.8, ss=true, isline=true, block=true, physical=true},
		UrgotPlasmaGrenade={range=950, radius=300, time=1, ss=true, isline=false, physical=true},
	},
	Vayne = {
		VayneCondemn={cc=KNOCK, physical=true},
      VayneTumble={type="dash", ends="max", range=300},
	},
	Varus = {
		VarusQ={range=1475, radius=50, time=1, ss=true, isline=true, physical=true},
		VarusR={range=1075, radius=80, time=1.5, ss=true, isline=true, cc=STUN},
	},
	Veigar = {
		veigarbalefulstrike={},
		VeigarDarkMatter={range=900, radius=225, time=2, ss=true, show=true, isline=false},
		veigareventhorizon={cc=STUN},	
		veigarprimordialburst={},
	},
   Velkoz={
   	-- ult={type="stall"},
   	-- TODO get obj for channel
      keys={"R"}
	},	
	Volibear = {
		VolibearQ={cc=KNOCK, physical=true},
		VolibearR={}
	},
	Vi = {
		ViQ={range=900, radius=150, time=1, ss=true, isline=true, physical=true}, -- TODO dash stuff
		assaultandbattery={cc=KNOCK, physical=true},
	},
	Viktor = {
		--ViktorDeathRay={range=700, radius=80, time=2, ss=true, isline=true},
	},
   Warwick={
   	HungeringStrike={key="Q"},
      InfiniteDuress={type="dash", ends="target"},
      infiniteduresschannel={},
      HuntersCall={key="W"},
      BloodScent={},
   },	
   MonkeyKing={
   	MonkeyKingNimbus={type="dash", ends="target"},
	},
	Xerath = {
		xeratharcanopuls2={range=1500, radius=80, time=1, ss=true, show=true, isline=true},
		xeratharcanebarrage2={range=1100, radius=200, time=1, ss=true, isline=false},
		xerathrmissilewrapper={range=5600, radius=150, time=1, ss=true, isline=false},
		XerathLocusOfPower2={type="stall"},
      XerathArcanopulseChargeUp={type="stall"},
  	},
   XinZhao={
      XenZhaoSweep={type="dash", ends="target"},
      XenZhaoBattleCry={},
   },
   Yasuo={
      YasuoDashWrapper={type="dash", ends="max", range=300},
      keys={"E"}
   },
  	Zac = {
		ZacQ={range=550, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		ZacE={range=1550, radius=200, time=2, ss=true, isline=false, cc=KNOCK},
	},
	Zed = {
		ZedShuriken={range=900, radius=100, time=1, ss=true, isline=true, physical=true},
		ZedShadowDash={range=550, radius=150, time=1, ss=true, isline=true, point=true, physical=true},
		zedw2={range=550, radius=150, time=0.5, ss=true, isline=false, physical=true},
		ZedPBAOEDummy={},
		zedult={},
		ZedR2={},
	},
	Ziggs = {
		ZiggsQ={range=1100, radius=150, time=1.5, ss=true, show=true, isline=true, point=true, block=true},
		ZiggsW={range=1000, radius=225, time=1, ss=true, isline=false, cc=KNOCK},
		ZiggsE={range=900, radius=250, time=1, ss=true, isline=false, cc=SLOW},
		ZiggsR={range=5300, radius=550, time=3, ss=true, isline=false},
	},
	Zyra = {
		ZyraQFissure={range=800, radius=275, time=1.5, ss=true},
		ZyraGraspingRoots={range=1100, radius=90, time=2, ss=true, show=true, isline=true, cc=BIND},
	},
}

function GetSpellDef(name, spellName)
	local spellTable = SPELL_DEFS[name]
	if spellTable then
		local spellDef = spellTable[spellName]
		if spellDef then
			spellDef.name = spellName
			if not spellDef.time then
				spellDef.time = 1
			end
			if not spellDef.radius then
				spellDef.radius = 0
			end
			return spellDef
		else
			for _,ignored in ipairs(ignoredSpells) do
				if find(spellName, ignored) then
					return
				end
			end
			pp("No def for "..name)
			pp(spellName)
			PlaySound("Beep")
			table.insert(ignoredSpells, spellName)
		end
	else
		pp("No defs for "..name)
	end
	return nil
end
