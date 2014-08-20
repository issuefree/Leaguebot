require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Tristana")

InitAAData({
   projSpeed = 2.25, windup=.15,
   minMoveTime=0,
   extraRange=-25,  --TODO check range
   -- particles = {"TristannaBasicAttack_mis"}  -- Trists object is shared with minions. This could result in clipping. Can be turned back on for testing
})

SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("jump", {on=false, key=112, label="Jumps"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

function getShotRange()
   return 675+(9*(me.selflevel-1))
end

function getBusterRange()
   return 650+(9*(me.selflevel-1))
end

spells["rapid"] = {
   key="Q", 
} 
spells["jump"] = {
   key="W", 
   range=900, 
   color=blue, 
   base={70,115,160,205,250}, 
   ap=.8,
   delay=2,
   speed=12, --?
   radius=300, --?
} 
spells["shot"] = {
   key="E", 
   range=getShotRange,
   color=violet, 
   base={80,125,170,215,260}, 
   ap=1,
   radius=150,
} 
spells["buster"] = {
   key="R", 
   range=getBusterRange, 
   color=red, 
   base={300,400,500}, 
   ap=1.5,
   knockback={600,800,1000},
   radius=200,
} 

local jumpPoint = nil
local kbPoint = nil
local kbType = nil

function getKBPoint()

   kbType = nil
   local kbDist = GetLVal(spells["buster"], "knockback")
   local busterRange = GetSpellRange("buster")
   local jumpRange = GetSpellRange("jump")

   -- if GetDistance(HOME) < (850 + kbDist + busterRange + jumpRange) then
   --    PrintState(0, "HOME")      
   --    kbType = "HOME"
   --    return Point(HOME)
   -- end

   local point = SortByDistance(GetInRange(me, 750+kbDist+busterRange+jumpRange, MYTURRETS))[1]
   if point then 
      PrintState(0, "TURRET")
      kbType = "TURRET"
      return point 
   end

   -- local otherAllies = GetOtherAllies()
   -- for _,ally in ipairs(GetInRange(me, kbDist+busterRange, otherAllies)) do
   --    local pick = SelectFromList(
   --       ALLIES, 
   --       function(a) 
   --          return #GetInRange(a, 500, otherAllies)
   --       end,
   --       ally
   --    )
   --    local group = GetInRange(pick, 500, otherAllies)
   --    if #group >= 2 or GetHPerc(pick) > .5 then
   --       PrintState(0, "ALLIES")
   --       kbType = "ALLIES"
   --       return GetCenter(group)
   --    end
   -- end

   -- for _,minion in ipairs(GetInRange(me, 1000, MYMINIONS)) do
   --    local pick = SelectFromList(
   --       MYMINIONS, 
   --       function(a) 
   --          return #GetInRange(minion, 450, MYMINIONS)
   --       end,
   --       minion
   --    )
   --    local group = GetInRange(minion, 450, MYMINIONS)
   --    if #group >= 3 then
   --       point = GetCenter(group)
   --       if GetDistance(point, HOME) < GetDistance(me, HOME)+250 then         
   --          PrintState(0, "MINIONS")
   --          return point
   --       end
   --    end
   -- end

   return nil
end

function getJumpPoint()
   local target = GetWeakestEnemy("jump", 500)

   -- if I don't have a target or a place I want to knock em bail
   if not target or not kbPoint then 
      return nil
   end

   -- I have a target and a point I'd like to knock them to

   local predTarget = GetSpellFireahead("jump", target) -- where they'll be when I land - ish

   -- local predTarget = mousePos
   
   -- local point
   -- if GetDistance(predTarget, kbPoint) > GetDistance(target, kbPoint) then 
   --    -- they're moving away from the kb point, lead em
   --    point = Projection(kbPoint, predTarget, GetDistance(kbPoint, predTarget)+100)
   --    target = predTarget
   -- else       
   --    point = Projection(kbPoint, target, GetDistance(kbPoint, target)+300) 
   -- end

   local point = Projection(kbPoint, predTarget, GetDistance(kbPoint, predTarget)+GetSpellRange("buster"))
   if GetDistance(point) > GetSpellRange("jump") then
      local jd = GetSpellRange("jump")-5
      local od = GetOrthDist(predTarget, me, kbPoint)
      local dx = math.sqrt(jd^2 - od^2) + math.sqrt(GetDistance(kbPoint)^2 - od^2)

      point = Projection(kbPoint, predTarget, dx)
   end

   -- can't get to where I'd need to go
   if GetDistance(point) > GetSpellRange("jump") then
      return nil
   end

   if GetDistance(kbPoint, point) - GetDistance(predTarget, kbPoint) < 300 then -- I won't be able to lead them enough
      return nil
   end

   -- don't jump into walls
   if IsSolid(point) then
      return nil
   end

   -- I have a point I'd like to jump to so I can kb
   Circle(point, 50, red, 4)

   -- If I'm closer to the kb point than I am to them don't jump yet
   if GetDistance(kbPoint)+100 < GetDistance(predTarget) then 
      return nil
   end

   -- make sure if I did KB them that they'd go where I want
   local kbDist = GetLVal(spells["buster"], "knockback")
   if kbType == "HOME" then
      if GetDistance(predTarget, kbPoint) > kbDist + 800 then -- I can't knock them home
         return nil
      end
      if GetDistance(predTarget, kbPoint) < 900 then -- already in poool don't bother
         return nil
      end
   elseif kbType == "TURRET" then
      if GetDistance(predTarget, kbPoint) > kbDist + 750 then -- I can't knock them into a turret
         return nil
      end
      if GetDistance(predTarget, kbPoint) < 850 then -- already under tower don't bother
         return nil
      end
   elseif kbType == "ALLIES" then
      if GetDistance(predTarget, kbPoint) > kbDist + 250 then -- I can't knock them into allies
         return nil
      end
   end

   if UnderTower(point) then -- don't jump under towers
      return nil
   end

   if #GetInRange(point, 1000, ENEMIES) > 2 then -- don't jump into groups
      return nil
   end

   return point, predTarget
end

function checkForHeals()
   if not CanUse("shot") then return false end

   local target = GetWithBuff("sadism", ENEMIES)[1]
   if target and IsInRange("shot", target) then
      Cast("shot", target)
      PrintAction("Shrapnel for sadism", target)
      return true
   end

   local target = GetWithBuff("crow", ENEMIES)[1]
   if target and IsInRange("shot", target) then
      Cast("shot", target)
      PrintAction("Shrapnel for crow", target)
      return true
   end

   local target = GetWithBuff("meditate", ENEMIES)[1]
   if target and IsInRange("shot", target) then
      Cast("shot", target)
      PrintAction("Shrapnel for meditate", target)
      return true
   end

   local target = GetWithBuff("healthPotion", ENEMIES)[1]
   if target and IsInRange("shot", target) then
      Cast("shot", target)
      PrintAction("Shrapnel for healthPotion", target)
      return true
   end

   local target = GetWeakestEnemy("AA")
   if target then

      local healers = GetInRange(target, 500, ENEMIES)
      for _,healer in ipairs(healers) do
         if ListContains(healer.name, {"Sona", "Soraka", "Nami", "Taric", "Alistar", "Nidalee", "Kayle"}) then
            Cast("shot", target)
            PrintAction("Shot to counter healers", healer)
            return true
         end
      end

   end

   local target = GetWeakestEnemy("AA")
   if target then
      if target.name == "Akali" then
         Cast("shot", target)
         PrintAction("Shot to counter vamp", target)
         return true
      elseif target.name == "Gangplank" and IsCooledDown("E", 0, target) then
         Cast("shot", target)
         PrintAction("Shot to counter oranges", healer)
         return true
      elseif target.name == "Volibear" then
         Cast("shot", target)
         PrintAction("Shot to counter", target)
         return true
      elseif target.name == "Warwick" then
         Cast("shot", target)
         PrintAction("Shot to counter", target)
         return true
      elseif target.name == "FiddleSticks" and IsCooledDown("W", 0, target) then
         Cast("shot", target)
         PrintAction("Shot to counter drain", target)
         return true
      elseif target.name == "Fiora" then
         Cast("shot", target)
         PrintAction("Shot to counter", target)
         return true
      elseif target.name == "Garen" then
         Cast("shot", target)
         PrintAction("Shot to counter", target)
         return true
      elseif target.name == "Vladimir" then
         Cast("shot", target)
         PrintAction("Shot to counter", target)
         return true
      end
   end
end

function Run()
   -- for _,target in ipairs(ENEMIES) do
   --    if target.name == "FiddleSticks" then
   --       PrintState(1, "Fiddle")
   --       if IsCooledDown("W", 0, target) then
   --          PrintState(2, "CAN DRAIN")
   --       end
   --    end
   -- end
   if StartTickActions() then
      return true
   end

   if CheckDisrupt("buster") then
      return true
   end

   kbPoint = getKBPoint()
   Circle(kbPoint)
   if kbPoint then
      jumpPoint, jumpTarget= getJumpPoint()
      if jumpPoint and jumpTarget then
         Circle(jumpPoint, 50, red, 4)
         -- LineBetween(jumpTarget, GetKnockback("buster", jumpPoint, jumpTarget))
         -- Circle(jumpTarget, nil, red)
         -- LineBetween(me, jumpPoint)
      end
   end




   -- auto stuff that always happen
   if checkForHeals() then
      return true
   end


   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if IsOn("jump") and 
      CanUse("jump") and CanUse("buster") and
      me.mana > (GetSpellCost("jump") + GetSpellCost("buster"))
   then
      if jumpPoint and GetDistance(jumpPoint) < GetSpellRange("jump") then
         CastXYZ("jump", jumpPoint)
         PrintAction("JUMP for kb to "..kbType)
         return true
      end
   end

   if CanUse("buster") then
      local target = GetKills("buster", GetInRange(me, "buster", ENEMIES))[1]
      if target then
         Cast("buster", target)
         PrintAction("Buster for execute", target)
         return true
      end
   end

   if CanUse("buster") and kbPoint then
      for _,target in ipairs(SortByDistance(GetInRange(me, "buster", ENEMIES))) do
         local targetKb = GetKnockback("buster", me, target)
         -- the kb will move them closer to the kbPoint than they are now (why kb if it won't move them where I want to move them)
         if GetDistance(kbPoint, targetKb) < GetDistance(kbPoint, target) and
            ( GetDistance(targetKb, kbPoint) < 500 or  -- they'll land where I want them
              UnderMyTower(targetKb) or -- they'll land under tower
              GetDistance(targetKb, HOME) < 800 ) -- they'll land in the pool 
         then 
            Cast("buster", target)
            PrintAction("KB to "..kbType, target)
            return true
         end
      end
   end

   if CanUse("shot") then
      if me.SpellLevelE >= me.SpellLevelQ then
         if CastBest("shot") then
            return true
         end
      end
   end

   if CanUse("rapid") then
      local target = GetWeakestEnemy("AA", -50)
      if target then
         Cast("rapid", me)
         PrintAction("Rapid Fire", target)
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   return false
end

local function onObject(object)
   PersistOnTargets("sadism", object, "TODO", ENEMIES)
   PersistOnTargets("crow", object, "swain_demonForm", ENEMIES)
   PersistOnTargets("meditate", object, "MasterYi_Base_W_Buf", ENEMIES)
   PersistOnTargets("healthPotion", object, "GLOBAL_Item_Health", ENEMIES)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

SetTimerCallback("Run")

