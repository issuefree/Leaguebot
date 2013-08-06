require "Utils"
require "timCommon"

local cleanse = {"stun", "banish", "taunt", "fear", "charm", "shackle", "binding", "prison", "wither", "ultwrap", "root", "RengarEMax", "VarusRHitFlash"} 
local byAbil = concat({"nethergrasp", "infiniteduress", "skarner_ult_tail_tip", "SwapArrow"}, cleanse)
local byItem  = concat({"mordekaiser_cotg_tar", "Fizz_UltimateMissle_Orbit"}, byAbil)

local cleanseKey

if me.SummonerD == "SummonerBoost" then
   cleanseKey = "D"
elseif me.SummonerF == "SummonerBoost" then
   cleanseKey = "F" 
end

local function cleanseObj(object)
	if ModuleConfig.cleanse and GetDistance(object) < 75 then
		if me.name == "Gangplank" and 
		   CanUse("W") and 
		   ListContains(object.charName, byAbil) 
		then
			Cast("W", me)
			pp("Removed "..object.charName.." with oranges.")
			return
		end
		
		if me.name == "Olaf" and 
			ListContains(object.charName, byAbil) and
         CanUse("R") 
      then
			Cast("R", me)
			pp("Removed "..object.charName.." with Ragnarok.")
			return
		end
		
		if ListContains(object.charName, byItem) then
			UseItem("Quicksilver Sash", me)
			UseItem("Mercurial Scimitar", me)
			pp("Removed "..object.charName.." with QSS.")
			return
		end
		
		if cleanseKey and ListContains(object.charName, cleanse) then
			CastHotkey("SPELL"..cleanseKey..":WEAKALLY SMARTCAST")
			pp("Removed "..object.charName.." with Cleanse.")
		end
	end
end

ModuleConfig:addParam("cleanse", "Auto Cleanse", SCRIPT_PARAM_ONOFF, true)
ModuleConfig:permaShow("cleanse")

AddOnCreate(cleanseObj)