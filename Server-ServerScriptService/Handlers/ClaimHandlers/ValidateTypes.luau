-- Services
local ServerScriptStorage = game:GetService("ServerScriptService")

-- Folders
local TypeValidation = ServerScriptStorage.TypeValidation

-- Modules
local ValidateNumber = require(TypeValidation.ValidateNumber)
local ValidateString = require(TypeValidation.ValidateString)
local ValidateInstance = require(TypeValidation.ValidateInstance)

function ValidateTypes(player: Player, timeStamp: number, claimType: string)
	if not ValidateInstance(player, "Player") then
		return false
	end

	if not ValidateNumber(timeStamp) then
		return false
	end
	
	if not ValidateString(claimType) then
		return false
	end
	
	return true
end

return ValidateTypes