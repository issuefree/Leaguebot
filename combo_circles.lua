--OneComboKill Circle Drawer
--Draws circles around enemy heroes you can kill with one combo
--Not all items have been added, if you wish to add more you can find some item codes here:http://na.leagueoflegends.com/board/showthread.php?p=31604980#31604980
--

require "basic_functions"
require "spell_Damage"
local script_loaded=1
local toggle_timer=os.clock()
local ignite_letter=nil  --put 'D' ect if you want instead of nil

function checkItemReady(item)
	if GetInventoryItem(1) == item and IsSpellReady('1') == 1 then 
		return 1;
	elseif GetInventoryItem(2) == item and IsSpellReady('2') == 1 then 
		return 1;
	elseif GetInventoryItem(3) == item and IsSpellReady('3') == 1 then 
		return 1;
	elseif GetInventoryItem(4) == item and IsSpellReady('4') == 1 then 
		return 1;
	elseif GetInventoryItem(5) == item and IsSpellReady('5') == 1 then 
		return 1;
	elseif GetInventoryItem(6) == item and IsSpellReady('6') == 1 then 
		return 1;
	end
	return 0;
end

function sample_CallBackOneComboKill()
	CLOCK=os.clock()
	local p=GetSelf()
	local max_heroes=objManager:GetMaxHeroes()
	local player_team=p.team
	--iihh=44t
	local key=GetScriptKey();
	if (IsKeyDown(key)~=0 and CLOCK-toggle_timer>1.2 and key~=0) then
		toggle_timer=CLOCK
		script_loaded= ((script_loaded+1)%2)
	end
	if (script_loaded==1) then
		if (CLOCK-toggle_timer<12) then
			DrawText("OneComboKill Circles loaded",10,40,0xFF00EE00);
			DrawText("Press key again to toggle",10,50,0xFF00EE00);
		end
	elseif (CLOCK-toggle_timer<6) then
		DrawText("OneComboKill Circles unloaded",10,40,0xFFFFFF00);
		return
	end
	local marker=0;
	for i= 1,max_heroes,1 do
		local h=objManager:GetHero(i)
		if (h.team ~= player_team and h.visible==1 and h.invulnerable==0) then
			local name=h.name
			local qdmg=getDmg("Q",h,p)*CanUseSpell('Q');
			local wdmg=getDmg("W",h,p)*CanUseSpell('W');
			local edmg=getDmg("E",h,p)*CanUseSpell('E');
			local rdmg=getDmg("R",h,p)*CanUseSpell('R');
			local autodmg=getDmg("AD",h,p);
			local ignitedmg=0;
			if (ignite_letter ~= nil) then
				ignitedmg=getDmg("IGNITE",h,p)*IsSpellReady(ignite_letter);
			end
			local dfgdmg=getDmg("DFG",h,p)*checkItemReady(3128);
			local trinitydmg=getDmg("TRINITY",h,p)*checkItemReady(3078);
			local liandrydmg=getDmg("LIANDRYS",h,p)*checkItemReady(3151);
			local sheendmg=getDmg("SHEEN",h,p)*checkItemReady(3057);
			local totaldamage=qdmg+wdmg+edmg+rdmg+dfgdmg+trinitydmg+liandrydmg+sheendmg+autodmg+ignitedmg;
			--DrawText("to:" .. name .. " " .. tostring(math.floor(totaldamage)), 10,200+marker,0xFFFFFF00);
			marker=marker+20;
			if (h.health<totaldamage) then
				DrawCircleObject(h,202,1);
				DrawCircleObject(h,204,2);
				DrawCircleObject(h,206,2);
				DrawCircleObject(h,208,2);
				DrawCircleObject(h,210,1);
			end
		end
	end
end
SetTimerCallback("sample_CallBackOneComboKill")
			