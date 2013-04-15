ssers = {
   blitz = {
      spell = {type="line", range=925, block=true, width=80}
   },
   lux = {
      spell = {type="circle", width=350}   
   },
   morgana = {
      spell = {type="line", range=1300, block=true, width=60}
   },
   ezreal = {
      spell = {type="line", range=1100, block=true, width=60}
   },
   thresh = {
      spell = {type="line", range=1075, block=true, width=60}
   },
   nautilus = {
      spell = {type="line", range=950, block=true, width=80}
   },
   leesin = {
      spell = {type="line", range=975, block=true, width=60}
   },
   nidalee = {
      spell = {type="line", range=1500, block=true, width=80}
   }
}


function assTick()
   for _,enemy in ipairs(ENEMIES) do
      if enemy.name == "Blitzcrank" then
         ssers.blitz.obj = enemy
      elseif enemy.name == "Lux" then
         ssers.lux.obj = enemy
      elseif enemy.name == "Morgana" then
         ssers.morgana.obj = enemy
      elseif enemy.name == "Ezreal" then
         ssers.ezreal.obj = enemy
      elseif enemy.name == "Thresh" then
         ssers.thresh.obj = enemy
      elseif enemy.name == "Nautilus" then
         ssers.nautalis.obj = enemy
      elseif enemy.name == "LeeSin" then
         ssers.leesin.obj = enemy
      elseif enemy.name == "Nidalee" then
         ssers.nidalee.obj = enemy
      end
   end
   if ModuleConfig.ass then
      for _,enemy in pairs(ssers) do
         if not enemy.visible then
         
         elseif enemy.spell.type == "line" then
            if enemy.obj and enemy.obj.x and GetDistance(enemy.obj) < enemy.spell.range then
               local unblocked = GetUnblocked(enemy.obj, enemy.spell.range, enemy.spell.width, MYMINIONS, ALLIES)
               for _,test in ipairs(unblocked) do
                  if test.charName == me.charName then
                     LineBetween(enemy.obj, me, enemy.spell.width)
                     break
                  end
               end
            end
         end
      end
   end
end

ModuleConfig:addParam("ass", "AntiSkillShot", SCRIPT_PARAM_ONOFF, false)
ModuleConfig:permaShow("ass")

SetTimerCallback("assTick")