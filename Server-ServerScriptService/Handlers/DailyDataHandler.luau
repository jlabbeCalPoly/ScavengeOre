-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local TaskData = require(SharedUtility.TaskData)

local DailyDataHandler = {}

function DailyDataHandler.convertTimestampToPlaytime(timeStamp, playerData)
	local playtimeTask = playerData["DailyData"]["Tasks"][1]
	local progress = TaskData.getProgress(timeStamp, playtimeTask[3])
	
	playtimeTask[3] = progress
end

-- Playtime task will initally have the progress, so calculate the completion timed based on that value
function DailyDataHandler.convertPlaytimeToTimestamp(timeStamp, playerData)
	local playtimeTask = playerData["DailyData"]["Tasks"][1]
	local remaining = TaskData.getRemainingPlaytime(playtimeTask[3])
	
	playtimeTask[3] = timeStamp + remaining
end

function DailyDataHandler.checkReset(timeStamp: number, playerData: { any }, onJoin: boolean?)
	local dailyData = playerData["DailyData"]
	local location = playerData["LevelStats"]["UnlockedLocations"]

	if not dailyData["Reset"] or timeStamp >= dailyData["Reset"] then
		playerData["DailyData"] = TaskData.generateTaskDataServer(dailyData, location, timeStamp, onJoin)
	end
end

function DailyDataHandler.updateTaskData(playerData, list, taskKeys)
	local timeStamp = workspace:GetServerTimeNow()
	DailyDataHandler.checkReset(timeStamp, playerData)
	
	TaskData.updateTaskProgress(playerData["DailyData"], list, taskKeys)
end

function DailyDataHandler.onPlayerAdded(playerData)
	local timeStamp = workspace:GetServerTimeNow()
	DailyDataHandler.checkReset(timeStamp, playerData, true)
	DailyDataHandler.convertPlaytimeToTimestamp(timeStamp, playerData)
end

--[[
	Updates the player's playtime entry when they leave the game
]]
function DailyDataHandler.onPlayerLeaving(playerData)
	local timeStamp = workspace:GetServerTimeNow()
	DailyDataHandler.checkReset(timeStamp, playerData)
	DailyDataHandler.convertTimestampToPlaytime(timeStamp, playerData)
end

return DailyDataHandler