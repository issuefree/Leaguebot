require "Utils"
require "timCommon"
require "modules"

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
   width=80
}
spells["ricochet"] = {
   key="W"
}
spells["shield"] = {
   key="E"   
}
spells["hunt"] = {
   key="R"
}

function Run()
	TimTick()	


   local spell = GetSpell("boomerang")

   local hits = GetInLine(me, "boomerang", targets[1], targets)
   for _,t in ipairs(hits) do
      DrawBB(t, red)      
   end
   local c = ToPoint(GetCenter(hits))
   DrawLineObject(me, spell.range, blue, AngleBetween(me, c), spell.width)


   if HotKey() and CanAct() then

      if SkillShot("boomerang") then
         return true
      end
   end

   if IsOn("lasthit") and not GetWeakEnemy("PHYSICAL", 950) then
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

function checkBlock(unit, spell)
   if CanUse("E") and spell.target and spell.target.name == me.name then
      for _,s in ipairs(ENEMY_SPELLS) do
         if find(spell.name, s.spellName) then
      		Cast("E", me)
      		break
         end
      end
   end
end

AddOnSpell(checkBlock)
SetTimerCallback("Run")