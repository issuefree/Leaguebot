require "Utils"
require 'spell_damage'
print=printtext
printtext("\nMaster JedYi\n")
printtext("\nBy Malbert\n")
printtext("\nVersion 4.6\n")

local target
local hasSheen = 0
local hasLich = 0
local hasTrinity = 0
local hasIceBorn = 0
local CLOCKM=os.clock()
local CLOCKU=os.clock()
local CLOCKT=os.clock()
local CLOCKF=os.clock()
local Wheal
local hpmarker
local ignitedamage
local mtarget
local ulting=false

local _registry = {}

--------Spell Stuff

local cc = 0
local skillshotArray = { 
}
local colorcyan = 0x0000FFFF
local coloryellow = 0xFFFFFF00
local colorgreen = 0xFF00FF00
local drawskillshot = false
local playerradius = 150
local skillshotcharexist = false
local dodgeskillshotkey = 74 -- dodge skillshot key J
local show_allies=0
local enemyinRange
local checkDie=false

--turret stuff

local SpawnturretR={}
local SpawnturretB={}
local TurretsR={}
local TurretsB={}
local enemyTurrets={}
local enemySpawn={}
local map = nil
printtext("\n" ..GetMap() .. "\n")


    if GetMap()==1 then 

        map = "SummonersRift"
		SpawnturretR = {"Turret_ChaosTurretShrine_A"}
		SpawnturretB = {"Turret_OrderTurretShrine_A"}
		TurretsR = {"Turret_T1_C_01_A","Turret_T1_C_02_A","Turret_T1_C_03_A","Turret_T1_C_04_A","Turret_T1_C_05_A","Turret_T1_C_06_A","Turret_T1_C_07_A","Turret_T1_L_02_A","Turret_T1_L_03_A","Turret_T1_R_02_A","Turret_T1_R_03_A"}
		TurretsB = {"Turret_T2_C_01_A","Turret_T2_C_02_A","Turret_T2_C_03_A","Turret_T2_C_04_A","Turret_T2_C_05_A","Turret_T2_L_01_A","Turret_T2_L_02_A","Turret_T2_L_03_A","Turret_T2_R_01_A","Turret_T2_R_02_A","Turret_T2_R_03_A"}

    elseif GetMap()==2 then
        map = "CrystalScar"
		SpawnturretR = {"Turret_ChaosTurretShrine_A","Turret_ChaosTurretShrine1_A"}
		SpawnturretB = {"Turret_OrderTurretShrine_A","Turret_OrderTurretShrine1_A"}
		TurretsR = {"OdinNeutralGuardian"}
		TurretsB = {"OdinNeutralGuardian"}
        
    elseif GetMap()==3 then
        map = "TwistedTreeline"
		SpawnturretR = {"Turret_ChaosTurretShrine_A"}
		SpawnturretB = {"Turret_OrderTurretShrine_A"}
		TurretsR = {"Turret_T1_R_02_A","Turret_T1_C_07_A","Turret_T1_C_06_A","Turret_T1_C_01_A","Turret_T1_L_02_A"}
		TurretsB = {"Turret_T2_L_01_A","Turret_T2_C_01_A","Turret_T2_L_02_A","Turret_T2_R_01_A","Turret_T2_R_02_A"}
        
    elseif GetMap()==0 then

	map = "ProvingGrounds" 
		SpawnturretR = {"Turret_ChaosTurretShrine_A"}
		SpawnturretB = {"Turret_OrderTurretShrine_A"}
		TurretsR = {"Turret_T1_C_07_A","Turret_T1_C_08_A","Turret_T1_C_09_A","Turret_T1_C_010_A"}
		TurretsB = {"Turret_T2_L_01_A","Turret_T2_L_02_A","Turret_T2_L_03_A","Turret_T2_L_04_A"}
	end

