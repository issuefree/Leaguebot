require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Lulu")

-- SetChampStyle("caster")
SetChampStyle("support")

spells["pix"] = {
	base=function() return 9 + math.floor((me.selflevel-1)/2)*12 end,
	ap=.15,
	leash=2000,
	allyTimeout=6,
	otherTimeout=4
}

spells["lance"] = {
	key="Q", 
	range=925, 
	color=violet, 
	base={80,125,170,215,260}, 
	ap=.5,
	delay=2.6, -- testskillshot
	speed=15, -- testskillshot
	width=50,
	noblock=true,
	cost={60,65,70,75,80}
}
spells["doubleLance"] = copy(spells["lance"])
spells["doubleLance"].base = mult(spells["lance"].base, 2)
spells["doubleLance"].ap = spells["lance"].ap * 2

spells["whimsy"] = {
	key="W", 
	range=650,  
	color=yellow,
	cost={65,70,75,80,85}	
}
spells["help"] = {
	key="E", 
	range=650,  
	color=blue,  
	base={80,110,140,170,200}, 
	ap=.4,
	cost={60,70,80,90,100}
}
spells["growth"] = {
	key="R", 
	range=900,
	radius=150,
	color=green,  
	base={300,450,600}, 
	ap=.5,
	cost=100
}

AddToggle("shield", {on=true, key=112, label="Auto Shield", auxLabel="{0}", args={"help"}})
AddToggle("ult", {on=true, key=113, label="Auto Ult"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "lance"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

Persist("pix", me)
pixTimeout = 0

function Run()
	if not ValidTarget(P.pix) or GetDistance(P.pix) > spells["pix"].leash or time() > pixTimeout then
		Persist("pix", me)
	end

	-- since I can't predict what pix AA will hit I'm not counting the damage

	-- if P.pix and GetDistance(P.pix) < 150 then
	-- 	spells["AA"].bonus = GetSpellDamage("pix")
	-- else
	-- 	spells["AA"].bonus = 0
	-- end

   if StartTickActions() then
      return true
   end

   if IsOn("ult") and CanUse("growth") then
      local targets = GetInRange(me, "growth", ALLIES)
      local bestT
      local bestP
      for _,target in ipairs(targets) do
         local tp = GetHPerc(target)
         if tp < .2 and #GetInRange(target, 500, ENEMIES) > 0 then
            if not bestT or tp < bestP then
               bestT = target
               bestP = tp
            end
         end
      end
      if bestT then
         Cast("growth", bestT)
         PrintAction("Save", bestT)
         return true
      end
   end


   if CheckDisrupt("whimsy") then
      return true
   end

   if CastAtCC("lance") then
   	return true
   end


	if HotKey() then
		if Action() then
			return true
		end
	end

	if IsOn("lasthit") then
		if Alone() then
			local killsNeeded = 2
			if KillMinionsInLine("lance", killsNeeded) then
				return true
			end

			-- weird angles on pix and since I can't detect pix makes creative stuff hard.

			-- if IsMe(P.pix) or not P.pix then
			-- 	if KillMinionsInLine("doubleLance", 2) then
			-- 		return true
			-- 	end
			-- else
			-- 	local myHits,myKills = GetBestLine(me, "lance", .5, .5, MINIONS)
			-- 	local pixHits = GetInLine(P.pix, "lance", GetAngularCenter(myHits), MINIONS)
			-- 	local pixKills = GetKills("lance", pixHits)

			-- 	-- things both lances hit but neither killed
			-- 	local bothHits = GetIntersection(myHits, pixHits)
			-- 	bothHits = RemoveFromList(bothHits, myKills)
			-- 	bothHits = RemoveFromList(bothHits, pixKills)

			-- 	pixKills = RemoveFromList(pixKills, myKills)
			-- 	local allKills = concat(myKills, pixKills)				

			-- 	for _,hit in ipairs(bothHits) do
			-- 		if WillKill("doubleLance", hit) then
			-- 			table.insert(allKills, hit)
			-- 		end
			-- 	end

			-- 	if #allKills >= killsNeeded then
			-- 		CastXYZ("lance", GetAngularCenter(myHits))
			-- 		AddWillKill(allKills)
			-- 		PrintAction("Lance for LH", #allKills)
			-- 		return true
			-- 	end
			-- end
		end
	end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()	
end 

function Action()
	-- TestSkillShot("lance")

	if CanUse("growth") and IsOn("ult") then
		for _,ally in ipairs(ALLIES) do
			if #GetInRange(ally, spells["growth"].radius + GetWidth(ally), ENEMIES) >= 2 then
				Cast("growth", ally)
				PrintAction("POPUP!")
				return true
			end
		end
	end

	if SkillShot("lance") then
		return true
	end

	if IsMe(P.pix) or not P.pix then
	   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
	   if AutoAA(target) then
	      return true
	   end
	end

	return false
end

function FollowUp()
   return false
end

local function onCreate(object)
	-- PersistBuff("pix", object, "pix object name") -- no object for pix!?!
end

local function onSpell(unit, spell)
	if IsOn("shield") then
		CheckShield("help", unit, spell)
	end

	if ICast("help", unit, spell) then
		if spell.target.team == me.team then
			pixTimeout = time() + spells["pix"].allyTimeout
		else
			pixTimeout = time() + spells["pix"].otherTimeout
		end
		Persist("pix", spell.target)
	end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")