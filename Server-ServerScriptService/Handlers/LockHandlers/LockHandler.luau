-- Modules
local ValidateTypes = require(script.ValidateTypes)
local ValidateArguments = require(script.ValidateArguments)

local LockHandler = {}

function LockHandler.validateTypes(player: Player, timeStamp: number, material: string, action: string)
	return ValidateTypes(player, timeStamp, material, action)
end

function LockHandler.validateArguments(timeStamp: number, material: string, action: string, materialInventory)
	return ValidateArguments(timeStamp, material, action, materialInventory)
end

return LockHandler