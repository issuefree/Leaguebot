require "issuefree/basicUtils"
require "issuefree/telemetry"

local PREDICTION_DEFS = {
   Aatrox={
      AatroxQ={type="dash", ends="point", max=650},
      keys={"Q"}
   },
   Ahri={
      AhriTumble={type="dash", ends="max", max=450, key="R"},
      keys={"R"}
   },
   Akali={
      AkaliShadowDance={type="dash", ends="target", key="R"},
   },
   Alistar={
      Headbutt={type="dash", ends="target"},
   },
   Amumu={
      BandageToss={type="dash", ends="target"},
   },
   Azir={
      keys={"E"} -- TODO shifting sands
   }, 
   Blitzcrank={
      RocketGrab={type="stall"},
   },
   Braum={ 
      keys={"W"} -- TODO stand behind me
   }, 
   Caitlyn={
      CaitlynPiltoverPeacemaker={type="stall"},
      CaitlynEntrapment={type="dash", ends="reverse", max=400},
      CaitlynAceintheHole={type="stall", duration=2},
   },
   Cassiopeia={
      CassiopeiaPetrifyingGaze={type="stall"},
   },
   Chogath={
      Rupture={type="stall"},
      keys={"Q"}
   },
   Corki={
      CarpetBomb={type="dash", ends="point", max=800},
   },
   Darius={
      DariusAxeGrabCone={type="stall"},
      DariusExecute={type="dash", ends="target"},
   },
   Diana={
      DianaTeleport={type="dash", ends="target"},
      keys={"R"}      
   },
   Elise={
      EliseSpiderQCast={type="dash", ends="target"},
   },
   Ezreal={
      EzrealArcaneShift={type="dash", ends="point", max=475},
      EzrealTrueshotBarrage={type="stall", duration=1},
   },
   FiddleSticks={
      Drain={type="stall"},
      Crowstorm={type="dash", ends="point", max=800},
   },
   Fiora={
      FioraQ={type="dash", ends="target"},
      keys={"Q"}
   },
   Galio={
      GalioIdolOfDurand={type="stall"},
   },
   Gragas={
   	-- GragasE
   }, 
   Graves={
      GravesMove={type="dash", ends="max", max=425}, -- TODO spellname
   },
   Hecarim={
      HecarimUlt={type="dash", ends="point", max=1000},
      keys={"R"}
   },
   Irelia={
      IreliaGatotsu={type="dash", ends="target"},
   },
   Janna={
      ReapTheWhirlwind={type="stall"},
   },
   JarvanIV={
      JarvanIVCataclysm={type="dash", ends="point", max=650},
   },
   Jax={
      JaxLeapStrike={type="dash", ends="target"},
   },
   Jayce={
      JayceToTheSkies={type="dash", ends="target"},
      keys={"Q"}
   },
   Jinx={
      jinxw={type="stall"},
      jinxr={type="stall"},
      keys={"W","R"}      
   },
   Kassadin={
      RiftWalk={type="dash", ends="point", max=700},
      keys={"R"}
   },
   Katarina={
      KatarinaE={type="dash", ends="target"},
      KatarinaR={type="stall"},
   },
   Khazix={
      KhazixE={type="dash", ends="point", max=600},
      khazixelong={type="dash", ends="point", max=900},
      keys={"E"}
   },
   Leblanc={
      LeblancSlide={type="dash", ends="point", max=600},
      LeblancSlideM={type="dash", ends="point", max=600},
   },
   LeeSin={
      blindmonkqtwo={type="dash", ends="target"},
      BlindMonkWOne={type="dash", ends="target"},
      keys={"Q", "W"}
   },
   Leona={ 
      -- LeonaZenithBlade={type="dash", ends="target?"}, -- TODO
   }, 
   Lissandra={}, -- TODO
   Lucian={
      LucianE={type="dash", ends="point", max=450},
   },
   Lux={
      LuxMaliceCannon={type="stall"},
   },
   Malphite={
      UFSlash={type="dash", ends="point", max=1000},
   },
   Malzahar={
      AlZaharNetherGrasp={type="stall"},
   },
   Maokai={
      MaokaiUnstableGrowth={type="dash", ends="target"},
   },
   MasterYi={
      Meditate={type="stall"},
   },
   MissFortune={
      MissFortuneBulletTime={tupe="stall"},
   },
   Nidalee={
      Pounce={type="dash", ends="max", max=375},
      keys={"W"}
   },
   Nocturne={
      -- NocturneParanoia={type="dash", ends="target"},
      keys={"R"}
   },
   Nunu={
      Consume={type="stall"},
      AbsoluteZero={type="stall"},
   },
   Pantheon={
      PantheonW={type="dash", ends="target"},
   },
   Poppy={
      PoppyHeroicCharge={type="dash", ends="target", overShoot=300},
      keys={"E"}
   },
   Renekton={
      RenektonSliceAndDice={type="dash", ends="max", max=450},
      renektondice={type="dash", ends="max", max=450},
   },
   Riven={
      RivenFeint={type="dash", ends="max", max=325},
      keys={"E"}
   },
   Sejuani={
   	-- SejuaniArcticAssault
	},
   Shaco={
      Deceive={type="dash", ends="point", max=400},
      keys={"Q"}
   },
   Shen={
      ShenShadowDash={type="dash", ends="max", max=600},
      ShenStandUnited={type="stall"},
   },
   Shyvana={
   	ShyvanaTransformCast={type="dash", ends="point", max=1000},
	},
	Sion={
		-- DecimatingSmash={type="stall"},
      keys={"Q"}
	},
	Talon={
		TalonCutthroat={type="dash", ends="target"},
      keys={"E"}
	},
   Thresh={
      threshrpenta={type="stall"},
      threshe={type="stall"},
      keys={"Q","E"}
   },
   Tristana={
      RocketJump={type="dash", ends="point", max=900},
   },
   Tryndamere={
   	-- spinningSlash={type="dash", ends="point", max=660},
      keys={"E"}   	
	},
   Vayne={
      VayneTumble={type="dash", ends="max", max=300},
   },
   Velkoz={
   	-- ult={type="stall"},
   	-- TODO get obj for channel
      keys={"R"}
	},
	Vi={
		-- ViQ=725,
	},
   Warwick={
      InfiniteDuress={type="dash", ends="target"},
   },
   Wukong={
   	MonkeyKingNimbus={type="dash", ends="target"},
	},
	Xerath={
		XerathLocusOfPower2={type="stall"},
      XerathArcanopulseChargeUp={type="stall"},
	},
   XinZhao={
      XenZhaoSweep={type="dash", ends="target"},
   },
   Yasuo={
      YasuoDashWrapper={type="dash", ends="max", max=300},
      keys={"E"}
   },
}

