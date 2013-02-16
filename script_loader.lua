scriptlist={}
--scripttimercallbacks={}
function GetMinBBox(target)
local pos={}
pos.x=target.minBBx
pos.y=target.minBBy
pos.z=target.minBBz
return pos
end
function GetMaxBBox(target)
local pos={}
pos.x=target.maxBBx
pos.y=target.maxBBy
pos.z=target.maxBBz
return pos
end
function scriptloader (scriptname,scriptnum)
printtext(tostring(scriptname) .. " " .. tostring(scriptnum));
local scriptenv = {}   -- a new table (one for each script)
local scriptenv_mt = {__index=_G}  -- the metatable for scriptenv
setmetatable (scriptenv, scriptenv_mt)

local chunk,msg = loadfile(scriptname)      -- loads/compiles the lua chunk
if (chunk ~=nil) then
setfenv (chunk, scriptenv)    -- sets the 'global' env for the script
chunk()
scriptlist[scriptnum]=scriptenv;
else
PrintError(msg)
return msg
end
return scriptname .. " loaded"
end
function dotimercallback(name,num)
--printtext("\n" .. tostring(name) .. " " .. tostring(num));
local f=scriptlist[num][name]()
--f()
end