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



a = "2450,0,1500"
b = "2450,-193,1550"

reg = "(%d+),([-]*%d+),(%d+)"

for x,y,z in string.gmatch(a, reg) do
    pp(x..","..y..","..z)
end

for x,y,z in string.gmatch(b, reg) do
    pp(x..","..y..","..z)
end
