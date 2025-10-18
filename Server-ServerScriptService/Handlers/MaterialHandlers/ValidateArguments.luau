--[[
	Function that validates the values passed in from the "Materials" remote
]]

-- Modules
local GetEntityLocation = require(script.Parent.GetEntityLocation)

function ValidateArguments(timeStamp: number,
						   entityName: string,
						   unlockedLocations: number)
	-- validate timestamp
	local now = workspace:GetServerTimeNow()
	if timeStamp > now then
		return false
	end
	if timeStamp < now - 1 then
		return false
	end
	
	-- validate entity 
	local entityLocation = GetEntityLocation(entityName)
	if entityLocation == nil then
		return false
	end
	
	-- validate the player can access the entity on the map
	if entityLocation > unlockedLocations then
		return false
	end
	
	return true
end

return ValidateArguments