require "Utils"
require "timCommon"
require "modules"

print("\nTim's Teemo")

function getMaladyDamage()
	local maladyDam = 0
	if GetInventorySlot(ITEMS["Malady"].id) then
		maladyDam = 15+(me.ap*.1)
	end
	return maladyDam
end

AddToggle("lasthit", {on=true, key=112, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=113, label="Clear Waves"})

spells["blind"] = {key="Q", range=680, color=yellow, base={80,125,170,215,260}, ap=.8}
spells["toxic"] = {key="E", base={10,20,30,40,50}, ap=.3}

local poisons = {}

function Run()
	TimTick()
	
	Clean(poisons, "charName", "Global_poison")
	
--	for _,obj in ipairs(poisons) do
--		DrawCircleObject(obj, 75, yellow)
--	end
	
	local tt = GetWeakEnemy("MAGIC", 10000)
	if tt then
	  PrintState(1, tt.name)
	  local facingMe = FacingMe(tt)
	  if facingMe then
	     PrintState(2, "facing me")
	  else
	     PrintState(2, "facing away")
	  end
   end
	
	if HotKey() then
		UseItems()
		if CanUse("blind") then
   		if EADC and GetDistance(EADC) < spells["blind"].range then
            CastSpellTarget("Q", EADC)
   		else
            local target = GetWeakEnemy("MAGIC", spells["blind"].range)
            if target then
               CastSpellTarget("Q", target)
            end
         end
      end   
	end
	
	if IsOn("lasthit") and not GetWeakEnemy("MAGIC", 750) then
      KillWeakMinion("AA", 50)
	end 
	
	if IsOn("clear") and not GetWeakEnemy("MAGIC", 1000) then
		local nearMinions = GetInRange(me, 1000, MINIONS)
		if #nearMinions > 0 then
			SortByDistance(nearMinions)
			for _,minion in ipairs(nearMinions) do
				if not (#GetInRange(minion, 50, poisons) > 0) then
					AttackTarget(minion)
				end
			end
		end
	end
end
    
local function onObject(object)
	if IsOn("clear") and GetDistance(object) < 1000 then
		if find(object.charName, "Global_poison") then
			table.insert(poisons, object)
		end 
	end
end

local function onSpell(object, spell)
--	if object.name == me.name then
--		if spell.target then
--			pp(spell.name.."->"..spell.target.name)
--		else		
--			pp(spell.name)
--		end
--	end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
SetTimerCallback("Run")


-- some code in here for detecting auto attacks and blinds
--	for i = 1, objManager:GetMaxNewObjects(), 1 do
--		local object = objManager:GetNewObject(i)
--		if object and object ~= nil then
--			if string.find(object.charName,"Toxicshot") and GetDistance(me, object) < 500 then
--				attacked = GetClock()
--			end
--		end
--	end
--
--	-- If I attack something in the last half second and I have Q hit them again with blind to set up the attack refresh
--    local target = GetWeakEnemy('MAGIC', 500)    
--    if target ~= nil then
--    	if GetClock() - attacked < 500 and GetDistance(me, target) < 525 and CanCastSpell("Q") then 
--        	CastSpellTarget("Q", target)
--        	attacked = 0
--        end
--    end        
--BlindShot_tar.troy
--BlindShot_mis.troy
--Toxicshot_tar.troy
--Toxicshot_mis.troy