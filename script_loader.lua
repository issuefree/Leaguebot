-- v01 - 5/15/2013 9:31:16 PM - pcall in dotimercallback
-- v02 - 5/15/2013 9:42:28 PM - pcall in scriptloader

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

function GetLastOrder()
    local pos={}
    pos.x=GetLastOrderX()
    pos.y=GetLastOrderY()
    pos.z=GetLastOrderZ()
    return pos
end

function scriptloader(scriptname,scriptnum)
    printtext(tostring(scriptname) .. " " .. tostring(scriptnum));
    local scriptenv = {}   -- a new table (one for each script)
    local scriptenv_mt = {__index=_G}  -- the metatable for scriptenv
    setmetatable (scriptenv, scriptenv_mt)
    
    local chunk,msg = loadfile(scriptname)      -- loads/compiles the lua chunk
    if (chunk ~=nil) then
        setfenv (chunk, scriptenv)    -- sets the 'global' env for the script
        --chunk()
        local status, err = pcall(chunk)
        if err ~= nil then
            printtext('\nerror loading script: '..tostring(err))    
        end                
        scriptlist[scriptnum]=scriptenv;
    else
        PrintError(msg)
        return msg
    end
    return scriptname .. " loaded"
end

function dotimercallback(name,num)
    local f=scriptlist[num][name]
    local status, err = pcall(f)
    if err ~= nil then
        printtext('\nerror: '..tostring(err))    
    end        
end