function PredictEnemy(unit, spell)
   if IsEnemy(unit) then
      local enemy = PREDICTION_DEFS[unit.name]
      if enemy then
         local def = enemy[spell.name]
         if def and def.type then
            local predName = unit.name..".pred"
            local pred = PersistTemp(predName, def.duration or .5)
            pred.enemy = unit
            local point
            if def.type == "dash" then
               if def.ends == "max" then
                  point = Projection(unit, spell.endPos, def.max)
               elseif def.ends == "reverse" then
                  point = Projection(spell.endPos, unit, def.max)
               elseif def.ends == "point" then
                  if GetDistance(unit, spell.endPos) > def.max then
                     point = Projection(unit, spell.endPos, def.max)
                  else
                     point = Point(spell.endPos)
                  end
               elseif def.ends == "target" then
                  if def.overShoot then
                     point = OverShoot(unit, spell.target, def.overShoot)
                  else
                     point = Point(spell.target)
                  end
               end
            elseif def.type == "stall" then
               point = Point(unit)
            end
            pred.x = point.x
            pred.y = point.y
            pred.z = point.z
         end
      end
   end
end

function checkSpells()
	for _,hero in ipairs(concat(ALLIES, ENEMIES)) do
		local defs = PREDICTION_DEFS[hero.name]
		if defs and defs.keys then
			for _,key in ipairs(defs.keys) do
				local sn = hero["SpellName"..key]
				if not defs[sn] then
					pp(hero.name.."."..key)
					pp(sn)
					defs[sn] = {}
				end
			end
		end
	end
end

function Tick()
	checkSpells()
end

SetTimerCallback("Tick")


