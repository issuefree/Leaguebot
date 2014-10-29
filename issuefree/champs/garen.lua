require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Garen")
pp(" - if justice will kill, use justice (probably worth chasing)")
pp(" - If my target is in 2x aa range then activate strike to catch and smack em")
pp(" -   don't activate if I'm spinning")
pp(" - If someone targets me and I'm < 75% activate courage")
pp(" - If strike is on cooldown and I have >= 2 enemies in range, activate spin")

InitAAData({ 
   windup = .35,
   particles = {"Garen_Base_AA_Tar", "Garen_Base_Q_Land"},
   resets = {"GarenQ"}
})

AddToggle("", {on=true, key=112, label="- - -"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "strike"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["strike"] = {
   key="Q", 
   base={30,55,80,105,130}, 
   ad=.4,
   modAA="strike",
   object="Garen_Base_Q_Cas_Sword",
   range=GetAARange,
   rangeType="e2e",
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

   if StartTickActions() then
      return true
   end

   spinT = nil
   if CanUse("judgement") then
      local bestMinions = GetBestArea(me, {range=1000, radius=330}, 1, 0, MINIONS)

      if isSpinning() and #bestMinions >= 1 then
         spinT = GetAngularCenter(bestMinions)
         Circle(spinT, 50, yellow, 6)
      elseif #bestMinions >= 3 then 
         spinT = GetAngularCenter(bestMinions)
         Circle(spinT, 50, yellow, 6)
      end
   end

   if CanUse("justice") then
      local targets = SortByDistance(GetInRange(me, spells["justice"].range*2, ENEMIES))
      for i,target in ipairs(targets) do
         if target.health < getJusticeDam(target) then
            Circle(target, nil, violet, 5)
            if GetDistance(target) < GetSpellRange("justice") then
               Cast("justice", target)
               PrintAction("Justice", target)
               return true            
            end
         end
      end
   end

	if HotKey() then
		if Action() then
         return true
      end
	end

   if IsOn("lasthit") then
      if Alone() then
         if ModAAFarm("strike") then
            return true
         end
      end
   end

   if IsOn("jungle") then
      if ModAAJungle("strike") then
         return true
      end
   end

	-- always stuff here
   if HotKey() and CanAct() then  
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if not CanUse("strike") and 
      CanUse("judgement") and 
      not isSpinning() and
      not P.strike
   then      
      local target = GetWeakestEnemy("judgement", 100)
      if target then
         Cast("judgement", me)
         PrintAction("Spin to win")
         return true
      end
   end

   local target = GetWeakestEnemy("judgement", 100, 250)
   if target and isSpinning() then
      MoveToTarget(target)
      PrintAction("Spin to target", target)
      return true
   end

   if not isSpinning() then
      local target = GetMarkedTarget() or GetMeleeTarget()
      if AutoAA(target, "strike") then
         return true
      end
   end

   return false
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
