require "Utils"
require "timCommon"
require "modules"

print("\nTim's Twisted Fate")

local card = "Blue"
local cardSelected = nil
local stackedDeck = false
local selecting = false


function getAADamage()
	local aad = 0
	if cardSelected then
		if find(cardSelected.charName, "Blue") then
			aad = aad + GetSpellDamage("blue") 
		elseif find(cardSelected.charName, "Yellow") then
			aad = aad + GetSpellDamage("yellow")
		elseif find(cardSelected.charname, "Red") then
			aad = aad + GetSpellDamage("red")
		end
	end
	if aad == 0 then
		aad = me.baseDamage+me.addDamage
	end
	if stackedDeck then
		aad = aad + GetSpellDamage("stacked")
	end
	return math.floor(aad+.5)
end

AddToggle("farm", {on=true, key=112, label="Auto Farm", auxLabel="{0}", args={getAADamage}})
AddToggle("pick", {on=true, key=113, label="Auto Pick"})

spells["wild"] = {key="Q", range=1450, color=violet, base={60,110,160,210,260}, ap=.65}
spells["pick"] = {key="W"}
spells["blue"] = {key="W", base={40,60,80,100,120}, ap=.4, ad=1}
spells["red"]  = {key="W", base={30,45,60,75,90}, ap=.4, ad=1}
spells["stacked"] = {key="E", base={55,80,105,130,155}, ap=.4}


function Run()
	TimTick()
	
	if cardSelected and not find(cardSelected.charName, "Card") then
		cardSelected = nil		
	end 
	
	if selecting then	
		DrawText("selecting", 10, 10, 0xffffff00)
	end

	local target = GetWeakEnemy("MAGIC", 1000)	
	if target then
		card = "Yellow"
	else
		if IsOn("farm") then
			card = "Blue"
			local nearMinions = GetInRange(me, me.range+200, MINIONS)
			if #nearMinions > 0 then

				local aad = getAADamage()				
				for _, minion in ipairs(nearMinions) do
					if minion.health < CalcMagicDamage(minion, aad) then
						AttackTarget(minion)
						break
					end
					if minion.health < aad+GetSpellDamage("blue") then
						if not selecting and CanUse("pick") then
							CastSpellTarget("W", me)
							selecting = true
						end
					end
				end
			end
		end
	end
	
	if IsKeyDown(hotKey) ~= 0 then
		UseAllItems()
	end
end

function onCreateObj(object)
	if IsOn("pick") then
		if find(object.charName, "Card_"..card) then
			CastSpellTarget("W", me)
			cardSelected = object
			selecting = false
		end	
	end
	if find(object.charName, "stackready") then
		stackedDeck = true
	end
	if find(object.charName, "TF_Attack") then
		stackedDeck = false
	end
end

function onSpell(object, spell)
	if object.name == me.name then
		if spell.name == "PickACard" then
			selecting = true
		end
		if find(spell.name, "cardlock") then
			selecting = false
		end
	end
end

AddOnSpell(onSpell)
AddOnCreate(onCreateObj)
SetTimerCallback("Run")