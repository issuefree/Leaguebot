require "timCommon"

function rangeTick()
   if not ModuleConfig.ranges then
      return
   end

   if me.dead == 1 then
      return
   end

   for name,info in pairs(spells) do
      if info.range and info.color and 
         ( not info.key or ( #info.key == 1 and GetSpellLevel(info.key) > 0 ) ) 
      then
         local range = GetSpellRange(info)
         local time 
         if info.key == "Q" then
            time = me.SpellTimeQ - 2
         elseif info.key == "W" then
            time = me.SpellTimeW - 2
         elseif info.key == "E" then
            time = me.SpellTimeE - 2
         elseif info.key == "R" then
            time = me.SpellTimeR - 2
         end

         if name == "AA" then
            if CanAttack() then
               Circle(me, range, info.color, 4)
            elseif IsAttacking() then

            elseif os.clock() - getNextAttackTime() < 0 then
               time = os.clock() - getNextAttackTime() - 1
               Circle(me, range/(-time*-time), info.color)
               Circle(me, range, red)
            end
         else
            if time and time < -1 then
               Circle(me, range/(-time*-time), info.color)
            else
               Circle(me, range, info.color, 2)
            end
         end
      end   
   end
   
   local ranges = {}
   for name, item in pairs(ITEMS) do
      if GetInventorySlot(item.id) and item.range and item.color then
         local range = item.range
         while ranges[range] do
            range = range+1
         end
         Circle(me, range, item.color)
         ranges[range] = true
      end
   end 
   
end

SetTimerCallback("rangeTick")
