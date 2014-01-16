require "Utils"
print("\nMals 3D to 2D Projections\n")
 
TDConfig = scriptConfig("3D", "3D Config")
TDConfig:addParam("e", "Draw", SCRIPT_PARAM_ONKEYDOWN, false, 65)
 
 
function Run()
        --if IsChatOpen() == 0 and TDConfig.e then
                   
                   
        DrawCircle(myHero.x,myHero.y,myHero.z,2*math.sqrt(50),3)
        --DrawCircle(myHero.x,myHero.y+225,myHero.z,2*100,3)
        --DrawCircle(myHero.x,myHero.y,myHero.z+164.5,2*100,1)
        --DrawBox(GetScreenX()/2,GetScreenY()/2-111,5,5,Color.White)
   
   
        --DrawCircle(myHero.x+1300,0,myHero.z,2*math.sqrt(50),3)
        --DrawCircle(myHero.x+1307,0,myHero.z,2*math.sqrt(50),1)
        --DrawBox(GetScreenX()/2+700,GetScreenY()/2,5,5,Color.White)
   
        DrawBox(transform(myHero.x,myHero.y,myHero.z).x,transform(myHero.x,myHero.y,myHero.z).y,5,5,Color.White)
 
 
        --end
end
 
function transform(Cx,Cz,Cy) -- Need to flip flop Y and Z value to make less
--confusing in calculating, since Riot has their y axis pointing up
 
--local Cz=0
local point={x=0,y=0} -- variable we will return at the end of function
 
local ez=1770 --height of the eye determined by guess and check
 
local phi=math.pi*17/90 -- 34 degrees found on google http://na.leagueoflegends.com/board/showthread.php?t=9747
 local theta=3*math.pi/2
local rho=1770/(math.cos(phi)) --Distance from Eye to center of screen with y=0 (Riot coordinates) value
 
print('\nR1 '.. rho)
 
local ex=GetWorldX() -- eye x coordinate
local ey=rho*math.sin(phi)*math.sin(theta)+GetWorldY() -- eye y coordinate
print("\nex: "..ex..", ey: "..ey..", ez: "..ez)
 
--Transform point trying to project into eye coordinates,
--meaning the eye is our new origin
local Ex = Cx-ex
local Ey = Cy-ey
local Ez = Cz-ez
print("\nEx: "..Ex..", Ey: "..Ey..", Ez: "..Ez)
 
--Rotation about the Z axis (Riot's y axis)
local Zx = -Ex*math.sin(theta)+Ey*math.cos(theta)
local Zy = -Ex*math.cos(theta)-Ey*math.sin(theta)
local Zz = Ez
print("\nZx: "..Zx..", Zy: "..Zy..", Zz: "..Zz)
 
--Rotation about the X axis (Riot's x axis) Now the Z axis (Riot's Y axis)
--will point straight from the eye to the center of the screen (negative direction though)
--so positive z is pointing through the eye and out through the back our your head.
--good picture: http://profs.sci.univr.it/~colombar/html_openGL_tutorial/images/perspective_proj_glfrustum.gif
local Vx = Zx
local Vy = Zy*math.cos(phi)+Zz*math.sin(phi)
local Vz = -Zy*math.sin(phi)+Zz*math.cos(phi)
print("\nVx: "..Vx..", Vy: "..Vy..", Vz: "..Vz)
 
--local eyeWorld={x=ex,y=ez,z=ey}
--local spot={x=myHero.x,y=myHero.y,z=myHero.z+164.5}
--local rho2 = math.sqrt(rho*rho+164.5*164.5-2*rho*164.5*math.cos(phi+math.pi/2))
--print('\nR2 '.. rho2)
--local Angle = math.acos((rho2*rho2+164.5*164.5-rho*rho)/(2*rho2*164.5))
--print('\nA '.. Angle)
--local objectSize=164.5/math.sin(180-34-Angle)
--print('\nObjSize '.. objectSize)
local d=-rho*1.458*111/304.59 -- distamce of the virtual screen from eye
--local dyz=-rho*111/304.59--700/1000--111/225--
 
local X = -d*Vx/Vz
local Y = -d*Vy/Vz
 
print("\nX: "..X..",Y: "..Y)
local Xdone=GetScreenX()/2-X
local Ydone=GetScreenY()/2+Y
 
print("\nXdone: "..Xdone..", Ydone: "..Ydone)
point.x=Xdone
point.y=Ydone
 
 
return point
end
 
 
function GetD(p1, p2)
                if p2 == nil then p2 = myHero end
        if (p1.z == nil or p2.z == nil) and p1.x~=nil and p1.y ~=nil and p2.x~=nil and p2.y~=nil then
                px=p1.x-p2.x
                py=p1.y-p2.y
                if px~=nil and py~=nil then
                        px2=px*px
                        py2=py*py
                        if px2~=nil and py2~=nil then
                                return math.sqrt(px2+py2)
                        else
                                return 99999
                        end
                else
                        return 99999
                end
 
        elseif p1.x~=nil and p1.z ~=nil and p2.x~=nil and p2.z~=nil then
                px=p1.x-p2.x
                pz=p1.z-p2.z
                if px~=nil and pz~=nil then
                        px2=px*px
                        pz2=pz*pz
                        if px2~=nil and pz2~=nil then
                                return math.sqrt(px2+pz2)
                        else
                                return 99999
                        end
                else    
                        return 99999
                end
 
        else
                                return 99999
        end
end
 
 
SetTimerCallback("Run")