require "timCommon"

ModuleConfig:addParam("ranges", "Draw Spell Ranges", SCRIPT_PARAM_ONOFF, true)
ModuleConfig:permaShow("ranges")

function rangeTick()
   if not ModuleConfig.ranges then
      return
   end
   for name,info in pairs(spells) do
      if info.range and info.color and 
         ( not info.key or GetSpellLevel(info.key) > 0 ) 
      then
         local range
         if type(info.range) == "number" then
            range = info.range 
         else
            range = info.range()           
         end
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
         if time and time < -1 then
            DrawCircleObject(me, range/(-time*-time), info.color)
         else
            DrawCircleObject(me, range, info.color)
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
         DrawCircleObject(me, range, item.color)
         ranges[range] = true
      end
   end 
   
end

SetTimerCallback("rangeTick")
