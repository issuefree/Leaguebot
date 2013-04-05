require "utils"
require "timCommon"
require "modules"

pp("Tim's Mundo")

local berserkToggleTime = GetClock()
function getBerserkTime()
	return math.floor(10.5 - (GetClock() - berserkToggleTime)/1000)
end

spells["cleaver"] = {
   key="Q", 
   range=1000, 
   color=violet, 
   base={80,130,180,230,280},
   type="M",
   width=80,
   delay=2,
   speed=20
}
spells["agony"] = {
   key="W",
   range=325,  
   color=red, 
   base={35,50,65,80,95},
   type="M", 
   ap=.2
}
spells["masochism"] = {
   key="E",
   base={40,55,70,85,100},
   mhp={0.4,0.55,0.7,0.85,1},
   type="P"
}

function getMasochismDamage()
   local spell = spells["masochism"]
   local level = GetSpellLevel(spell.key) 
   if level == 0 then
      return 0
   end
   
   local damage = spell.base[level]
   damage = damage + spell.mhp[level]*((1-me.health/me.maxHealth)*100)
   return damage
end

AddToggle("berserk", {on=false, key=112, label="BERSERK", auxLabel="{0}", args={getBerserkTime}})
AddToggle("cook",    {on=true,  key=113, label="Cook minions", auxLabel="{0}", args={"agony"}})
AddToggle("butcher", {on=true,  key=114, label="Butcher minions", auxLabel="{0}", args={"cleaver"}})

-- holder for my burning agony object
local burningAgony = nil

function Run()
	TimTick()
	updateObjects()

	if GetWeakEnemy("MAGIC", 1200) or not IsOn("berserk") then
		berserkToggleTime = GetClock()
	elseif GetClock() - berserkToggleTime > 10000 then
		keyToggles["berserk"].on = false
	end   

	if HotKey() then
      UseItems()
      cleaverEnemy()
      
      if IsOn("berserk") then
         local target = GetWeakEnemy("PHYSICAL", 350)
         if target then
            if CanUse("masochism") then
               CastSpellTarget(spells["masochism"].key, me)
            end
            if not burningAgony and CanUse("agony") then
               CastSpellTarget(spells["agony"].key, me)
            end

            AttackTarget(target)
         else
            target = GetWeakEnemy("PHYSICAL", 1000)
            if target then
               AttackTarget(target)
            end
         end
      end
	end

   if IsOn("cook") and not burningAgony and CanUse("agony") then
   	for _,minion in ipairs(MINIONS) do
   		if GetDistance(me, minion) < spells["agony"].range and 
   		   GetSpellDamage("agony", minion) > minion.health
   		then
   			CastSpellTarget(spells["agony"].key, me)
   			break				
   		end
   	end
   end

   local target = GetWeakEnemy("MAGIC", 750)
   if IsOn("butcher") and not HotKey() and not target then
      local cleaver = spells["cleaver"]	
   	for _,minion in ipairs(GetUnblocked(me, cleaver.range, cleaver.width, MINIONS)) do
   		if GetDistance(minion) > spells["agony"].range and 
   		   GetSpellDamage(cleaver, minion) > minion.health 
   		then
      		LineBetween(me, minion, cleaver.width)
      		if CanUse(cleaver) then
   			   CastSpellXYZ(cleaver.key, minion.x, minion.y, minion.z)
   			end
 			   break
   		end	
   	end
	end
end

function cleaverEnemy()
   local cleaver = spells["cleaver"]
   local target = GetWeakEnemy("MAGIC", cleaver.range+50)
   if target and CanUse(cleaver) then
      local unblocked = GetUnblocked(me, cleaver.range+50, cleaver.width, MINIONS, ENEMIES)

      unblocked = FilterList(unblocked, function(item) return not IsMinion(item) end)

      target = GetWeakest(cleaver, unblocked)

      if target then
         local x,y,z = GetFireahead(target, cleaver.delay, cleaver.speed)
         if GetDistance({x=x, y=y, z=z}) < cleaver.range then
            CastSpellXYZ(cleaver.key, x, y, z)
            --            OrbWalk(250)
            return target            
         end
      end
   end
   return false
end

function checkBurning(object)
	if find(object.charName, "burning_agony") and GetDistance(me, object) < 100 then
		burningAgony = object
	end
end

function updateObjects()
	if burningAgony and burningAgony.x and burningAgony.z and GetDistance(me, burningAgony) < 50 then
	else
		burningAgony = nil
	end
end

AddOnCreate(checkBurning)

SetTimerCallback("Run")