require "Utils"
require "timCommon"
require "modules"
require "support"

print("\nTim's Sivir")

AddToggle("lasthit", {on=true, key=112, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("block", {on=true, key=113, label="SpellShield"})

spells["boomerang"] = {
   key="Q", 
   range=1000, 
   color=violet, 
   base={60,105,150,195,240}, 
   ap=.5, 
   adBonus=1.1,   
   type="P",
   delay=2.5,
   speed=13,
   width=80,
   cost={70,80,90,100,110}
}
spells["ricochet"] = {
   key="W",
   cost=40
}
spells["shield"] = {
   key="E",
   range=10,
   cost=75   
}
spells["hunt"] = {
   key="R",
   cost=100
}

function Run()
	TimTick()	

   if IsRecalling(me) or me.dead == 1 then
      PrintAction("Recalling or dead")
      return
   end

   local spell = GetSpell("boomerang")

   -- local hits = GetInLine(me, "boomerang", targets[1], targets)
   -- for _,t in ipairs(hits) do
   --    DrawBB(t, red)      
   -- end
   -- local c = ToPoint(GetCenter(hits))
   -- DrawLineObject(me, spell.range, blue, AngleBetween(me, c), spell.width)


   if HotKey() and CanAct() then

      if SkillShot("boomerang") then
         return true
      end
   end

   if IsOn("lasthit") and Alone() then
      KillWeakMinion("AA", 100)
   end
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