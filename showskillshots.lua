require 'Utils'
require 'winapi'
require 'SKeys'
local send = require 'SendInputScheduled'
require "timCommon"

local version = '1.0'

local LINE = 1 -- standard projectile
local LINE_POINT = 2 -- projectile with endpoint
local AOE = 3 -- standard aoe
local LINE_GLOBAL = 4 -- global projectile
local TELEPORT = 5

local skillshotArray = {}
local colorcyan = 0x0000FFFF
local coloryellow = 0xFFFFFF00
local colorgreen = 0xFF00FF00
local skillshotcharexist = false
local show_allies=0

function SSSTick()
   if ModuleConfig.ass then
      Skillshots()
      if blockAndMove ~= nil then blockAndMove() end
      send.tick()
   end
end

function CreateBlockAndMoveToXYZ(x, y, z)
   local move_start_time, move_dest, move_pending
   send.block_input(true,750,MakeStateMatch)
   move_start_time = os.clock()
   move_dest = {x=x, y=y, z=z}
   move_pending = true

   MoveToXYZ(move_dest.x, 0, move_dest.z)

   run_once = false
   return function()
      if move_pending then
         local waited_too_long = move_start_time + 1 < os.clock()    
         if waited_too_long or GetDistance(move_dest)<75 then
            move_pending = false
            send.block_input(false)
         end
      else
      end
   end
end

function MakeStateMatch(changes)
   for scode,flag in pairs(changes) do    
      pp(scode)
      if flag then pp('went down') else pp('went up') end
      local vk = winapi.map_virtual_key(scode, 3)
      local is_down = winapi.get_async_key_state(vk)
      if flag then -- went down
         if is_down then
            send.wait(60)
            send.key_down(scode)
            send.wait(60)
         else
            -- up before, up after, down during, we don't care
         end            
      else -- went up
         if is_down then
            -- down before, down after, up during, we don't care
         else
            send.wait(60)
            send.key_up(scode)
            send.wait(60)
         end
      end
   end
end

local function OnProcessSpell(unit,spell)
   if not ModuleConfig.ass then
      return
   end
   local P1 = spell.startPos
   local P2 = spell.endPos
   local calc = (math.floor(math.sqrt((P2.x-unit.x)^2 + (P2.z-unit.z)^2)))
   if string.find(unit.name,"Minion_") == nil and string.find(unit.name,"Turret_") == nil then
      if (unit.team ~= myHero.team or (show_allies==1)) and string.find(spell.name,"Basic") == nil then
          for i=1, #skillshotArray, 1 do
            local maxdist
            local dodgeradius
            dodgeradius = skillshotArray[i].radius
            maxdist = skillshotArray[i].maxdistance
            if string.find(spell.name, skillshotArray[i].name) then
               skillshotArray[i].shot = 1
               skillshotArray[i].lastshot = os.clock()
               if skillshotArray[i].type == LINE then
                  skillshotArray[i].p1x = unit.x
                  skillshotArray[i].p1y = unit.y
                  skillshotArray[i].p1z = unit.z
                  skillshotArray[i].p2x = unit.x + (maxdist)/calc*(P2.x-unit.x)
                  skillshotArray[i].p2y = P2.y
                  skillshotArray[i].p2z = unit.z + (maxdist)/calc*(P2.z-unit.z)
                  dodgelinepass(unit, P2, dodgeradius, maxdist)
               elseif skillshotArray[i].type == LINE_POINT then
                  skillshotArray[i].px = P2.x
                  skillshotArray[i].py = P2.y
                  skillshotArray[i].pz = P2.z
                  dodgelinepoint(unit, P2, dodgeradius)
               elseif skillshotArray[i].type == AOE then
                  skillshotArray[i].skillshotpoint = calculateLineaoe(unit, P2, maxdist)
                  dodgeaoe(unit, P2, dodgeradius)
               elseif skillshotArray[i].type == LINE_GLOBAL then
                  skillshotArray[i].px = unit.x + (maxdist)/calc*(P2.x-unit.x)
                  skillshotArray[i].py = P2.y
                  skillshotArray[i].pz = unit.z + (maxdist)/calc*(P2.z-unit.z)
                  dodgelinepass(unit, P2, dodgeradius, maxdist)
               elseif skillshotArray[i].type == TELEPORT then
                  skillshotArray[i].skillshotpoint = calculateLineaoe2(unit, P2, maxdist)
                  dodgeaoe(unit, P2, dodgeradius)
               end
            end
         end
      end
   end
