require "timCommon"
require "modules"

pp("\nTim's Garen")
pp(" - if justice will kill, use justice (probably worth chasing)")
pp(" - If my target is in 2x aa range then activate strike to catch and smack em")
pp(" -   don't activate if I'm spinning")
pp(" - If someone targets me and I'm < 75% activate courage")
pp(" - If strike is on cooldown and I have >= 2 enemies in range, activate spin")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["strike"] = {
   key="Q", 
   base={30,55,80,105,130}, 
   ad=1.4,
   type="P"
}
spells["courage"] = {
  key="W"
}
spells["judgement"] = {
  key="E", 
  type="P",
  range=330,
  radius=330,
  color=violet
}
spells["justice"] = {
  key="R", 
  range=400,
  color=red,
  base={175,350,525},
  missing={3.5,3,2.5},
  type="M"
}

local spinT

function Run()
   -- local collision = WillCollide(me, mousePos)
   -- if collision then
   --    Circle(collision, 15, red, 5)
   -- end

   -- if KeyDown(string.byte("X")) then
   --    if not lastPoint or GetDistance(mousePos, lastPoint) > 75 then
   --       printtext("("..mousePos.x..", "..mousePos.z.."),")
   --       lastPoint = Point(mousePos)
   --       table.insert(points, Point(mousePos))
   --    end
   -- end

   -- for _,point in ipairs(points) do
   --    Circle(point, 5)
   -- end

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return true
   end

   

   spinT = nil
   if CanUse("judgement") then
      local bestMinions = GetBestArea(me, {range=1000, radius=330}, 1, 0, MINIONS)

      if isSpinning() and #bestMinions >= 1 then
         spinT = GetCenter(bestMinions)
         Circle(spinT, 50, yellow, 6)
      elseif #bestMinions >= 3 then 
         spinT = GetCenter(bestMinions)
         Circle(spinT, 50, yellow, 6)
      end
   end

   if CanUse("justice") then
      local targets = SortByDistance(GetInRange(me, spells["justice"].range*2, ENEMIES))
      for i,target in ipairs(targets) do
         if target.health < getJusticeDam(target) then
            Cast("justice", target)
            PrintAction("Justice", target)
            return true            
         end
      end
   end

	if HotKey() then
      UseItems()
		if Action() then
         return true
      end
	end

   if IsOn("lasthit") then
      if Alone() then
         if ModAAFarm("strike", P.strike) then
            return true
         end
      end
   end

   if IsOn("jungle") then
      if ModAAJungle("strike", P.strike) then
         return true
      end
   end

	-- always stuff here
   if HotKey() and CanAct() then  
      if FollowUp() then
         return true
      end
   end

   PrintAction()
end

function Action()
   local strikeUp = false
   local target = GetMarkedTarget() or GetMeleeTarget()
   if target and not isSpinning() and CanUse("strike") and not P.strike then
      Cast("strike", me)
      strikeUp = true
      -- no return
   end

   local target = GetWeakest("judgement", GetInRange(me, spells["judgement"].range, ENEMIES))
   if target and not isSpinning() and CanUse("judgement") and not CanUse("strike") and not P.strike then
      Cast("judgement", me)
      PrintAction("Spin to win")
      return true
   end
   if target and isSpinning() then
      MoveToXYZ(target.x, target.y, target.z)
      PrintAction("Spin to target", target)
      return true
   end

   if AA(target) then
      if strikeUp then
         PrintAction("AA (strike)", target)
      else
         PrintAction("AA", target)
      end
   	return true
   end

end

function FollowUp()
   if IsOn("lasthit") then

      if VeryAlone() then
         -- if I'm close to the best spin spot then spin

         if not isSpinning() and CanUse("judgement") and spinT then
            if GetDistance(me, spinT) < 225 then
               Cast("judgement", me)
               PrintAction("Spin to clear")
            end
         end

         -- if I'm spinning then move close to the spin spot.
         if isSpinning() and spinT then
            MoveToXYZ(spinT:unpack())
            return true
         end
      end

      if Alone() then
         if KillMinion("AA") then
            return true
         end
      end

   end

   if IsOn("clearminions") and Alone() then
      if not spinT or (not isSpinning() and not CanUse("judgement")) then
         if HitMinion("AA", "strong") then
            return true
         end
      end
   end

   if IsOn("move") then
      if MeleeMove() then
         return true
      end
   end
   return false
end

function getJusticeDam(target)
   if not target then return 0 end
   local sLvl = me.SpellLevelR
   if sLvl < 1 then return 0 end

   local dam = GetSpellDamage("justice")
   local missingHealth = target.maxHealth - target.health
   dam = dam + missingHealth / spells["justice"].missing[sLvl]
   return CalculateDamage(target, dam)
end

function isSpinning()
   return me.SpellNameE == "garenecancel"
end

local function onObject(object)
   PersistBuff("strike", object, "Garen_Base_Q_Cas_Sword", 150)
end

local function onSpell(unit, spell)
   if spell.target and IsMe(spell.target) and
      GetHPerc(me) < .75 and
      IsEnemy(unit) and 
      CanUse("courage")
   then
      Cast("courage", me)
      PrintAction("Courage", spell.name)
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