local turret = {}



	YiConfig = scriptConfig('Yi Config', 'Yiconfig')
	YiConfig:addParam('teamfight', 'AutoTeamFight', SCRIPT_PARAM_ONKEYDOWN, false, 84)
	YiConfig:addParam('move', 'Move To Cursor', SCRIPT_PARAM_ONKEYDOWN, false, 65)
	YiConfig:addParam('autoQ', 'AutoQ', SCRIPT_PARAM_ONKEYTOGGLE, false, 55)
	YiConfig:addParam('autoW', 'AutoWHeal', SCRIPT_PARAM_ONKEYTOGGLE, true, 56)
	YiConfig:addParam('autoE', 'AutoE', SCRIPT_PARAM_ONKEYTOGGLE, true, 57)
	YiConfig:addParam('autoQMrange', 'AutoQminionrange', SCRIPT_PARAM_ONKEYTOGGLE, false, 48)
	YiConfig:addParam("smite", "Smitesteal", SCRIPT_PARAM_ONKEYTOGGLE, true, 118)
	YiConfig:addParam('farm', 'AutoCreepFarm', SCRIPT_PARAM_ONKEYTOGGLE, false, 119)
	YiConfig:addParam('zh', 'Zhonyas', SCRIPT_PARAM_ONOFF, true)
	YiConfig:addParam('drawQ', 'DrawQsOnEnemies', SCRIPT_PARAM_ONOFF, true)
	YiConfig:addParam('autoQM3', 'AutoQminion3orLess', SCRIPT_PARAM_ONOFF, false)
	YiConfig:addParam('ultks', 'UltKillsteal', SCRIPT_PARAM_ONOFF, true)
	YiConfig:addParam('dokillsteal', 'Killsteal', SCRIPT_PARAM_ONOFF, false)
	YiConfig:addParam('ap', 'AP Yi?', SCRIPT_PARAM_ONOFF, true)
	YiConfig:permaShow('farm')
	YiConfig:permaShow('teamfight')
	YiConfig:permaShow('autoQ')
	YiConfig:permaShow('autoQMrange')
	YiConfig:permaShow('autoW')




function Run()
	enemyInRange = GetWeakEnemy('PHYS',800)

	ignite()
	
	if YiConfig.farm and not isMed() then autofarm() end
        if YiConfig.smite then smitesteal() end
	if IsChatOpen()==0 and YiConfig.teamfight then fight() end
	if IsChatOpen()==0 and YiConfig.move then Move() end
	if YiConfig.autoE and not isMed() then autoEattack() end
	if YiConfig.autoW then autohealW() end
	if YiConfig.autoQ then autoQ() end
	if YiConfig.autoQMrange then autoQM() end
	if YiConfig.ultks then Ultkillsteal() end
	if YiConfig.dokillsteal then killsteal() end
	if GetInventorySlot(3057)~=nil then 
	hasSheen = 1 
	else
	hasSheen = 0
	end
	if GetInventorySlot(3100)~=nil then 
	hasLich = 1 
	else
	hasLich = 0
	end
	if GetInventorySlot(3025)~=nil then 
	hasIceBorn = 1 
	else
	hasIceBorn = 0
	end
	if GetInventorySlot(3087)~=nil then 
	hasTrinity = 1 
	else
	hasTrinity = 0
	end
end

function OnCreateObj(obj)

		if obj ~= nil and GetD(obj,myHero)<10 then

		local s =obj.charName
            if s~=nil and string.find(s,"teleportarrive") ~= nil then    
                if (obj.x == myHero.x) and (obj.z == myHero.z) then
				CLOCKF=os.clock()
				--printtext("\n"..CLOCKF.."\n")   
                end
			end 
   
		end
	end


function OnProcessSpell(unit, spell)

end


function zhonyas()
	if GetInventorySlot(3157)~=nil then 
		k = GetInventorySlot(3157)
		CastSpellTarget(tostring(k),myHero)
	elseif GetInventorySlot(3090)~=nil then 
		k = GetInventorySlot(3090)
		CastSpellTarget(tostring(k),myHero)
	end
end


function isMed()
	if CLOCKM~=nil then
		if os.clock()>CLOCKM+5 then
		return false
		else
		return true
		end
	end
end

