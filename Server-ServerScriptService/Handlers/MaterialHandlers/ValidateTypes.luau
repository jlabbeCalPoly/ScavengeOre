--[[
	Function that validates the types passed in from the "Materials" remote
]]

-- Services
local ServerScriptStorage = game:GetService("ServerScriptService")

-- Folders
local TypeValidation = ServerScriptStorage.TypeValidation

-- Modules
local ValidateNumber = require(TypeValidation.ValidateNumber)
local ValidateInstance = require(TypeValidation.ValidateInstance)

function ValidateTypes(player: Player,
					   timeStamp: number,
					   entity: Model)
	if not ValidateInstance(player, "Player") then
		return false
	end
	
	if not ValidateNumber(timeStamp) then
		return false
	end
	
	if not ValidateInstance(entity, "Model") then
		return false
	end
	
	return true
end

return ValidateTypes