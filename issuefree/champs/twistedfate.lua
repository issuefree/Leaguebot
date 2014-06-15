require "issuefree/timCommon"
require "issuefree/modules"

print("\nTim's Twisted Fate")

local card = "Blue"
local selecting = false
local gating = false

function getCard()
   return card
end

AddToggle("farm", {on=true, key=112, label="Auto Farm", auxLabel="{0}", args={GetAADamage}})
AddToggle("pick", {on=true, key=113, label="Auto Pick", auxLabel="{0}", args={getCard}})

spells["wild"] = {
	key="Q", 
	range=1450, 
	color=violet, 
	base={60,110,160,210,260}, 
	ap=.65,
	delay=2,
	speed=10,
	noblock=true
}
spells["pick"] = {
	key="W"
}
spells["blue"] = {
	key="W", 
	range=spells["AA"].range, 
	base={40,60,80,100,120}, 
	ap=.4,
	ad=1,
	type="M"
}
spells["red"] = {
	key="W", 
	range=spells["AA"].range, 
	base={30,45,60,75,90}, 
	ap=.4, 
	ad=1,
	type="M"
}
spells["yellow"]  = {
	key="W", 
	range=spells["AA"].range, 
	base={15,22.5,30,37.5,45}, 
	ap=.4, 
	ad=1,
	type="M"
}

spells["stacked"] = {
	key="E", 
	range=spells["AA"].range, 
	base={55,80,105,130,155}, 
	ap=.4, 
	type="M"
}

spells["card"] = nil
spells["stack"] = nil

function Run()
	if selecting then
		PrintState(1, "SELECTING")
	end
	
	if not P.card then
      spells["card"] = nil
   end

   spells["AA"].bonus = GetSpellDamage("card") + GetSpellDamage("stack")
   if spells["card"] then
      spells["AA"].ad = 0
   else
      spells["AA"].ad = 1
	end


   if StartTickActions() then
      return true
   end

   if CastAtCC("wild") then
      return true
   end

	if GetWeakEnemy("MAGIC", 1000) then
		card = "Yellow"
		
		local target = GetWeakEnemy("MAGIC", spells["AA"].range+100) 
		if HotKey() and target then
         UseItems()
         if CanUse("pick") and not selecting then
            Cast("pick", me)
            selecting = true
         end

         if SkillShot("wild") then
         	return true
         end
         
         -- AttackTarget(target)
      end
	else
		if IsOn("farm") and not gating then
         card = "Blue"
         
			if not selecting and CanUse("pick") and not P.card then
				local minions = GetInRange(me, "AA", MINIONS)
				for _,minion in ipairs(minions) do
	            if minion.health < GetAADamage(minion)+GetSpellDamage("blue", minion) then
						CastSpellTarget("W", me)
						PrintAction("Pick for farm")
						StartChannel()
						return true
	            end
	         end
			end

         if P.card and not selecting then
         	if KillMinion("AA") then
         		return true
         	end
         end


			-- local nearMinions = GetInRange(me, me.range+200, MINIONS)
			-- for _, minion in ipairs(nearMinions) do
			-- 	if minion.health < GetAADamage(minion) then
			-- 		AA(minion)
			-- 		break
			-- 	end
				
			-- end
		end
	end
end

function onCreateObj(object)
	-- if find(object.charName, "Card") then
	-- 	pp(object.charName)
	-- end
	if PersistBuff("card", object, "Card_", 200) then		
		if IsOn("pick") then
			if find(object.charName, card) then
				CastSpellTarget("W", me, 0)
				PrintAction("Pick "..card)
			end
		end
	end

	if find(object.charName, "stackready") then
		spells["stack"] = spells["stacked"]
	end

	if find(object.charName, "TF_Attack") then
      spells["stack"] = nil
	end
end

function onSpell(unit, spell)
--Destiny, gate
	if IsMe(unit) then
		
		if spell.name == "goldcardlock" then
			spells["card"] = spells["yellow"]
		elseif spell.name == "redcardlock" then
			spells["card"] = spells["red"]
		elseif spell.name == "bluecardlock" then
			spells["card"] = spells["blue"]
		end

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