function smitesteal()
        if myHero.SummonerD == "SummonerSmite" then
                CastHotkey("AUTO 100,0 SPELLF:SMITESTEAL RANGE=800 TRUE COOLDOWN")
                return
        end
        if myHero.SummonerF == "SummonerSmite" then
                CastHotkey("AUTO 100,0 SPELLF:SMITESTEAL RANGE=800 TRUE COOLDOWN")
                return
        end
end

function Move()
	if not isMed() then MoveToMouse() end
end


function autofarm()

mtarget=GetLowestHealthEnemyMinion(700)

if mtarget~=nil and myHero.dead==0 and not isMed() then
local AA = CalcDamage(mtarget,myHero.addDamage+myHero.baseDamage)
local Q = CalcMagicDamage(mtarget,(50+(50*GetSpellLevel('Q'))+myHero.ap)*CanUseSpell('Q'))
local tsafe=true

			local tfx,tfy,tfz = GetFireahead(mtarget,2,13)
			local tfa ={x=tfx,y=tfy,z=tfz}
			run_every(1,findTurret)
				for _, tur in ipairs(enemyTurrets) do
					if tur~=nil then
						
						if mtarget~=nil and GetD(tur.object,tfa)>tur.range then
							tsafe=true
						elseif mtarget~=nil and GetD(tur.object,tfa)<=tur.range then
							tsafe=false
							break
						else
							tsafe=false
							break
						end
					end
				end				

	if GetD(mtarget,myHero)>myHero.range+50 then
		MoveToXYZ(mtarget.x,0,mtarget.z)
			if GetD(mtarget,myHero)<600 and mtarget.health<Q and CanUseSpell('Q')==1 then
				CastSpellTarget('Q', mtarget)
			end
		
	elseif  GetD(mtarget,myHero)<=myHero.range+50 and mtarget.health<Q and CanUseSpell('Q')==1 then
			CastSpellTarget('Q', mtarget)	
			
	elseif GetD(mtarget,myHero)<=myHero.range+50 and mtarget.health<AA then
			AttackTarget(mtarget)	

		
		
	--elseif GetD(mtarget,myHero)<=myHero.range+50 and mtarget.health>AA then
	--	StopMove()
	end	

end
end
------------------------------------------------------ Check If In Spell Stuff


------------------------------END Spell Callback Stuff
function IsMoving(slowtarget)
   local x, y, z = GetFireahead(slowtarget,1,99)
   local d = GetD({x=x, y=y, z=z},slowtarget)
   return d > 0 
end



function fight()
	if target ~= nil  then
			UseAllItems(target)
			CastSummonerExhaust(target)
			if CanCastSpell('R') and GetD(myHero, target) < 700 and not isMed() and ulting==false then
				CastSpellTarget('R', target)
				AttackTarget(target)
			
			
			elseif CanCastSpell('E') and GetD(myHero, target) < myHero.range+150 and not isMed() then
				CastSpellTarget('E', target)
				AttackTarget(target)
			
			
			elseif CanCastSpell('Q') and GetD(myHero, target) < 600 and not isMed() then
				CastSpellTarget('Q', target)
				AttackTarget(target)
			
			
			elseif CanCastSpell('W') and myHero.health<myHero.maxHealth*25/100 and not CanCastSpell('Q') then
				CastSpellTarget('W', target)
				return
			
			
			elseif GetD(myHero, target) < myHero.range+100 and not isMed() then
				AttackTarget(target)
			end
	

	elseif target == nil then
	if not isMed() then MoveToMouse() end
	end
	
	
end


function autoQ()

    if target ~= nil then
		if CanCastSpell('Q') and GetD(myHero, target) < 600 and not isMed() then
			CastSpellTarget('Q', target)
		end
    end

end

