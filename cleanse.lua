require "Utils"
require "timCommon"

local cleanse = {"Stun_glb", "summoner_banish", "Global_Taunt", "Global_Fear", "Ahri_Charm_buf", "leBlanc_shackle_tar", "LuxLightBinding_tar", "RunePrison_tar", "DarkBinding_tar", "nassus_wither_tar", "Amumu_SadRobot_Ultwrap", "Amumu_Ultwrap", "maokai_elementalAdvance_root_01", "RengarEMax_tar", "VarusRHitFlash"} 
local byAbil = concat({"AlZaharNetherGrasp_tar", "InfiniteDuress_tar", "skarner_ult_tail_tip", "SwapArrow_red"}, cleanse)
local byItem  = concat({"summoner_banish", "mordekaiser_cotg_tar", "Fizz_UltimateMissle_Orbit", "Fizz_UltimateMissle_Orbit_Lobster"}, byAbil)

local cleanseKey

if me.SummonerD == "SummonerBoost" then
   cleanseKey = "D"
elseif me.SummonerF == "SummonerBoost" then
   cleanseKey = "F" 
end

local function cleanseObj(object)
	if GetDistance(object) < 25 and ModuleConfig.cleanse then

		if me.name == "Gangplank" and 
		   CanCastSpell("W") and 
		   ListContains(object.charName, byAbil) 
		then
			CastSpellTarget("W", me)
			return
		end
		
		if me.name == "Olaf" and 
			ListContains(object.charName, byAbil) and
         CanCastSpell("R") 
      then
         pp("here")
			CastSpellTarget("R", me)
			return
		end
		
		if ListContains(object.charName, byItem) then
			UseItem("Quicksilver Sash", me)
			UseItem("Mercurial Scimitar", me)
			return
		end
		
		if ListContains(object.charName, cleanse) then
			CastHotkey("SPELL"..cleanseKey..":WEAKALLY SMARTCAST")
		end
	end
end

ModuleConfig:addParam("cleanse", "Auto Cleanse", SCRIPT_PARAM_ONOFF, true)
ModuleConfig:permaShow("cleanse")

AddOnCreate(cleanseObj)