function trunc(num, places)
   if not places then places = 2 end
   local factor = 10^places
   return math.floor(num*factor)/factor
end

local health = 400
local maxHealth = 600

print(1+(1-health/maxHealth)/2)