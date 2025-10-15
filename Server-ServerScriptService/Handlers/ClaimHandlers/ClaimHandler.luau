-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local TaskData = require(SharedUtility.TaskData)
local WeeklyData = require(SharedUtility.WeeklyData)
local MaterialPackData = require(SharedUtility.MaterialPackData)
local ValidateTypes = require(script.ValidateTypes)
local ValidateArguments = require(script.ValidateArguments)
local RelicGeneration = require(script.RelicGeneration)
local RarityGeneration = require(script.RarityGeneration)

local ClaimHandler = {}

function ClaimHandler.validateTypes(player: Player, timeStamp: number, claimType)
	return ValidateTypes(player, timeStamp, claimType)
end

function ClaimHandler.validateArguments(timeStamp, claimType, taskNum, playerData)
	return ValidateArguments(timeStamp, claimType, taskNum,  playerData)
end

function ClaimHandler.relicGeneration(unlockedLocations, grant)
	return RelicGeneration(unlockedLocations, grant)
end

function ClaimHandler.rarityGeneration(unlockedLocations, count)
	return RarityGeneration(unlockedLocations, count)
end

function ClaimHandler.getDailyRewardData(specification: number, tasks)
	return {
		["Amplified Voucher"] = TaskData.getReward(specification, tasks)
	}
end

function ClaimHandler.getWeeklyRewardData(specification: number, location)
	return WeeklyData.getDataServer(specification, location)
end

function ClaimHandler.getMaterialPackData(packKey: string, location)
	return MaterialPackData.getMaterialPackQuantityData(packKey, location)
end

return ClaimHandler