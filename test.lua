function GetVarArg(...)
    if arg==nil then
        local n = select('#', ...)
        local t = {}
        local v
        for i=1,n do
            v = select(i, ...)
            --print('\nv = '..tostring(v))
            table.insert(t,v)
        end
        return t
    else
        return arg
    end
end
function GetSelf() end
printtext = print
require "basicUtils"

function foo(...)
   local arg = GetVarArg(...)

   pp(arg)
end

foo(1,2,3)