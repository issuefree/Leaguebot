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
	"trinket", "HealthBomb", "RanduinsOmen", "YoumusBlade", "FlaskOfCrystalWater", 
	"ElixirOfWrath", "HextechGunblade", "Muramana", "shurelyascrest", "lanternwally",
}

SPELL_DEFS = {
   Aatrox = {
      aatroxq={type="dash", ends="point", range=650},
   },
	Ahri = {
		ahriorbofdeception={range=880, radius=80, time=1, ss=true, isline=true},
		ahriseduce={range=975, radius=80, time=1, ss=true, isline=true, block=true, cc=TAUNT, nodamage=true},
      ahritumble={type="dash", ends="max", range=450, key="R"},
	},
	Akali = {
		akalimota={},
      akalishadowswipe={},
      akalishadowdance={type="dash", ends="target", key="R"},
      akalismokebomb={},
	},
	Alistar = {
		headbutt={
			cc=KNOCK,
			type="dash", ends="target", overShoot=-25,
		},
	},
	Amumu = {
		bandagetoss={
			range=1100, radius=80, time=1, ss=true, isline=true, block=true, cc=STUN, 
			type="dash", ends="target"
		},
	},
	Annie = {
		disintegrate={key="Q", cc=STUN},
		infernalguardian={key="R", range=600, perm=true, cc=STUN},
		incinerate={},
		moltenshield={},
	},
	Anivia = {
		flashfrostspell={range=1100, radius=90, time=2, ss=true, show=true, isline=true, cc=STUN},
		frostbite={},
	},
	Ashe = {
		volley={block=true, cc=SLOW, physical=true},
		enchantedcrystalarrow={range=50000, radius=120, time=4, ss=true, show=true, isline=true, cc=STUN, dodgeByObject=true},
		frostarrow={},
		frostshot={},
		ashespiritofthehawk={},
	},
   Azir = {
   	azirr={},
   }, 
	Blitzcrank = {
		rocketgrabmissile={
			key="Q", range=925, radius=90, time=1, ss=true, block=true, perm=true, show=true, isline=true, cc=GRAB,
			type="stall",
		},
	},
	Brand = {
		brandblazemissile={range=1050, radius=70, time=1, ss=true, isline=true, block=true, cc=STUN},
		brandconflagration={},
		brandfissure={range=900, radius=250, time=4, ss=true, isline=false},
		brandwildfire={},
	},
	Braum = {
		spellnameq={range=1000, radius=175, time=1, ss=true, isline=true, block=true, cc=SLOW},
	},
	Caitlyn = {
		caitlynheadshotmissile={},
		caitlynentrapmentmissile={range=1000, radius=50, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		caitlynpiltoverpeacemaker={
			range=1300, radius=80, time=1, ss=true, isline=true, physical=true,
			type="stall"
		},
      caitlynentrapment={type="dash", ends="reverse", range=400},
      caitlynyordletrap={key="W"},
		caitlynaceinthehole={
			physical=true,
			type="stall", duration=2
		},
	},
	Cassiopeia = {
		cassiopeiamiasma={range=850, radius=175, time=1, ss=true, isline=false},
		cassiopeianoxiousblast={range=850, radius=75, time=1, ss=true, isline=false},
		cassiopeiatwinfang={},
		cassiopeiapetrifyinggaze={type="stall"},
	},
	Chogath = {
		rupture={
			range=950, radius=275, time=2, ss=true, show=true, isline=false, cc=SLOW,
			type="stall"
		},
		feralscream={cc=SILENCE},
		feast={},
	},
	Corki = {
		missilebarragemissile={range=1225, radius=80, time=1, ss=true, isline=true, block=true},
		missilebarragemissile2={range=1225, radius=100, time=1, ss=true, isline=true, block=true},
		carpetbomb={
			--range=800, radius=150, time=1, ss=true, isline=true, point=true,
			type="dash", ends="point", range=800
		},
	},
	Darius = {
		dariusaxegrabcone={
			key="E", range=540, perm=true, cc=GRAB, nodamage=true,
			type="stall"
		},
      dariusexecute={type="dash", ends="target"},
      dariuscleave={},
      dariusnoxiantacticsonh={},
	},
	Diana = {
		dianavortex={},
		dianaorbs={},
		dianaarc={range=900, radius=205, time=1, ss=true, isline=true},
      dianateleport={type="dash", ends="target"},
	},
	Draven = {
		dravendoubleshot={range=1050, radius=125, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		dravenrcast={range=50000, radius=100, time=4, ss=true, show=true, isline=true, physical=true},
	},
	DrMundo = {
		infectedcleavermissilecast={key="Q", range=1000, radius=60, time=1, ss=true, perm=true, block=true, isline=true, block=true, cc=SLOW},
	},
	Elise = {
		elisehumanq={},
      elisespiderqcast={type="dash", ends="target"},
      elisehumanw={},
      elisespiderw={},
		elisehumane={range=1075, radius=100, time=1, ss=true, block=true, perm=true, isline=true, block=true},
		elisespidereinitial={},
		elisespidere={},
		eliser={},
	},
	Ezreal = {
		ezrealmysticshot={key="Q", range=1100, radius=80, time=1, ss=true, block=true, perm=true, isline=true, block=true, physical=true},
		ezrealessenceflux={},
		ezrealessencefluxmissile={range=900, radius=100, time=1, ss=true, isline=true},
      ezrealarcaneshift={type="dash", ends="point", range=475},
		ezrealtrueshotbarrage={
			range=50000, radius=150, time=4, ss=true, show=true, isline=true, dodgeByObject=true,
			type="stall", duration=1
		},
	},
	FiddleSticks = {
		terrify={cc=FEAR, nodamage=true},
      drain={type="stall"},
      drainchannel={type="stall"},
		crowstorm={
			range=800, radius=300, time=1.5, ss=true, isline=false,
			type="dash", ends="point"
		},
		fiddlesticksdarkwind={cc=SILENCE},
	},
   Fiora={
      fioraq={type="dash", ends="target"},
      fiorariposte={},
      fioraflurry={},
      fioradance={},
   },
	Fizz = {
		fizzmarinerdoom={range=1275, radius=100, time=1.5, ss=true, isline=true, point=true, block=true, cc=SLOW},
		fizzjump={},
		fizzpiercingstrike={},
		fizzseastonepassive={},
		fizzjumptwo={},
		fizzjumpbuffer={},
	},
	Galio = {
		galioresolutesmite={range=905, radius=200, time=1.5, ss=true, isline=false, cc=SLOW},
		galiorighteousgust={range=1000, radius=120, time=1.5, ss=true, isline=true},
      galioidolofdurand={type="stall"},
      galiobulwark={},
	},
	Gangplank = {
		parley={physical=true},
		removescurvy={},
		raisemorale={},
	},
	Garen = {
		garenq={},
		garenw={},
		garene={},
		garenr={},
	},
	Gnar = {
		gnarq={},
		gnarbigq={},
		gnarbigw={},
		gnare={},
		gnarbige={},
		gnarr={},
	},
	Graves = {
		gravesclustershot={range=750, radius=50, time=1, ss=true, isline=true, physical=true},
		gravessmokegrenade={range=700, radius=275, time=1.5, ss=true, isline=false},
      gravesmove={type="dash", ends="max", range=425},
		graveschargeshot={range=1000, radius=110, time=1, ss=true, isline=true, physical=true},
	},
	Gragas = {
		gragasq={range=850, radius=320, time=2.5, ss=true, show=true, isline=false},
		gragasw={},
		gragase={range=650, radius=150, time=1.5, ss=true, isline=true, point=true, block=true, cc=STUN},
		gragasexplosivecask={range=1050, radius=400, time=1.5, ss=true, isline=false, cc=KNOCK},
	},
   Hecarim={
      hecarimult={type="dash", ends="point", range=1000},
   },
	Heimerdinger = {
		ch1concussiongrenade={range=950, radius=225, time=2, ss=true, show=true, isline=false, cc=STUN},
		hextechmicrorockets={},
	},
	Irelia = {
		ireliatranscendentblades={range=1200, radius=80, time=0.8, ss=true, isline=true},
		ireliaequilibriumstrike={cc=STUN},
      ireliagatotsu={type="dash", ends="target"},
	},
	Janna = {
		howlinggale={range=1700, radius=100, time=3, ss=true, show=true, isline=true, dodgeByObject=true},
		sowthewind={cc=SLOW},
      reapthewhirlwind={type="stall"},
	},
	JarvanIV = {
		jarvanivdragonstrike={range=770, radius=70, time=1, ss=true, isline=true, cc=KNOCK, physical=true},
		jarvanivdemacianstandard={range=830, radius=150, time=2, ss=true, isline=false},
		jarvanivcataclysm={
			range=650, radius=300, time=1.5, ss=true, isline=false, physical=true,
			type="dash", ends="point"
		},
	},
   Jax={
      jaxleapstrike={type="dash", ends="target", overShoot=-50},
      jaycetotheskies={type="dash", ends="target"},
   },
	Jayce = {
		jayceaccelerationgate={},
		jaycestancegth={},
		jaycestancehtg={},
		jaycetotheskies={},
		jaycestaticfield={},
		jaycehypercharge={},
		jaycethunderingblow={},
		jayceshockblast={range=1470, radius=100, time=1, ss=true, show=true, isline=true, block=true, physical=true},
	},
	Jinx = {
		jinxq={key="Q"},
      jinxw={type="stall"},
		jinxwmissile={key="W", range=1500, radius=80, time=1.5, ss=true, show=true, isline=true, block=true, perm=true, physical=true, cc=SLOW},
		jinxe={key="E"},
		jinxr={
			key="R", range=50000, radius=150, time=4, ss=true, show=true, isline=true, physical=true, dodgeByObject=true,
			type="stall"
		},
	},
	Karma = {

	},
	Karthus = {
		laywaste={range=875, radius=150, time=1, ss=true, isline=false},
		fallenone={},
	},
	Kassadin = {
		nulllance={cc=SILENCE},
		forcepulse={cc=SLOW},
		riftwalk={
			range=700, radius=150, time=1, ss=true, isline=true, point=true,
			type="dash", ends="point"
		},
	},
	Katarina = {
		katarinaq={},
		katarinaw={},
      katarinae={type="dash", ends="target"},
      katarinar={type="stall"},
	},
	Kayle = {
		judicatorreckoning={cc=SLOW},
	},	
	Kennen = {
		kennenshurikenhurlmissile1={range=1050, radius=75, time=1, ss=true, isline=true, block=true},
		kennenshurikenstorm={}, --TODO
	},
	Khazix = {
		khazixw={range=1000, radius=120, time=0.5, ss=true, isline=true, cc=SLOW, physical=true},
		khazixwlong={range=1000, radius=150, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		khazixe={
			range=600, radius=200, time=1, ss=true, isline=false, physical=true,
			type="dash", ends="point"
		},
		khazixelong={
			range=900, radius=200, time=1, ss=true, isline=false, physical=true,
			type="dash", ends="point"
		},
		khazixeevo={},
	},
	KogMaw = {
		kogmawq={},--TODO
		kogmawqmis={},
		kogmawvoidooze={},
		kogmawvoidoozemissile={range=1150, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		kogmawlivingartillery={range=2200, radius=200, time=1.5, ss=true, show=true, isline=false},
		kogmawbioarcanebarrage={},
	},
	Leblanc = {
		leblancsoulshackle={range=1000, radius=80, time=1, ss=true, isline=true, block=true, cc=BIND},
		leblancsoulshacklem={range=1000, radius=80, time=1, ss=true, isline=true, block=true, cc=BIND},
		leblancslide={
			range=600, radius=250, time=1, ss=true, isline=false,
			type="dash", ends="point"
		},
		leblancslidem={
			range=600, radius=250, time=1, ss=true, isline=false,
			type="dash", ends="point"
		},
		leblancslidereturn={range=1000, radius=50, time=1, ss=true, isline=false},
		leblancslidereturnm={range=1000, radius=50, time=1, ss=true, isline=false},
	},
	LeeSin = {
		blindmonkqone={key="Q", range=975, radius=150, time=1, ss=true, block=true, perm=true, isline=true, block=true, physical=true},
		blindmonkrkick={range=1200, radius=100, time=1, ss=true, isline=true, physical=true},
      blindmonkqtwo={type="dash", ends="target"},
      blindmonkwone={type="dash", ends="target"},
	},
	Leona = {
		leonazenithblademissile={range=700, radius=150, time=1, ss=true, isline=true},
      leonazenithblade={}, --{type="dash", ends="target?"}, -- TODO
      leonasolarbarrier={},
		leonasolarflare={cc=STUN},
	},
	Lissandra = { -- todo dash
		lissandraq={},
		lissandraqmissile={range=725, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		lissandraw={},
		lissandrae={range=1050, radius=100, time=1.5, ss=true, isline=true},
		lissandraemissile={},
		lissandrar={},
	},
	Lucian = {
		lucianq={range=1100, radius=100, time=0.75, ss=true, isline=true, physical=true},
		lucianw={range=1000, radius=150, time=1.5, ss=true, isline=true, physical=true},
      luciane={type="dash", ends="point", range=450},
		lucianr={range=1400, radius=250, time=3, ss=true, isline=true, physical=true},
	},
	Lux = {
		luxlightbinding={key="Q", range=1175, radius=150, time=1, ss=true, isline=true, cc=BIND},
		luxlightstriketoggle={},
		luxlightstrikekugel={range=1100, radius=300, time=2.5, ss=true, show=true, isline=false, cc=SLOW},
		luxmalicecannon={
			range=3000, radius=180, time=1.5, ss=true, isline=true,
			type="stall"
		},
		luxmalicecannonmis={},
		luxprismaticwave={},
	},
	Lulu = {
		luluq={range=925, radius=50, time=1, ss=true, isline=true, cc=SLOW},
	},
	Malphite = {
		seismicshard={cc=SLOW},
		ufslash={
			range=1000, radius=325, time=1, ss=true, show=true, isline=false, cc=KNOCK,
			type="dash", ends="point"
		},
		landslide={},
	},
	Malzahar = {
		alzaharcallofthevoid={range=900, radius=100, time=1, ss=true, isline=false, cc=SILENCE},
		alzaharnullzone={range=800, radius=250, time=1, ss=true, isline=false},
		alzaharmaleficvisions={},
      alzaharnethergrasp={
	      cc=STUN,
      	type="stall"
      },
	},
	Maokai = {
	 	maokaiunstablegrowth={
	 		cc=STUN,
	 		type="dash", ends="target"
	 	},
		maokaitrunklinemissile={range=600, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		maokaisapling2={range=1100, radius=350, time=1, ss=true, isline=false},
	},
   MasterYi={
      meditate={type="stall"},
   },
	MissFortune = {
		missfortunericochetshot={physical=true},
		missfortunescattershot={range=800, radius=400, time=3, ss=true, isline=false},
      missfortunebullettime={tupe="stall"},
      missfortuneviciousstrikes={},
	},
	Morgana = {
		darkbindingmissile={key="Q", range=1300, radius=110, time=1.5, ss=true, show=true, perm=true, block=true, isline=true, cc=BIND},
		tormentedsoil={range=900, radius=300, time=1.5, ss=true, isline=false},
		blackshield={},
		soulshackles={},
	},
	Nami = {
		namiq={range=875, radius=200, time=1.5, ss=true, show=true, isline=false, cc=STUN},
		namiqmissile={}, --TODO
		namir={range=2550, radius=350, time=3, ss=true, isline=true, cc=KNOCK},
		namirmissile={},
		namiw={},
		namie={},
	},
	Nasus = {
		nasusw={cc=SLOW, nodamage=true},
		nasusq={}, -- siphon
		nasuse={}, -- spirit fire
		nasusr={},
	},
	Nautilus = {
		nautilusanchordrag={key="Q", range=950, radius=80, time=1.5, ss=true, perm=true, block=true, isline=true},
		nautilusgrandline={cc=KNOCK},
	},
	Nidalee = {
		javelintoss={key="Q", range=1500, radius=40, time=1.5, ss=true, block=true, perm=true, show=true, isline=true},
      pounce={type="dash", ends="max", range=375},
      bushwhack={},
      aspectofthecougar={},
      swipe={},
      takedown={},
      primalsurge={},
	},
	Nocturne = {
		nocturneduskbringer={range=1200, radius=150, time=1.5, ss=true, isline=true, physical=true},
	},
   Nunu={
      consume={type="stall"},
      absolutezero={type="stall"},
      iceblast={},
      bloodboil={},
   },
	Olaf = {
		olafaxethrow={range=1000, radius=100, time=1.5, ss=true, isline=true, point=true, cc=SLOW, physical=true},
		olafaxethrowcast={},
		olafrecklessstrike={},
		olaffrenziedstrikes={},
		olafragnarok={},
	},
	Orianna = {
		orianaizunacommand={range=825, radius=90, time=1.5, ss=true, isline=false},
	},
	Pantheon = {
		pantheon_throw={physical=true},
      pantheonw={type="dash", ends="target", overShoot=-50},
	},
   Poppy={
      poppyheroiccharge={type="dash", ends="target", overShoot=300},
   },
  	Quinn = {
  		quinnq={},
		quinnqmissile={range=1025, radius=40, time=1, ss=true, isline=true, cc=BLIND, physical=true},
		quinnvalorq={},
		quinnw={},
		quinne={},
		quinnwenhanced={},
		quinnvalore={},
		quinnr={},
	},
	Rammus = {
		puncturingtaunt={cc=TAUNT, nodamage=true},
	},
	Renekton = {
		-- RenektonSliceAndDice={range=450, radius=80, time=1, ss=true, isline=true, physical=true},
		-- renektondice={range=450, radius=80, time=1, ss=true, isline=true, physical=true},
      renektonsliceanddice={type="dash", ends="max", range=450},
      renektondice={type="dash", ends="max", range=450},
  	},
	Rengar = {
		rengare={cc=STUN, physical=true},
	},
   Riven={
      rivenfeint={type="dash", ends="max", range=325},
      rivenmartyr={},
      riventricleave={},
      rivenfengshuiengine={},
      rivenizunablade={},
   },
 	Rumble = {
		rumblegrenademissile={range=1000, radius=100, time=1.5, ss=true, isline=true},
		rumblecarpetbomb={range=1700, radius=100, time=1.5, ss=true, isline=true},
	},
	Ryze = {
		runeprison={cc=BIND},
		overload={speed=1400},
		spellflux={},
		desperatepower={},
	},
	Sejuani = {
		sejuaniglacialprison={range=1150, radius=180, time=1, ss=true, isline=true, cc=STUN},
		sejuaninorthernwinds={},
		sejuaniwintersclaw={},
		sejuaniarcticassault={},
		sejuaniglacialprisonstart={},
		sejuaniglacialprisoncast={},
	},
	Shaco = {
		deceive={
			range=400, radius=100, time=3.5, ss=true, isline=false, nodamage=true,
			type="dash", ends="point"
		},
		hallucinatefull={},
	},
	Shen = {
		shenshadowdash={
			range=600, radius=150, time=1, ss=true, isline=true, point=true, cc=TAUNT, nodamage=true,
			type="dash", ends="max"
		},
      shenstandunited={type="stall"},
	},
	Shyvana = {
   	shyvanatransformcast={type="dash", ends="point", range=1000},	
		shyvanatransformleap={range=925, radius=150, time=1.5, ss=true, isline=true},
		shyvanafireball={},
		shyvanafireballdragon2={},
		shyvanafireballmissile={range=1000, radius=80, time=1, ss=true, isline=true},
		shyvanaimmolationaura={},
		shyvanaimmolatedragon={},
	},
	Sion = {
		sionq={type="stall"},
  	},
	Sivir = {
		spiralblade={key="Q", range=1000, radius=100, time=1, ss=true, isline=true, physical=true},
	},
	Singed = {
		megaadhesive={range=1000, radius=350, time=1.5, ss=true, isline=false, cc=SLOW},
		poisontrail={},
		fling={},
	},
	Skarner = {
		skarnerfracture={range=600, radius=100, time=1, ss=true, isline=true},
		skarnerimpale={cc=GRAB},
	},
	Sona = {
		sonaq={},
		sonaw={},
		sonae={},
		sonar={range=1000, radius=350, time=1, ss=true, isline=true, cc=STUN},
	},
	Soraka = {
		sorakaq={},
		sorakaw={},
		sorakae={},
		sorakar={},
	},
	Swain = {
		swainshadowgrasp={range=900, radius=265, time=1.5, ss=true, isline=false, cc=STUN},
	},
	Syndra = {
		syndraq={range=800, radius=200, time=1, ss=true, isline=false},
		syndraw={},
		syndrawcast={range=950, radius=200, time=1, ss=true, isline=false, cc=SLOW},
		syndrae={range=650, radius=100, time=0.5, ss=true, isline=true, cc=STUN},
		syndrar={},
	},
	Talon={
		taloncutthroat={type="dash", ends="target"},
		talonrake={},
		talonnoxiandiplomacy={},
		talonshadowassault={},
		talonrakemissileone={},
	},
	Taric = {
		dazzle={cc=STUN},
	},
	Teemo = {
		movequick={},
		blindingdart={cc=BLIND},
		bantamtrap={},
	},
	Thresh = {
		threshq={key="Q", range=1100, radius=100, time=1.5, ss=true, show=true, block=true, perm=true, isline=true, cc=STUN},
		threshqinternal={},
		threshqleap={--[[type="dash"]]},
		threshw={},
      threshe={type="stall"},
      threshrpenta={type="stall"},
  	},
	Tristana = {
		rapidfire={},
		detonatingshot={},
		rocketjump={
			range=900, radius=200, time=1, ss=true, isline=false,
			type="dash", ends="point"
		},
		bustershot={cc=KNOCK},
	},
	Tryndamere = {
		slash={
			range=660, radius=100, time=1, ss=true, isline=true, point=true, physical=true,
			type="dash", ends="point"
		},
	},
	TwistedFate = {
		redcard={cc=SLOW},
		yellowcard={cc=STUN},
		wildcards={range=1450, radius=80, time=1, ss=true, show=true, isline=true},
	},
	Twitch = {
		twitchvenomcask={cc=SLOW, nodamage=true},
	},
	Urgot = {
		urgotheatseekingmissile={},
		urgotheatseekinghomemissile={},
		urgotheatseekinglinemissile={range=1000, radius=80, time=0.8, ss=true, isline=true, block=true, physical=true},
		urgotplasmagrenade={range=950, radius=300, time=1, ss=true, isline=false, physical=true},
		urgotplasmagrenadeboom={},
		urgotterrorcapacitoractive2={},
		urgotswap2={},
	},
	Vayne = {
		vaynecondemn={cc=KNOCK, physical=true},
		vaynecondemnmissile={},
      vaynetumble={type="dash", ends="max", range=300},
      vayneinquisition={},
	},
	Varus = {
		varusq={range=1475, radius=50, time=1, ss=true, isline=true, physical=true},
		varusr={range=1075, radius=80, time=1.5, ss=true, isline=true, cc=STUN},
	},
	Veigar = {
		veigarbalefulstrike={},
		veigardarkmatter={range=900, radius=225, time=2, ss=true, show=true, isline=false},
		veigareventhorizon={cc=STUN},	
		veigarprimordialburst={},
	},
   Velkoz={
   	-- ult={type="stall"},
   	-- TODO get obj for channel
   	velkozq={},
   	velkozw={},
   	velkoze={},
   	velkozr={type="stall"},
	},	
	Volibear = {
		volibearq={cc=KNOCK, physical=true},
		volibearw={},
		volibeare={},
		volibearr={}
	},
	Vi = {
		viq={range=900, radius=150, time=1, ss=true, isline=true, physical=true}, -- TODO dash stuff
		assaultandbattery={cc=KNOCK, physical=true},
	},
	Viktor = {
		--ViktorDeathRay={range=700, radius=80, time=2, ss=true, isline=true},
	},
   Warwick={
   	hungeringstrike={key="Q"},
      infiniteduress={type="dash", ends="target"},
      infiniteduresschannel={},
      hunterscall={key="W"},
      bloodscent={},
   },	
   MonkeyKing={
   	monkeykingnimbus={type="dash", ends="target"},
	},
	Xerath = {
		xerathlocuspulse={},
		xerathmagespear={},
		xeratharcanopulse2={range=1500, radius=80, time=1, ss=true, show=true, isline=true},
		xeratharcanebarrage2={range=1100, radius=200, time=1, ss=true, isline=false},
		xerathrmissilewrapper={range=5600, radius=150, time=1, ss=true, isline=false},
		xerathlocusofpower2={type="stall"},
      xeratharcanopulsechargeup={type="stall"},
  	},
   XinZhao={
      xenzhaosweep={type="dash", ends="target"},
      xenzhaobattlecry={},
   },
   Yasuo={
      yasuodashwrapper={type="dash", ends="max", range=300},
   },
  	Zac = {
		zacq={range=550, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		zace={range=1550, radius=200, time=2, ss=true, isline=false, cc=KNOCK},
	},
	Zed = {
		zedshuriken={range=900, radius=100, time=1, ss=true, isline=true, physical=true},
		zedshadowdash={range=550, radius=150, time=1, ss=true, isline=true, point=true, physical=true},
		zedw2={range=550, radius=150, time=0.5, ss=true, isline=false, physical=true},
		zedpbaoedummy={},
		zedult={},
		zedr2={},
	},
	Ziggs = {
		ziggsq={range=1100, radius=150, time=1.5, ss=true, show=true, isline=true, point=true, block=true},
		ziggsw={range=1000, radius=225, time=1, ss=true, isline=false, cc=KNOCK},
		ziggse={range=900, radius=250, time=1, ss=true, isline=false, cc=SLOW},
		ziggsr={range=5300, radius=550, time=3, ss=true, isline=false},
	},
	Zilean = {

	},
	Zyra = {
		zyraqfissure={range=800, radius=275, time=1.5, ss=true},
		zyragraspingroots={range=1100, radius=90, time=2, ss=true, show=true, isline=true, cc=BIND},
	},
}

function GetSpellDef(name, spellName)
	local spellTable = SPELL_DEFS[name]
	if spellTable then
		local spellDef = spellTable[string.lower(spellName)]
		if spellDef then
			spellDef.name = spellName
			if not spellDef.time then
				spellDef.time = 1
			end
			if not spellDef.radius then
				spellDef.radius = 0
			end
			spellDef.radius = spellDef.radius or spellDef.width * 2
			return spellDef
		else
			for _,ignored in ipairs(ignoredSpells) do
				if find(spellName, ignored) then
					return
				end
			end
			pp("No def for "..name)
			pp(string.lower(spellName))
			PlaySound("Beep")
			table.insert(ignoredSpells, spellName)
		end
	else
		pp("No defs for "..name)
	end
	return nil
end