function autoQM()

	local enemyMinions = GetEnemyMinions(MINION_SORT_HEALTH_ASC)

	local mhtarget

	local tsafe=true
	if YiConfig.autoQM3==false then
		if targetQharass~=nil then
		for _, minion in pairs(enemyMinions) do
			if minion~=nil then
				local tfx,tfy,tfz = GetFireahead(minion,2,13)
				local tfa ={x=tfx,y=tfy,z=tfz}
				run_every(1,findTurret)
				for _, tur in ipairs(enemyTurrets) do
					if tur~=nil then
						
						if minion~=nil and GetD(tur.object,tfa)>tur.range then
							tsafe=true
						elseif minion~=nil and GetD(tur.object,tfa)<=tur.range then
							tsafe=false
							break
						else
							tsafe=false
							break
						end
					end
				end	
		
		
		
				if mhtarget==nil and tsafe==true and 75<GetD(minion,targetQharass) and GetD(minion,targetQharass)<650 then
					mhtarget=minion
				elseif mhtarget~=nil and tsafe==true and 75<GetD(minion,targetQharass) and GetD(minion,targetQharass)<650 and GetD(minion,myHero)<GetD(mhtarget,myHero)  then
					mhtarget=minion
				end
			end
		end
		end
	elseif YiConfig.autoQM3==true then
		local minioncount=0
		if targetQharass~=nil then
		for _, minion in pairs(enemyMinions) do
			if minion~=nil then
				if GetD(minion)<1200 then
					minioncount=minioncount+1
				end
				local tfx,tfy,tfz = GetFireahead(minion,2,13)
				local tfa ={x=tfx,y=tfy,z=tfz}
				run_every(1,findTurret)
				for _, tur in ipairs(enemyTurrets) do
					if tur~=nil then
						
						if minion~=nil and GetD(tur.object,tfa)>tur.range then
							tsafe=true
						elseif minion~=nil and GetD(tur.object,tfa)<=tur.range then
							tsafe=false
							break
						else
							tsafe=false
							break
						end
					end
				end	
		
		
		
				if mhtarget==nil and minioncount<4 and tsafe==true and 75<GetD(minion,targetQharass) and GetD(minion,targetQharass)<650 then
					mhtarget=minion
				elseif mhtarget~=nil and minioncount<4 and tsafe==true and 75<GetD(minion,targetQharass) and GetD(minion,targetQharass)<650 and GetD(minion,myHero)<GetD(mhtarget,myHero)  then
					mhtarget=minion
				elseif minioncount>=4 then
					mhtarget=nil
					break
				end
			end
		end
		end
	end

				
		if mhtarget~=nil and targetQharass~=nil and tsafe==true then
			if CanCastSpell('Q') and GetD(myHero, mhtarget) < 600 and GetD(myHero, mhtarget) < GetD(myHero,targetQharass) and not isMed() then
				CastSpellTarget('Q', mhtarget)
			end
		end
end


function autoEattack()

    if target ~= nil then
		if CanCastSpell('E') and GetD(myHero, target) < myHero.range+100 and not isMed() then
			CastSpellTarget('E', target)
		end
    end

end

function autohealW()

		if CanCastSpell('W') and (not IsMoving(myHero) or YiConfig.move or YiConfig.teamfight) and myHero.health<myHero.maxHealth*20/100 and os.clock()>CLOCKT+9 and os.clock()>CLOCKF+3 then
			CastSpellTarget('W', myHero)
		end


end

