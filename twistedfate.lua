require "Utils"
require "timCommon"
require "modules"

print("\nTim's Twisted Fate")

local card = "Blue"
local cardSelected = nil
local selecting = false
local gating = false

function getCard()
   return card
end

AddToggle("farm", {on=true, key=112, label="Auto Farm", auxLabel="{0}", args={GetAADamage}})
AddToggle("pick", {on=true, key=113, label="Auto Pick", auxLabel="{0}", args={getCard}})

spells["wild"] = {key="Q", range=1450, color=violet, base={60,110,160,210,260}, ap=.65}
spells["pick"] = {key="W"}

spells["blue"] = {key="W", range=spells["AA"].range, base={40,60,80,100,120}, ap=.4, ad=1}
spells["red"]  = {key="W", range=spells["AA"].range, base={30,45,60,75,90}, ap=.4, ad=1}
spells["yellow"]  = {key="W", range=spells["AA"].range, base={30,45,60,75,90}, ap=.4, ad=1}

spells["stacked"] = {key="E", range=spells["AA"].range, base={15,22.5,30,37.5,45}, ap=.4, ad=1}

spells["card"] = nil
spells["stack"] = nil

function Run()
	TimTick()
	
	if selecting then
	  PrintState(1, "SELECTING")
	else
	  PrintState(1, "not")
	end
	
	if IsRecalling(me) then
	  return
	end
	
	if not Check(cardSelected) then
      spells["card"] = nil
   end
	
	if GetWeakEnemy("MAGIC", 1000) then
		card = "Yellow"
		
		local target = GetWeakEnemy("MAGIC", spells["AA"].range+100) 
		if HotKey() and target then
         UseItems()
         if CanUse("pick") and not selecting then
            CastSpellTarget("W", me)
            selecting = true
         end
         
         if CanUse("wild") then
            CastSpellXYZ("Q", target.x, target.y, target.z)
         end
         
         AttackTarget(target)
      end
	else
		if IsOn("farm") and not gating then
         card = "Blue"
         
			local nearMinions = GetInRange(me, me.range+200, MINIONS)
			for _, minion in ipairs(nearMinions) do
				if minion.health < GetAADamage(minion) then
					AttackTarget(minion)
					break
				end
				
				if not selecting and CanUse("pick") then
               if minion.health < GetAADamage(minion)+GetSpellDamage("blue", minion) then
						CastSpellTarget("W", me)
						selecting = true
						break
               end
				end
			end
		end
	end
end

function onCreateObj(object)
	if IsOn("pick") then
		if find(object.charName, "Card_"..card) then
			CastSpellTarget("W", me)
         spells["card"] = spells[string.lower(card)]
         cardSelected = {object.charName, object}
			selecting = false
		end	
	end
	if find(object.charName, "stackready") then
		spells["stack"] = spells["stacked"]
	end

	if find(object.charName, "TF_Attack") then
      spells["stack"] = nil
	end
end

function onSpell(object, spell)
--Destiny, gate
	if object.name == me.name then
		if spell.name == "PickACard" then
			selecting = true
		end
		if find(spell.name, "cardlock") then
			selecting = false
		end
		
		if spell.name == "Destiny" then
         card = "Yellow"         
         gating = true
         if CanUse("pick") then
            CastSpellTarget("W", me)
         end
      end
		if spell.name == "gate"then
         gating = false
      end
	end
end

AddOnSpell(onSpell)
AddOnCreate(onCreateObj)
SetTimerCallback("Run")