end
AddOnSpell(OnProcessSpell)

function dodgeaoe(pos1, pos2, radius)
   local calc = (math.floor(math.sqrt((pos2.x-myHero.x)^2 + (pos2.z-myHero.z)^2)))
   local dodgex
   local dodgez
   dodgex = pos2.x + ((radius+100)/calc)*(myHero.x-pos2.x)
   dodgez = pos2.z + ((radius+100)/calc)*(myHero.z-pos2.z)
   if calc < radius then
      CreateBlockAndMoveToXYZ(dodgex,0,dodgez)
   end
end

function dodgelinepoint(pos1, pos2, radius)
   local calc1 = (math.floor(math.sqrt((pos2.x-myHero.x)^2 + (pos2.z-myHero.z)^2)))
   local calc2 = (math.floor(math.sqrt((pos1.x-myHero.x)^2 + (pos1.z-myHero.z)^2)))
   local calc4 = (math.floor(math.sqrt((pos1.x-pos2.x)^2 + (pos1.z-pos2.z)^2)))
   local calc3
   local perpendicular
   local k
   local x4
   local z4
   local dodgex
   local dodgez
   perpendicular = (math.floor((math.abs((pos2.x-pos1.x)*(pos1.z-myHero.z)-(pos1.x-myHero.x)*(pos2.z-pos1.z)))/(math.sqrt((pos2.x-pos1.x)^2 + (pos2.z-pos1.z)^2))))
   k = ((pos2.z-pos1.z)*(myHero.x-pos1.x) - (pos2.x-pos1.x)*(myHero.z-pos1.z)) / ((pos2.z-pos1.z)^2 + (pos2.x-pos1.x)^2)
   x4 = myHero.x - k * (pos2.z-pos1.z)
   z4 = myHero.z + k * (pos2.x-pos1.x)
   calc3 = (math.floor(math.sqrt((x4-myHero.x)^2 + (z4-myHero.z)^2)))
   dodgex = x4 + ((radius+100)/calc3)*(myHero.x-x4)
   dodgez = z4 + ((radius+100)/calc3)*(myHero.z-z4)
   if perpendicular < radius and calc1 < calc4 and calc2 < calc4 then
      blockAndMove = CreateBlockAndMoveToXYZ(dodgex,0,dodgez)
   end
end

function dodgelinepass(pos1, pos2, radius, maxDist)
   local pm2x = pos1.x + (maxDist)/(math.floor(math.sqrt((pos1.x-pos2.x)^2 + (pos1.z-pos2.z)^2)))*(pos2.x-pos1.x)
   local pm2z = pos1.z + (maxDist)/(math.floor(math.sqrt((pos1.x-pos2.x)^2 + (pos1.z-pos2.z)^2)))*(pos2.z-pos1.z)
   local calc1 = (math.floor(math.sqrt((pm2x-myHero.x)^2 + (pm2z-myHero.z)^2)))
   local calc2 = (math.floor(math.sqrt((pos1.x-myHero.x)^2 + (pos1.z-myHero.z)^2)))
   local calc3
   local calc4 = (math.floor(math.sqrt((pos1.x-pm2x)^2 + (pos1.z-pm2z)^2)))
   local perpendicular
   local k
   local x4
   local z4
   local dodgex
   local dodgez
   perpendicular = (math.floor((math.abs((pm2x-pos1.x)*(pos1.z-myHero.z)-(pos1.x-myHero.x)*(pm2z-pos1.z)))/(math.sqrt((pm2x-pos1.x)^2 + (pm2z-pos1.z)^2))))
   k = ((pm2z-pos1.z)*(myHero.x-pos1.x) - (pm2x-pos1.x)*(myHero.z-pos1.z)) / ((pm2z-pos1.z)^2 + (pm2x-pos1.x)^2)
   x4 = myHero.x - k * (pm2z-pos1.z)
   z4 = myHero.z + k * (pm2x-pos1.x)
   calc3 = (math.floor(math.sqrt((x4-myHero.x)^2 + (z4-myHero.z)^2)))
   dodgex = x4 + ((radius+100)/calc3)*(myHero.x-x4)
   dodgez = z4 + ((radius+100)/calc3)*(myHero.z-z4)
   if perpendicular < radius and calc1 < calc4 and calc2 < calc4 then
      blockAndMove = CreateBlockAndMoveToXYZ(dodgex,0,dodgez)
   end
