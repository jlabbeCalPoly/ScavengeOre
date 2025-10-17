-- Services
local ServerScriptStorage = game:GetService("ServerScriptService")

-- Folders
local TypeValidation = ServerScriptStorage.TypeValidation

-- Modules
local ValidateNumber = require(TypeValidation.ValidateNumber)
local ValidateInstance = require(TypeValidation.ValidateInstance)
local ValidateString = require(TypeValidation.ValidateString)

function ValidateTypes(player: Player, timeStamp: number, material: string, action: string)
	if not ValidateInstance(player, "Player") then
		return false
	end

	if not ValidateNumber(timeStamp) then
		return false
	end
	
	if not ValidateString(material) then
		return false
	end
	
	if not ValidateString(action) then
		return false
	end
	
	return true
end

return ValidateTypes