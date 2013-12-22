
function trunc(num, places)
   if not places then places = 2 end
   local factor = 10^places
   return math.floor(num*factor)/factor
end

function class()
    local cls = {}
    cls.__index = cls
    return setmetatable(cls, {__call = function (c, ...)
        local instance = setmetatable({}, cls)
        if cls.__init then
            cls.__init(instance, ...)
        end
        return instance
    end})
end

