-- Modules
local ValidateChestArguments = require(script.ValidateChestArguments)
local ValidateDailyArguments = require(script.ValidateDailyArguments)
local ValidateWeeklyArguments = require(script.ValidateWeeklyArguments)

local specificValidators = {
	["Chest"] = ValidateChestArguments,
	["Daily"] = ValidateDailyArguments,
	["Weekly"] = ValidateWeeklyArguments
}

function ValidateArguments(timeStamp: number,
						   claimType: string,
						   taskNum: number?,
						   playerData)
	-- validate timestamp
	local now = workspace:GetServerTimeNow()
	if timeStamp > now then
		return false
	end
	if timeStamp < now - 1 then
		return false
	end
	
	local specificValidator = specificValidators[claimType]
	if not specificValidator then
		return false
	end
	
	return specificValidator(playerData, timeStamp, taskNum)
end

return ValidateArguments