function Ultkillsteal()
	if target ~= nil then
		local E = (10+(5*GetSpellLevel("E")))*CanUseSpell("E")
		local AA = getDmg("AD",target,myHero)+(getDmg("SHEEN",target,myHero)*hasSheen)+(getDmg("LICHBANE",target,myHero)*hasLich)+(getDmg("ICEBORN",target,myHero)*hasIceBorn)+(getDmg("TRINITY",target,myHero)*hasTrinity)+E
		local Q = (getDmg("Q",target,myHero))*CanUseSpell('Q')
		local W	= (50+(150*GetSpellLevel('W'))+myHero.ap*2)*CanUseSpell('W')

		
		if CanUseSpell('R')==1 and ulting==false then

			if target.health<Q+AA+E+ignitedamage then	
				if CanCastSpell('R') then CastSpellTarget('R', target) 
				elseif CanCastSpell('Q') then CastSpellTarget('Q', target) 
				elseif CanCastSpell('E') then CastSpellTarget('E', target)
				elseif myHero.SummonerD == 'SummonerDot' then
					if IsSpellReady('D') and GetD(target)<600 then CastSpellTarget('D',target) end
				
				elseif myHero.SummonerF == 'SummonerDot' then
					if IsSpellReady('F') and GetD(target)<600 then CastSpellTarget('F',target) end
				else
					AttackTarget(target)
				end
			end
		elseif ulting==true then
			if target.health<Q+AA+E+ignitedamage then
				if CanCastSpell('Q') then CastSpellTarget('Q', target) 
				elseif CanCastSpell('E') then CastSpellTarget('E', target)
				elseif myHero.SummonerD == 'SummonerDot' then
					if IsSpellReady('D') and GetD(target)<600 then CastSpellTarget('D',target) end
				
				elseif myHero.SummonerF == 'SummonerDot' then
					if IsSpellReady('F') and GetD(target)<600 then CastSpellTarget('F',target) end
				else
					AttackTarget(target)
				end
			end
		end
		
	end
end


function killsteal()
	if target ~= nil then
		local E = (10+(5*GetSpellLevel("E")))*CanUseSpell("E")
		local AA = getDmg("AD",target,myHero)+(getDmg("SHEEN",target,myHero)*hasSheen)+(getDmg("LICHBANE",target,myHero)*hasLich)+(getDmg("ICEBORN",target,myHero)*hasIceBorn)+(getDmg("TRINITY",target,myHero)*hasTrinity)+E
		local Q = (getDmg("Q",target,myHero))*CanUseSpell("Q")
		local W	= (50+(150*GetSpellLevel('W'))+myHero.ap*2)*CanUseSpell('W')

			if target.health<Q+AA+E+ignitedamage and not isMed() then	
				if ulting==false then CastSpellTarget('R', target) end
				if CanCastSpell('Q') then CastSpellTarget('Q', target) 
				elseif CanCastSpell('E') then CastSpellTarget('E', target)
				elseif myHero.SummonerD == 'SummonerDot' then
					if IsSpellReady('D') and GetD(target)<600 then CastSpellTarget('D',target) end
				
				elseif myHero.SummonerF == 'SummonerDot' then
					if IsSpellReady('F') and GetD(target)<600 then CastSpellTarget('F',target) end
				else
					AttackTarget(target)
				end
			end
		
	end
end

function ignite()
		if myHero.SummonerD == 'SummonerDot' then
			ignitedamage = ((myHero.selflevel*20)+50)*IsSpellReady('D')
		elseif myHero.SummonerF == 'SummonerDot' then
				ignitedamage = ((myHero.selflevel*20)+50)*IsSpellReady('F')
		else
				ignitedamage=0
		end
end


function OnDraw()

	
    if myHero.dead == 0 then
		if CanUseSpell('Q') == 1 then
			CustomCircle(600,3,2,myHero)
			CustomCircle(1250,3,1,myHero)
		end	
		if hpmarker~=nil then
			if CanUseSpell('W') == 1 and hpmarker<39/160*GetScreenX() then
				DrawBox(GetScreenX()-98/160*GetScreenX()+hpmarker,GetScreenY()-43/900*GetScreenY(),8,17,Color.Red)
			end	
		
			if CanUseSpell('W') == 1 and hpmarker>=39/160*GetScreenX() then
				DrawBox(GetScreenX()-59/160*GetScreenX(),GetScreenY()-43/900*GetScreenY(),8,17,Color.DeepPink)
			end	
		end

 
		for i=1, objManager:GetMaxHeroes(), 1 do
			object = objManager:GetHero(i)
			if object ~= nil and object.team ~= myHero.team and GetD(object,myHero)<1600 and YiConfig.drawQ then	
				DrawTextObject("\n\n"..(math.floor(object.health/getDmg("Q",object,myHero)))+1 .." Q's",object,Color.White)
			end
		end
		
	end	
	
end


            --------------------------------------------W usage for PinkWards

SetTimerCallback("Run")