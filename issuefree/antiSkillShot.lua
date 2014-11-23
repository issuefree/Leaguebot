require "issuefree/timCommon"


function assTick()
   if not ModuleConfig.ass then
      return
   end

   for _,enemy in ipairs(ENEMIES) do
      if IsValid(enemy) then
         local spells = GetSpellShots(enemy.name)
         if spells then
            for _,spell in pairs(spells) do
               if spell.perm and spell.key and enemy["SpellLevel"..spell.key] > .5 then

                  if spell.ss and spell.isline then
                     if GetDistance(enemy) < spell.range and enemy["SpellTime"..spell.key] >= 1 then
                        if spell.block then
                           local unblocked = GetUnblocked(spell, enemy, MYMINIONS, ALLIES)
                           for _,test in ipairs(unblocked) do
                              if test.charName == me.charName then
                                 LineBetween(enemy, me, spell.radius)
                                 break
                              end
                           end
                        else
                           LineBetween(enemy, me, spell.radius)
                        end
                     end
                  end

                  if not spell.ss and enemy["SpellTime"..spell.key] >= 1 then
                     Circle(enemy, spell.range, red, 2)
                  end

               end
            end
         end
      end
   end
end

AddOnTick(assTick)