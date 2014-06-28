require "issuefree/timCommon"
require "issuefree/modules"

print("\nTim's Sivir")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("block", {on=true, key=113, label="SpellShield"})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["boomerang"] = {
   key="Q", 
   range=1000, 
   color=violet, 
   base={25,45,65,85,105}, 
   ap=.5, 
   ad={.7,.8,.9,1,1.1},
   type="P",
   delay=2,
   speed=13,
   width=80,
   noblock=true,
   overshoot=-200,
   cost={70,80,90,100,110}
}
spells["ricochet"] = {
   key="W",
   cost=40,
   ad={.5,.55,.6,.65,.7},
   bounceRange=400 --?
}
spells["shield"] = {
   key="E",
   range=10  
}
spells["hunt"] = {
   key="R",
   cost=100
}

function Run()
   if StartTickActions() then
      return true
   end

   local spell = GetSpell("boomerang")

   -- local hits = GetInLine(me, "boomerang", targets[1], targets)
   -- for _,t in ipairs(hits) do
   --    DrawBB(t, red)      
   -- end
   -- local c = GetCenter(hits)
   -- DrawLineObject(me, spell.range, blue, AngleBetween(me, c), spell.width)

   if CastAtCC("boomerang") then
      return true
   end

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end   

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if SkillShot("boomerang") then
      return true
   end
   return false
end

function FollowUp()
   return false
end

-- function getRangTargs()
--    local spell = GetSpell("boomerang")
--    local enemies = SortByDistance(GetInRange(me, "boomerang", ENEMIES))
--    local enemiesFireahead = {}
--    for _,enemy in ipairs(enemies) do
--       local x,y,z = GetFireahead(enemy, spell.delay, spell.speed)
--       table.insert(enemiesFireahead, {x=x, y=y, z=z}         
--    end

--    GetInLine(spell.width, enemiesFireahead, )
-- end

local function onSpell(unit, spell)
   if IsOn("block") then
      CheckShield("shield", unit, spell, "SPELL")
   end
end

AddOnSpell(onSpell)
SetTimerCallback("Run")