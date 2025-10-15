-- Services
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Remotes = ReplicatedStorage.Remotes
local Handlers = script.Parent

-- Modules
local ExploitHandler = require(Handlers.ExploitHandler)

-- Remotes
local LeaderboardStats = Remotes.LeaderboardStats

-- Ordered data stores
local CashDataStore = DataStoreService:GetOrderedDataStore("Leaderboard", "Cash")
local PowerDataStore = DataStoreService:GetOrderedDataStore("Leaderboard", "Power")

local LeaderboardHandler = {}

local cashLeaderboard = {}
local powerLeaderboard = {}
local untilRefresh = 1200   -- 20 minutes (1200 seconds)

--[[
	Save the given keys to the data store
]]
function LeaderboardHandler.onPlayerLeaving(userId: number, cash: number, power: number)
	local success = false
	local attempt = 0

	repeat
		success, _ = pcall(function()
			CashDataStore:SetAsync(userId, cash)
		end)
		attempt += 1
		if not success then
			task.wait(3)
		end
	until success or attempt == 5
	
	if not success then
		warn("Unable to save data to cash leaderboard for player: "..userId)
	end
	
	success = false
	attempt = 0

	repeat
		success, _ = pcall(function()
			PowerDataStore:SetAsync(userId, power)
		end)
		attempt += 1
		if not success then
			task.wait(3)
		end
	until success or attempt == 5
	
	if not success then
		warn("Unable to save data to power leaderboard for player: "..userId)
	end
end

function LeaderboardHandler.setup()
	local isAscending = false
	local pageSize = 10
	local cashPages
	local powerPages
		
	local success = false
	local attempt = 0

	repeat
		success, cashPages = pcall(function()
			return CashDataStore:GetSortedAsync(isAscending, pageSize)
		end)
		attempt += 1
		if not success then
			task.wait(3)
		end
	until success or attempt == 5
	
	if not success then
		cashPages = {}
		warn("Unable to fetch cash leaderboard data")
	else
		cashPages = cashPages:GetCurrentPage()
	end
	
	local success = false
	local attempt = 0
	
	repeat
		success, powerPages = pcall(function()
			return PowerDataStore:GetSortedAsync(isAscending, pageSize)
		end)
		attempt += 1
		if not success then
			task.wait(3)
		end
	until success or attempt == 5

	if not success then
		powerPages = {}
		warn("Unable to fetch cash leaderboard data")
	else
		powerPages = powerPages:GetCurrentPage()
	end
	
	cashLeaderboard = cashPages
	powerLeaderboard = powerPages
	untilRefresh = 1200
	
	for _, player in pairs(Players:GetPlayers()) do
		LeaderboardStats:FireClient(player, untilRefresh, cashLeaderboard, powerLeaderboard)
	end 
	
	while untilRefresh > 0 do
		untilRefresh -= 1
		task.wait(1)
	end
	
	LeaderboardHandler.setup()
end

LeaderboardStats.OnServerEvent:Connect(function(player: Player)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end	
	
	LeaderboardStats:FireClient(player, untilRefresh, cashLeaderboard, powerLeaderboard)
end)

return LeaderboardHandler