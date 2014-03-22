require "issuefree/timCommon"
require "issuefree/modules"

pp("Tim's Taric")
pp(" - Heal")

spells["heal"] = {
	key="Q",
	range=750,
	color=green,
	base={60,100,140,180,220}, 
	ap=.3,
	type="H",
	cost={60,80,100,120,140}
}
spells["shatter"] = {
	key="W", 
	range=400,  
	color=red,    
	base={40,80,120,160,200}, 
	armor=.5,
	cost={50,60,70,80,90}
}
spells["aura"] = {
	key="W", 
	range=1000, 
	color=yellow
}
spells["stun"] = {
	key="E", 
	range=625,  
	color=violet,    
	base={150,195,240},        
	ap=.5,
	cost=75
}
spells["radiance"] = {
	key="R", 
	range=400,  
	color=red,    
	base={150,250,350},
	ap=.5,
	cost=100
}

AddToggle("healing", {on=true, key=112, label="Heal Team", auxLabel="{0}", args={"heal"}})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=false, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

function CheckDisrupt()
   if Disrupt("DeathLotus", "stun") then return true end

   if Disrupt("Grasp", "stun") then return true end

   if Disrupt("AbsoluteZero", "stun") then return true end

   if Disrupt("BulletTime", "stun") then return true end

   if Disrupt("Duress", "stun") then return true end

   if Disrupt("Idol", "stun") then return true end

   if Disrupt("Monsoon", "stun") then return true end

   if Disrupt("Meditate", "stun") then return true end

   if Disrupt("Drain", "stun") then return true end

   if Disrupt("HeartSeeker", "stun") then return true end

   return false
end

function Run()
	spells["heal"].bonus = (me.maxHealth - (468+(90*me.selflevel-1)))*.05
	
	if P.gemcraft then
		spells["AA"].bonus = me.armor * .2
	else
		spells["AA"].bonus = 0
	end

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   if CheckDisrupt() then
      return true
   end

   if IsOn("healing") and CanUse("heal") then
		if doHeal() then
			return true
		end
	end

	if HotKey() and CanAct() then
		if Action() then
			return
		end
	end
end 

function Action()
	UseItems()
	return false
end

function healScore(hero, maxHeal)
	if GetDistance(HOME, hero) < 1000 or
		IsMe(hero) or
		hero.health + maxHeal > hero.maxHealth*.9 or
		hero.dead == 1 or
		hero.visible == 0 or
		HasBuff("wound", hero) or
		IsRecalling(hero)
	then
		return 0
	end

	return 10000 - hero.health
end

function doHeal()
	local maxHeal = GetSpellDamage("heal")

	local bestNear = SelectFromList(GetInRange(me, "heal", ALLIES), healScore, maxHeal)
	local bestFar = SelectFromList(GetInRange(me, GetSpellRange("heal")+250, ALLIES), healScore, maxHeal)

	Circle(bestNear, 100, green)

	if ( not bestNear or GetHPerc(bestNear) > .5 ) and
		bestFar and GetHPerc(bestFar) < .25
	then
		Circle(bestFar, 100, yellow)
		LineBetween(me, bestFar)
		PrintAction("Far heal needed", bestFar)
		return false
	end
		
	if bestNear then
		Cast("heal", bestNear)
		PrintAction("Heal", bestNear)
		return true
	end

	if me.health + maxHeal*1.4 < me.maxHealth*.75 then
		Cast("heal", me)
		PrintAction("Heal self")
		return true
	end
end

local function onCreate(object)
	PersistBuff("gemcraft", object, "bluehands_buf")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)


SetTimerCallback("Run")