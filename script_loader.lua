-- v01 - 5/15/2013 9:31:16 PM - pcall in dotimercallback
-- v02 - 5/15/2013 9:42:28 PM - pcall in scriptloader
-- v03 - 5/18/2013 2:39:04 PM - handle_error, using xpcall, trying to make sure tracebacks print
-- v04 - 5/18/2013 9:38:36 PM - rework for use with utils 2.0.0
--       add scriptlist_by_name, scriptlist_names, the former needed for new utils.lua
--       added replacement print function here
--       changed to xpcall
-- v05 - 5/20/2013 2:03:42 PM - case insensitive require wrapper
-- v06 - 6/3/2013 8:48:59 AM - cleanup
-- v07 - 6/3/2013 9:59:27 PM - added activescripts global and logic for utils 2.0.7, commented a print statement
-- v08 - 6/7/2013 11:45:51 PM - error handler also does a PrintError so you see it in the hud
-- v09 - 6/9/2013 5:57:59 PM - util tick no longer called in scriptnum 0, to avoid ALWAYS LOADSCRIPT OnWndMsg problem
-- v10 - 6/10/2013 9:20:44 AM - rollback to v08

if not script_loader_loaded then

    printtext('*** script_loader loaded\n')

    function handle_error(err)
        print('\n--\n')
        PrintError(err)
        print(debug.traceback(err))
        print('\n--\n')
    end

    function init()    
        
        scriptlist = {}
        activescripts = {}

        real_require = require
        use_require_wrapper = true
        
        function print(...)
            local n = select('#', ...)
            for i=1,n do
                local v = select(i, ...)
                printtext(tostring(v))
                if n>1 and i<n then
                    printtext('\t')
                end
            end
            printtext('\n')
        end

        -- case insensitive require
        if use_require_wrapper then
            function require(s)
                --print('* require', s)
                return real_require(s:lower())
            end
        else
            require = real_require
        end
        
    end
    
    init()
    
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
        
    function scriptloader(scriptname, scriptnum)
        print('scriptloader:', scriptnum, scriptname)
        local scriptenv = {}   -- a new table (one for each script)
        local scriptenv_mt = {__index=_G}  -- the metatable for scriptenv
        setmetatable (scriptenv, scriptenv_mt)
        
        local chunk, msg = loadfile(scriptname)      -- loads/compiles the lua chunk
        if (chunk ~=nil) then
            setfenv(chunk, scriptenv)    -- sets the 'global' env for the script
            local status, err = xpcall(chunk, handle_error)
            scriptlist[scriptnum]=scriptenv
        else
            PrintError(msg)
            return '{'..tostring(msg)..'}'
        end
        return scriptname .. " loaded"
    end

    function dotimercallback(name, num)            
        activescripts[tostring(num)] = true
        --printtext('<')
        -- reset active scripts when script_gui tick runs, this is how i avoid ListScripts
        -- utils tick happens before script_gui tick, since script_gui requires utils
        if num==0 and name=='GuiTick' then
            activescripts = {}
        end
        --print('dotimercallback:', num, name)
        --printtext(name)
        local f=scriptlist[num][name]        
        --print(type(f), num, name)
        local status, err = xpcall(f, handle_error)
        --printtext('>\n')
    end
    
    --function scriptloader(name, num)
    --    local fn = function() return scriptloader_real(name,num) end
    --    xpcall(fn, handle_error)
    --end

    --function dotimercallback(name, num)
    --    local fn = function() return dotimercallback_real(name,num) end
    --    xpcall(fn, handle_error)
    --end
    
    script_loader_loaded = true
    
end