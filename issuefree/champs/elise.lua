require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Elise")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("gank", {on=false, key=114, label="Gank"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clearminions", {on=false, key=117, label="Clear Minions"})

spells["toxin"] = {
   key="Q", 
   range=625, 
   color=green,
   base={40,75,110,145,180}, 
   percHealth=.08,
   maxOnMobs={50,75,100,125,150},
   cost={80,85,90,95,100}
} 
spells["bite"] = {
   key="Q",
   range=475, 
   color=violet,
   base={60,100,140,180,220}, 
   percMissingHealth=.08,
   maxOnMobs={50,75,100,125,150}
} 

spells["spiderling"] = {
   key="W", 
   range=950, 
   color=violet, 
   base={75,125,175,225,275}, 
   ap=.8,
   delay=2,
   speed=12,
   width=80,
   cost={60,70,80,90,100}
} 
spells["frenzy"] = {
   key="W"
}

spells["cocoon"] = {
   key="E", 
   range=1075, 
   color=yellow, 
   delay=2,
   speed=14,
   width=80,
   cost=50,
   showFireahead=true
} 
spells["rappel"] = {
   key="E", 
   range=1150, 
   color=yellow
} 
spells["spider"] = {
   key="R", 
   base={10,20,30,40}, 
   ap=.3
} 

spells["AA"].damOnTarget = 
   function(target)
      if isSpider() then
         return GetSpellDamage("spider", target)
      end
      return 0
   end

function isSpider()
   if me.SpellNameQ == "EliseHumanQ" then
      return false
   end
   return true
end

function Run()
   spells["toxin"].percHealth = .08 + me.ap/100*.03
   spells["bite"].percMissingHealth = .08 + me.ap/100*.03

   if isSpider() then
      spells["toxin"].key = "--"
      spells["spiderling"].key = "--"
      spells["cocoon"].key = "--"
      spells["bite"].key = "Q"
      spells["frenzy"].key = "W"
      spells["rappel"].key = "E"
   else
      spells["toxin"].key = "Q"
      spells["spiderling"].key = "W"
      spells["cocoon"].key = "E"
      spells["bite"].key = "--"
      spells["frenzy"].key = "--"
      spells["rappel"].key = "--"
   end

   if StartTickActions() then
      return true
   end


   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
      UseItems()
		if Action() then
			return true
		end
	end

   if IsOn("gank") then
      local webbed = GetWithBuff("web", ENEMIES)[1]
      if webbed then

         DoIn(function() Toggle("gank", false) end, 2)

         if CanUse("spiderling") then
            CastXYZ("spiderling", webbed)
            PrintAction("Spider webbed", webbed)
            return true
         end
         if CanUse("toxin") then
            Cast("toxin", webbed)
            PrintAction("Toxin webbed", webbed)
            return true
         end
         if not isSpider() and CanUse("spider") then
            Cast("spider", me)
            PrintAction("SPIDER")
            return true
         end
         if CanUse("bite") then
            Cast("bite", webbed)
            PrintAction("Bite webbed", webbed)
            return true
         end
      end
   end


	-- auto stuff that should happen if you didn't do something more important

   if CanUse("frenzy") and JustAttacked() and VeryAlone() then
      Cast("frenzy", me)
      PrintAction("Frenzy alone")
   end


   if IsOn("lasthit") and Alone() then
      if CanUse("spiderling") then
         local unblocked = GetUnblocked(me, "spiderling", MINIONS)
         local bestK = 1
         local bestT
         for _,target in ipairs(unblocked) do
            local kills = #GetKills("spiderling", GetInRange(target, 150, MINIONS))
            if kills > bestK then
               bestT = target
               bestK = kills
            end
         end
         if bestT then
            if bestK >= 3 or (bestK >= 2 and GetMPerc(me) > .5) then
               CastXYZ("spiderling", bestT)
               PrintAction("spiderling for lasthit")
               return true
            end
         end
      end

      if KillMinion("bite") then
         return true
      end
   end


   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   if IsOn("jungle") and VeryAlone() then
      local creep
      local creeps = GetAllInRange(me, "toxin", CREEPS)
      if #creeps > 0 then
         table.sort(creeps, function(a,b) return a.maxHealth - a.health > b.maxHealth - b.health end)
         if creeps[1].maxHealth > creeps[1].health then
            creep = creeps[1]
         end
      end

      if creep then
         if isSpider() then
            -- bite the creep that is missing the most health if any
            if CanUse("bite") then
               Cast("bite", creep)
               PrintAction("Bite in jungle", creep)
               return true
            end

         else
            if GetMPerc(me) >= .85 or ( #creeps >= 2 and CanUse("spiderling") and GetMPerc(me) > .33 ) then
               CastXYZ("spiderling", me)            
               PrintAction("Spiderling in jungle")
               return true
            end
            if CanUse("spider") then
               Cast("spider", me)
               PrintAction("Spider")
               return true
            end
         end
      end
   end   

   EndTickActions()
end

function Action()   
   if isSpider() then
      if CastBest("bite") then
         return true
      end

      local target = GetMarkedTarget() or GetMeleeTarget()
      if AA(target) then
         PrintAction("AA", target)
         return true
      end
   else      
      if CastBest("toxin") then
         return true
      end

      if SkillShot("spiderling") then
         return true
      end

      local target = GetMarkedTarget() or GetWeakestEnemy("bite", 50)
      if target and 
         not CanUse("toxin") and 
         not CanUse("spiderling") and 
         CanUse("spider") 
      then
         Cast("spider", me)
         PrintAction("Spider")
         return true
      end

   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clearminions") and Alone() then
      if HitMinion("AA", "strong") then
         return true
      end
   end

   if isSpider() then
      if IsOn("move") then
         if MeleeMove() then
            return true
         end
      end
   end

   return false
end

local function onCreate(object)
   Persist("swarm", object, "Spiderling")
   PersistOnTargets("web", object, "Elise_human_E_tar", ENEMIES)
end

local function onSpell(unit, spell)
   if CanUse("frenzy") and IAttack(unit, spell) and IsEnemy(spell.target) then
      Cast("frenzy", me)
      PrintAction("Frenzy enemy")
   end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
SetTimerCallback("Run")