end


function calculateLinepass(pos1, pos2, spacing, maxDist)
   local calc = (math.floor(math.sqrt((pos2.x-pos1.x)^2 + (pos2.z-pos1.z)^2)))
   local line = {}
   local point1 = {}
   point1.x = pos1.x
   point1.y = pos1.y
   point1.z = pos1.z
   local point2 = {}
   point1.x = pos1.x + (maxDist)/calc*(pos2.x-pos1.x)
   point1.y = pos2.y
   point1.z = pos1.z + (maxDist)/calc*(pos2.z-pos1.z)
   table.insert(line, point2)
   table.insert(line, point1)
   return line
end

function calculateLineaoe(pos1, pos2, maxDist)
   local line = {}
   local point = {}
   point.x = pos2.x
   point.y = pos2.y
   point.z = pos2.z
   table.insert(line, point)
   return line
end

function calculateLineaoe2(pos1, pos2, maxDist)
   local calc = (math.floor(math.sqrt((pos2.x-pos1.x)^2 + (pos2.z-pos1.z)^2)))
   local line = {}
   local point = {}
   if calc < maxDist then
      point.x = pos2.x
      point.y = pos2.y
      point.z = pos2.z
      table.insert(line, point)
   else
      point.x = pos1.x + maxDist/calc*(pos2.x-pos1.x)
      point.z = pos1.z + maxDist/calc*(pos2.z-pos1.z)
      point.y = pos2.y
      table.insert(line, point)
   end
   return line
end

function calculateLinepoint(pos1, pos2, spacing, maxDist)
    local line = {}
    local point1 = {}
    point1.x = pos1.x
    point1.y = pos1.y
    point1.z = pos1.z
    local point2 = {}
    point1.x = pos2.x
    point1.y = pos2.y
    point1.z = pos2.z
    table.insert(line, point2)
    table.insert(line, point1)
    return line
end

function Skillshots()
   if ModuleConfig.ass == true then
      for i=1, #skillshotArray, 1 do
         if skillshotArray[i].shot == 1 then
            local radius = skillshotArray[i].radius
            local color = skillshotArray[i].color
            if skillshotArray[i].isline == false then
               for number, point in pairs(skillshotArray[i].skillshotpoint) do
                  DrawCircle(point.x, point.y, point.z, radius, color)
               end
            else
               startVector = Vector(skillshotArray[i].p1x,skillshotArray[i].p1y,skillshotArray[i].p1z)
               endVector = Vector(skillshotArray[i].p2x,skillshotArray[i].p2y,skillshotArray[i].p2z)
               directionVector = (endVector-startVector):normalized()
               local angle=0
               if (math.abs(directionVector.x)<.00001) then
                  if directionVector.z > 0 then angle=90
                  elseif directionVector.z < 0 then angle=270
                  else angle=0
                  end
               else
                  local theta = math.deg(math.atan(directionVector.z / directionVector.x))
                  if directionVector.x < 0 then theta = theta + 180 end
                  if theta < 0 then theta = theta + 360 end
                  angle=theta
               end
               angle=((90-angle)*2*math.pi)/360
               DrawLine(startVector.x, startVector.y, startVector.z, GetDistance(startVector, endVector)+170, 1,angle,radius)
            end
         end
      end
   end
   for i=1, #skillshotArray, 1 do
      if skillshotArray[i].lastshot and os.clock() > (skillshotArray[i].lastshot + skillshotArray[i].time) then
         skillshotArray[i].shot = 0
      end
   end
end

