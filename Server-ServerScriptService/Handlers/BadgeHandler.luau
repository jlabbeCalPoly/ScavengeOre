-- Services
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local Relics = require(SharedUtility.Relics)

--[[
	List of ids that can be used to determine which badges the player has when they join
]]
local badgeIds = {
	2480117321168848,
	3913259124803118,
	3089227826655388,
	2113743999013858,
	3561897847417551,
	4299386839643769,
	591286738580183,
	1144700551774767
}

--[[
	location badges, indexed by the location
]]
local locationBadges = {
	
}

--[[
	Relic badges
]]
local relicBadges = {
	["Normal"] = 4299386839643769,
	["Special"] = 1144700551774767,
	["Eternal"] = 591286738580183
}

--[[
	Rarity badges, indexed by rarity (3 = rare, 4 = ultra rare, etc.)
]]
local rarityBadges = {
	[3] = 2480117321168848,
	[4] = 3913259124803118,
	[5] = 3089227826655388,
	[6] = 2113743999013858,
	[7] = 3561897847417551
}

local BadgeHandler = {}

local instanceTracker = {}

function BadgeHandler.onPlayerAdded(player: Player)
	-- Check if the player has any of the badges
	local attempt = 0
	local success = false
	local result = {}

	repeat
		success, result = pcall(function()
			return BadgeService:CheckUserBadgesAsync(player.UserId, badgeIds)
		end)
		
		attempt += 1
		if not success then
			task.wait(2)
		end
	until success or attempt == 5
	
	local earnedBadges = {}
	if success then
		for _, badge in pairs(result) do
			earnedBadges[badge] = true
		end
	end
	
	instanceTracker[player.UserId] = earnedBadges
end

function BadgeHandler.onPlayerRemoving(player: Player)
	if instanceTracker[player.UserId] then
		table.clear(instanceTracker[player.UserId])
		instanceTracker[player.UserId] = nil
	end
end

local function awardBadge(userId, badgeId)
	local attempt = 0
	local success = false
	
	repeat
		success,_ = pcall(function()
			return BadgeService:AwardBadge(userId, badgeId)
		end)
		
		attempt += 1
		if not success then
			task.wait(2)
		end
	until success or attempt == 5
	
	if success then
		instanceTracker[userId][badgeId] = true
	end
end

function BadgeHandler.addLocationBadge(player: Player, location: number)
	local badgeId = locationBadges[location]
	local instanceData = instanceTracker[player.UserId]
	if badgeId and instanceData and not instanceData[badgeId] then
		awardBadge(player.UserId, badgeId)
	end
end

function BadgeHandler.addRelicBadge(player: Player, relic: string)
	local data = Relics.getRelicsData(relic)
	local sellValue = data[4]
	
	-- If there's a sell value, that means the relic is a "Special"
	if sellValue then
		local specialBadge = relicBadges.Special
		local instanceData = instanceTracker[player.UserId]
		if instanceData and not instanceData[specialBadge] then
			awardBadge(player.UserId, specialBadge)
		end
	else
		local normalBadge = relicBadges.Normal
		local instanceData = instanceTracker[player.UserId]
		if instanceData and not instanceData[normalBadge] then
			awardBadge(player.UserId, normalBadge)
		end

		-- Check if the location is a negative number (meaning the relic is from an "Eternal" crafter)
		if data[5] < 0 then
			local eternalBadge = relicBadges.Eternal
			local instanceData = instanceTracker[player.UserId]
			if instanceData and not instanceData[eternalBadge] then
				awardBadge(player.UserId, eternalBadge)
			end
		end
	end
end

function BadgeHandler.addRarityBadge(player: Player, rarity: number)
	local badgeId = rarityBadges[rarity]
	local instanceData = instanceTracker[player.UserId]
	if badgeId and instanceData and not instanceData[badgeId] then
		awardBadge(player.UserId, badgeId)
	end
end

return BadgeHandler