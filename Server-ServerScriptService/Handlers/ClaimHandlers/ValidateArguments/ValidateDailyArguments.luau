-- Services
local ServerScriptStorage = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local TypeValidation = ServerScriptStorage.TypeValidation
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local ValidateNumber = require(TypeValidation.ValidateNumber)
local TaskData = require(SharedUtility.TaskData)

function ValidateDailyArguments(playerData, timeStamp, taskNum)
	-- First, check the type of the taskNum
	if not ValidateNumber(taskNum) then
		return
	end
	
	if taskNum < 1 or taskNum > 3 then
		return false
	end
	
	local dailyData = playerData["DailyData"]
	if timeStamp > dailyData["Reset"] then
		return false
	end
	
	-- Validate the claim
	local taskDetails = dailyData["Tasks"][taskNum]
	local taskKey, hasClaimed, progress = unpack(taskDetails)
	if hasClaimed then
		return false
	end
	
	if not TaskData.checkTaskProgress(taskKey, progress, dailyData["Location"]) then
		return false
	end
	-- Set the tasks state to "claimed"
	taskDetails[2] = true
	
	return true
end

return ValidateDailyArguments