function LoadTable()
   -- "Quinn" --
   table.insert(skillshotArray,{name= "QuinnQMissile", maxdistance = 1025, type = LINE, radius = 40, color= coloryellow, time = 1, isline = true })
   -- "Lissandra" --
   table.insert(skillshotArray,{name= "LissandraQ", maxdistance = 725, type = LINE, radius = 100, color= coloryellow, time = 1, isline = true })
   table.insert(skillshotArray,{name= "LissandraE", maxdistance = 1050, type = LINE, radius = 100, color= coloryellow, time = 1.5, isline = true })
   -- "Zac" --
   table.insert(skillshotArray,{name= "ZacQ", maxdistance = 550, type = LINE, radius = 100, color= coloryellow, time = 1, isline = true })
   table.insert(skillshotArray,{name= "ZacE", maxdistance = 1550, type = AOE, radius = 200, color= colorcyan, time = 2, isline = false })
   -- "Syndra" --
   table.insert(skillshotArray,{name= "SyndraQ", maxdistance = 800, type = AOE, radius = 200, color= coloryellow, time = 1, isline = false })
   table.insert(skillshotArray,{name= "SyndraE", maxdistance = 650, type = LINE, radius = 100, color= coloryellow, time = 0.5, isline = true })
   table.insert(skillshotArray,{name= "syndrawcast", maxdistance = 950, type = AOE, radius = 200, color= colorcyan, time = 1, isline = false })
   -- "Jayce" --
   table.insert(skillshotArray,{name= "jayceshockblast", maxdistance = 1470, type = LINE, radius = 100, color= colorcyan, time = 1, isline = true })
   -- "Nami" --
   table.insert(skillshotArray,{name= "NamiQ", maxdistance = 875, type = AOE, radius = 200, color= coloryellow, time = 1, isline = false })
   table.insert(skillshotArray,{name= "NamiR", maxdistance = 2550, type = LINE, radius = 350, color= colorcyan, time = 3, isline = true })
   -- "Vi" --
   table.insert(skillshotArray,{name= "ViQ", maxdistance = 900, type = LINE, radius = 150, color= coloryellow, time = 1, isline = true })
   -- "Thresh" --
   table.insert(skillshotArray,{name= "ThreshQ", maxdistance = 1100, type = LINE, radius = 100, color= coloryellow, time = 1.5, isline = false })
   -- "Khazix" --
   table.insert(skillshotArray,{name= "KhazixE", maxdistance = 600, type = AOE, radius = 200, color= colorcyan, time = 1, isline = false })
   table.insert(skillshotArray,{name= "KhazixW", maxdistance = 1000, type = LINE, radius = 120, color= coloryellow, time = 1, isline = true })
   table.insert(skillshotArray,{name= "khazixwlong", maxdistance = 1000, type = LINE, radius = 150, color= coloryellow, time = 1, isline = true })
   table.insert(skillshotArray,{name= "khazixelong", maxdistance = 900, type = AOE, radius = 200, color= colorcyan, time = 1, isline = false })
   -- "Elise" --
   table.insert(skillshotArray,{name= "EliseHumanE", maxdistance = 1075, type = LINE, radius = 100, color= colorcyan, time = 1, isline = true })
   -- "Zed" --
   table.insert(skillshotArray,{name= "ZedShuriken", maxdistance = 900, type = LINE, radius = 100, color= coloryellow, time = 1, isline = true })
   table.insert(skillshotArray,{name= "ZedShadowDash", maxdistance = 550, type = AOE, radius = 150, color= colorcyan, time = 1, isline = false })
   table.insert(skillshotArray,{name= "zedw2", maxdistance = 550, type = AOE, radius = 150, color= colorcyan, time = 0.5, isline = false })
   -- "Ahri" --
   table.insert(skillshotArray,{name= "AhriOrbofDeception", maxdistance = 880, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true})
   table.insert(skillshotArray,{name= "AhriSeduce", maxdistance = 975, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true})
   -- "Amumu" --
   table.insert(skillshotArray,{name= "BandageToss", maxdistance = 1100, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true})
   -- "Anivia" --
   table.insert(skillshotArray,{name= "FlashFrostSpell", maxdistance = 1100, type = LINE, radius = 90, color= colorcyan, time = 2, isline = true})
   -- "Ashe" --
   table.insert(skillshotArray,{name= "EnchantedCrystalArrow", maxdistance = 50000, type = LINE_GLOBAL, radius = 120, color= colorcyan, time = 4, isline = true})
   -- "Blitzcrank" --
   table.insert(skillshotArray,{name= "RocketGrabMissile", maxdistance = 925, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true})
   -- "Brand" --
   table.insert(skillshotArray,{name= "BrandBlazeMissile", maxdistance = 1050, type = LINE, radius = 70, color= colorcyan, time = 1, isline = true})
   table.insert(skillshotArray,{name= "BrandFissure", maxdistance = 900, type = AOE, radius = 250, color= coloryellow, time = 1, isline = false })
   -- "Cassiopeia" --
   table.insert(skillshotArray,{name= "CassiopeiaMiasma", maxdistance = 850, type = AOE, radius = 175, color= coloryellow, time = 1, isline = false })
   table.insert(skillshotArray,{name= "CassiopeiaNoxiousBlast", maxdistance = 850, type = AOE, radius = 75, color= coloryellow, time = 1, isline = false })
   -- "Caitlyn" --
   table.insert(skillshotArray,{name= "CaitlynEntrapmentMissile", maxdistance = 1000, type = LINE, radius = 50, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "CaitlynPiltoverPeacemaker", maxdistance = 1300, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true})
   -- "Corki" --
   table.insert(skillshotArray,{name= "MissileBarrageMissile", maxdistance = 1225, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "MissileBarrageMissile2", maxdistance = 1225, type = LINE, radius = 100, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "CarpetBomb", maxdistance = 800, type = LINE_POINT, radius = 150, color= colorcyan, time = 1, isline = true })
   -- "Chogath" --
   table.insert(skillshotArray,{name= "Rupture", maxdistance = 950, type = AOE, radius = 275, color= coloryellow, time = 1.5, isline = false })
   -- "DrMundo" --
   table.insert(skillshotArray,{name= "InfectedCleaverMissile", maxdistance = 1000, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true })
   -- "Heimerdinger" --
   table.insert(skillshotArray,{name= "CH1ConcussionGrenade", maxdistance = 950, type = AOE, radius = 225, color= coloryellow, time = 1.5, isline = true })
   -- "Draven" --
   table.insert(skillshotArray,{name= "DravenDoubleShot", maxdistance = 1050, type = LINE, radius = 125, color= colorcyan, time = 1, isline = true  })
   table.insert(skillshotArray,{name= "DravenRCast", maxdistance = 5000, type = LINE, radius = 100, color= colorcyan, time = 4, isline = true })
   -- "Ezreal" --
   table.insert(skillshotArray,{name= "EzrealEssenceFluxMissile", maxdistance = 900, type = LINE, radius = 100, color= colorcyan, time = 1, isline = true  })
   table.insert(skillshotArray,{name= "EzrealMysticShotMissile", maxdistance = 1100, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true  })
   table.insert(skillshotArray,{name= "EzrealTrueshotBarrage", maxdistance = 5000, type = LINE_GLOBAL, radius = 150, color= colorcyan, time = 4, isline = true  })
   -- table.insert(skillshotArray,{name= "EzrealArcaneShift", maxdistance = 475, type = TELEPORT, radius = 100, color= colorgreen, time = 1, isline = true  })
   -- "Fizz" --
   table.insert(skillshotArray,{name= "FizzMarinerDoom", maxdistance = 1275, type = LINE_POINT, radius = 100, color= colorcyan, time = 1.5, isline = true })
   -- "FiddleSticks" --
   table.insert(skillshotArray,{name= "Crowstorm", maxdistance = 800, type = AOE, radius = 600, color= coloryellow, time = 1.5, isline = false  })
   -- "Karthus" --
   table.insert(skillshotArray,{name= "LayWaste", maxdistance = 875, type = AOE, radius = 150, color= coloryellow, time = 1, isline = false })
   -- "Galio" --
   table.insert(skillshotArray,{name= "GalioResoluteSmite", maxdistance = 905, type = AOE, radius = 200, color= coloryellow, time = 1.5, isline = false })
   table.insert(skillshotArray,{name= "GalioRighteousGust", maxdistance = 1000, type = LINE, radius = 120, color= colorcyan, time = 1.5, isline = true })
   -- "Graves" --
   table.insert(skillshotArray,{name= "GravesChargeShot", maxdistance = 1000, type = LINE, radius = 110, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "GravesClusterShot", maxdistance = 750, type = LINE, radius = 50, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "GravesSmokeGrenade", maxdistance = 700, type = AOE, radius = 275, color= coloryellow, time = 1.5, isline = false })
   -- "Gragas" --
   table.insert(skillshotArray,{name= "GragasBarrelRoll", maxdistance = 1100, type = AOE, radius = 320, color= coloryellow, time = 2.5, isline = false })
   table.insert(skillshotArray,{name= "GragasBodySlam", maxdistance = 650, type = LINE_POINT, radius = 60, color= colorcyan, time = 1.5, isline = true })
   table.insert(skillshotArray,{name= "GragasExplosiveCask", maxdistance = 1050, type = AOE, radius = 400, color= coloryellow, time = 1.5, isline = false })
   -- "Irelia" --
   table.insert(skillshotArray,{name= "IreliaTranscendentBlades", maxdistance = 1200, type = LINE, radius = 150, color= colorcyan, time = 0.8, isline = true })
   -- "Janna" --
   table.insert(skillshotArray,{name= "HowlingGale", maxdistance = 1700, type = LINE, radius = 100, color= colorcyan, time = 2, isline = true })
   -- "JarvanIV" --
   table.insert(skillshotArray,{name= "JarvanIVDemacianStandard", maxdistance = 830, type = AOE, radius = 150, color= coloryellow, time = 2, isline = false })
   table.insert(skillshotArray,{name= "JarvanIVDragonStrike", maxdistance = 770, type = LINE, radius = 70, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "JarvanIVCataclysm", maxdistance = 650, type = AOE, radius = 300, color= coloryellow, time = 1.5, isline = false })
   -- "Kassadin" --
   table.insert(skillshotArray,{name= "RiftWalk", maxdistance = 700, type = TELEPORT, radius = 150, color= colorgreen, time = 1, isline = false })
   -- "Katarina" --
   table.insert(skillshotArray,{name= "ShadowStep", maxdistance = 700, type = AOE, radius = 75, color= colorgreen, time = 1, isline = false })
   -- "Kennen" --
   table.insert(skillshotArray,{name= "KennenShurikenHurlMissile1", maxdistance = 1050, type = LINE, radius = 75, color= colorcyan, time = 1, isline = true })
   -- "KogMaw" --
   table.insert(skillshotArray,{name= "KogMawVoidOozeMissile", maxdistance = 1115, type = LINE, radius = 100, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "KogMawLivingArtillery", maxdistance = 2200, type = AOE, radius = 200, color= coloryellow, time = 1.5, isline = false })
   -- "Leblanc" --
   table.insert(skillshotArray,{name= "LeblancSoulShackle", maxdistance = 1000, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "LeblancSoulShackleM", maxdistance = 1000, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "LeblancSlide", maxdistance = 600, type = AOE, radius = 250, color= coloryellow, time = 1, isline = false })
   table.insert(skillshotArray,{name= "LeblancSlideM", maxdistance = 600, type = AOE, radius = 250, color= coloryellow, time = 1, isline = false  })
   table.insert(skillshotArray,{name= "leblancslidereturn", maxdistance = 1000, type = AOE, radius = 50, color= colorgreen, time = 1, isline = false  })
   table.insert(skillshotArray,{name= "leblancslidereturnm", maxdistance = 1000, type = AOE, radius = 50, color= colorgreen, time = 1, isline = false })
   -- "LeeSin" --
   table.insert(skillshotArray,{name= "BlindMonkQOne", maxdistance = 975, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "BlindMonkRKick", maxdistance = 1200, type = LINE, radius = 100, color= colorcyan, time = 1, isline = true })
   -- "Leona" --
   table.insert(skillshotArray,{name= "LeonaZenithBladeMissile", maxdistance = 700, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true })
   -- "Lucian" --
   table.insert(skillshotArray,{name= "LucianQ", maxdistance = 1100, type = LINE, radius = 100, color= colorcyan, time = 0.75, isline = true })
   table.insert(skillshotArray,{name= "LucianW", maxdistance = 1000, type = LINE, radius = 150, color= colorcyan, time = 1.5, isline = true })
   table.insert(skillshotArray,{name= "LucianR", maxdistance = 1400, type = LINE, radius = 250, color= colorcyan, time = 3, isline = true })
   -- "Lux" --
   table.insert(skillshotArray,{name= "LuxLightBinding", maxdistance = 1175, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "LuxLightStrikeKugel", maxdistance = 1100, type = AOE, radius = 300, color= coloryellow, time = 2.5, isline = false })
   table.insert(skillshotArray,{name= "LuxMaliceCannon", maxdistance = 3000, type = LINE, radius = 180, color= colorcyan, time = 1.5, isline = true })
   -- "Lulu" --
   table.insert(skillshotArray,{name= "LuluQ", maxdistance = 925, type = LINE, radius = 50, color= colorcyan, time = 1, isline = true, px =0, py =0 , pz =0 })
   -- "Maokai" --
   table.insert(skillshotArray,{name= "MaokaiTrunkLineMissile", maxdistance = 600, type = LINE, radius = 100, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "MaokaiSapling2", maxdistance = 1100, type = AOE, radius = 350 , color= coloryellow, time = 1, isline = false })
   -- "Malphite" --
   table.insert(skillshotArray,{name= "UFSlash", maxdistance = 1000, type = AOE, radius = 325, color= coloryellow, time = 1, isline = false })
   -- "Malzahar" --
   table.insert(skillshotArray,{name= "AlZaharCalloftheVoid", maxdistance = 900, type = AOE, radius = 100 , color= coloryellow, time = 1, isline = false })
   table.insert(skillshotArray,{name= "AlZaharNullZone", maxdistance = 800, type = AOE, radius = 250 , color= coloryellow, time = 1, isline = false })
   -- "MissFortune" --
   table.insert(skillshotArray,{name= "MissFortuneScattershot", maxdistance = 800, type = AOE, radius = 400, color= coloryellow, time = 1, isline = false  })
   -- "Morgana" --
   table.insert(skillshotArray,{name= "DarkBindingMissile", maxdistance = 1300, type = LINE, radius = 90, color= colorcyan, time = 1.5, isline = true })
   table.insert(skillshotArray,{name= "TormentedSoil", maxdistance = 900, type = AOE, radius = 300, color= coloryellow, time = 1.5, isline = false  })
   -- "Nautilus" --
   table.insert(skillshotArray,{name= "NautilusAnchorDrag", maxdistance = 950, type = LINE, radius = 150, color= colorcyan, time = 1.5, isline = true })
   -- "Nidalee" --
   table.insert(skillshotArray,{name= "JavelinToss", maxdistance = 1500, type = LINE, radius = 150, color= colorcyan, time = 1.5, isline = true  })
   -- "Nocturne" --
   table.insert(skillshotArray,{name= "NocturneDuskbringer", maxdistance = 1200, type = LINE, radius = 150, color= colorcyan, time = 1.5, isline = true  })
   -- "Olaf" --
   table.insert(skillshotArray,{name= "OlafAxeThrow", maxdistance = 1000, type = LINE_POINT, radius = 100, color= colorcyan, time = 1.5, isline = true })
   -- "Orianna" --
   table.insert(skillshotArray,{name= "OrianaIzunaCommand", maxdistance = 825, type = AOE, radius = 150, color= coloryellow, time = 1.5, isline = false  })
   -- "Renekton" --
   table.insert(skillshotArray,{name= "RenektonSliceAndDice", maxdistance = 450, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true  })
   table.insert(skillshotArray,{name= "renektondice", maxdistance = 450, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true  })
   -- "Rumble" --
   table.insert(skillshotArray,{name= "RumbleGrenadeMissile", maxdistance = 1000, type = LINE, radius = 100, color= colorcyan, time = 1.5, isline = true  })
   table.insert(skillshotArray,{name= "RumbleCarpetBomb", maxdistance = 1700, type = LINE, radius = 100, color= coloryellow, time = 1.5, isline = true  })
   -- "Sivir" --
   table.insert(skillshotArray,{name= "SpiralBlade", maxdistance = 1100, type = LINE, radius = 100, color= colorcyan, time = 1, isline = true })
   -- "Singed" --
   table.insert(skillshotArray,{name= "MegaAdhesive", maxdistance = 1000, type = AOE, radius = 350, color= coloryellow, time = 1.5, isline = false  })
   -- "Shen" --
   table.insert(skillshotArray,{name= "ShenShadowDash", maxdistance = 600, type = LINE_POINT, radius = 150, color= colorcyan, time = 1, isline = true  })
   -- "Shaco" --
   table.insert(skillshotArray,{name= "Deceive", maxdistance = 500, type = TELEPORT, radius = 100, color= colorgreen, time = 3.5, isline = false  })
   -- "Shyvana" --
   table.insert(skillshotArray,{name= "ShyvanaTransformLeap", maxdistance = 925, type = LINE, radius = 150, color= colorcyan, time = 1.5, isline = true })
   table.insert(skillshotArray,{name= "ShyvanaFireballMissile", maxdistance = 1000, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true })
   -- "Skarner" --
   table.insert(skillshotArray,{name= "SkarnerFracture", maxdistance = 600, type = LINE, radius = 100, color= colorcyan, time = 1, isline = true })
   -- "Sona" --
   table.insert(skillshotArray,{name= "SonaCrescendo", maxdistance = 1000, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true })
   -- "Sejuani" --
   table.insert(skillshotArray,{name= "SejuaniGlacialPrison", maxdistance = 1150, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true })
   -- "Swain" --
   table.insert(skillshotArray,{name= "SwainShadowGrasp", maxdistance = 900, type = AOE, radius = 265 , color= coloryellow, time = 1.5, isline = false })
   -- "Tryndamere" --
   table.insert(skillshotArray,{name= "Slash", maxdistance = 600, type = LINE_POINT, radius = 100, color= colorcyan, time = 1, isline = true })
   -- "Tristana" --
   table.insert(skillshotArray,{name= "RocketJump", maxdistance = 900, type = AOE, radius = 200, color= coloryellow, time = 1, isline = false })
   -- "TwistedFate" --
   table.insert(skillshotArray,{name= "WildCards", maxdistance = 1450, type = LINE, radius = 150, color= colorcyan, time = 5, isline = true })
   -- "Urgot" --
   table.insert(skillshotArray,{name= "UrgotHeatseekingLineMissile", maxdistance = 1000, type = LINE, radius = 150, color= colorcyan, time = 0.8, isline = true })
   table.insert(skillshotArray,{name= "UrgotPlasmaGrenade", maxdistance = 950, type = AOE, radius = 300, color= coloryellow, time = 1, isline = false  })
   -- "Vayne" --
   -- table.insert(skillshotArray,{name= "VayneTumble", maxdistance = 250, type = TELEPORT, radius = 100, color= colorgreen, time = 1, isline = false  })
   -- "Varus" --
   table.insert(skillshotArray,{name= "VarusQ", maxdistance = 1475, type = LINE, radius = 50, color= coloryellow, time = 1})
   table.insert(skillshotArray,{name= "VarusR", maxdistance = 1075, type = LINE, radius = 150, color= colorcyan, time = 1.5, isline = true })
   -- "Veigar" --
   table.insert(skillshotArray,{name= "VeigarDarkMatter", maxdistance = 900, type = AOE, radius = 225, color= coloryellow, time = 2, isline = false  })
   -- "Viktor" --
   --table.insert(skillshotArray,{name= "ViktorDeathRay", maxdistance = 700, type = LINE, radius = 150, color= coloryellow, time = 2})
   -- "Xerath" --
   table.insert(skillshotArray,{name= "xeratharcanopulsedamage", maxdistance = 900, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true })
   table.insert(skillshotArray,{name= "xeratharcanopulsedamageextended", maxdistance = 1300, type = LINE, radius = 150, color= colorcyan, time = 1, isline = true  })
   table.insert(skillshotArray,{name= "xeratharcanebarragewrapper", maxdistance = 900, type = AOE, radius = 250, color= coloryellow, time = 1, isline = false })
   table.insert(skillshotArray,{name= "xeratharcanebarragewrapperext", maxdistance = 1300, type = AOE, radius = 250, color= coloryellow, time = 1, isline = false  })
   -- "Ziggs" --
   table.insert(skillshotArray,{name= "ZiggsQ", maxdistance = 850, type = AOE, radius = 160, color= coloryellow, time = 1, isline = true  })
   table.insert(skillshotArray,{name= "ZiggsW", maxdistance = 1000, type = AOE, radius = 225 , color= coloryellow, time = 1, isline = false  })
   table.insert(skillshotArray,{name= "ZiggsE", maxdistance = 900, type = AOE, radius = 250, color= coloryellow, time = 1, isline = false })
   table.insert(skillshotArray,{name= "ZiggsR", maxdistance = 5300, type = AOE, radius = 550, color= coloryellow, time = 3, isline = false })
   -- "Zyra" --
   table.insert(skillshotArray,{name= "ZyraQFissure", maxdistance = 825, type = AOE, radius = 275, color= coloryellow, time = 1.5, isline = true })
   table.insert(skillshotArray,{name= "ZyraGraspingRoots", maxdistance = 1100, type = LINE, radius = 90, color= colorcyan, time = 2, isline = true })
   -- "Diana" --
   table.insert(skillshotArray,{name= "DianaArc", maxdistance = 900, type = AOE, radius = 205, color= coloryellow, time = 1, isline = true })

   skillshotcharexist = true
end

LoadTable()

RegisterLibraryOnTick(SSSTick)
pp(" - Show-/Dodge Skillshots v"..version)