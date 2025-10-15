-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local Relics = require(SharedUtility.Relics)
local GetHighestPower = require(SharedUtility.GetHighestPower)

local HighestPowerModule = {}

local instanceTracker = {}

function HighestPowerModule.onPlayerAdded(player: Player, relicInventory:{ any })
	HighestPowerModule.setHighest(player, HighestPowerModule.getHighestInInventory(relicInventory))
end

function HighestPowerModule.onPlayerRemoving(player: Player)
	instanceTracker[player.UserId] = nil
end

--[[
	Return the highest power that is currently being tracked by the player
]]
function HighestPowerModule.getHighest(player: Player)
	return instanceTracker[player.UserId]
end

--[[
	Return the highest power that is currently in the player's relic inventory,
	returning the highest power and the amplified list
]]
function HighestPowerModule.getHighestInInventory(relicInventory)
	return GetHighestPower(relicInventory)
end

function HighestPowerModule.updateRelicData(player, relicInventory)
	local powerChange = 0
	-- Get the highest power and amplified list
	local highestPower, amplifiedList = HighestPowerModule.getHighestInInventory(relicInventory)

	HighestPowerModule.setHighest(player, highestPower)
		
	for _, relicId in pairs(amplifiedList) do
		local relicData = relicInventory[relicId]
			
		local currentTypeValue = relicData["TypeValue"]
		local updatedValue = math.floor(Relics.getRelicsValue(relicData.Name) * highestPower)
		local difference = updatedValue - currentTypeValue

		relicData["TypeValue"] = updatedValue
			
		if relicData["Equipped"] == 1 then
			powerChange += difference
		end
	end

	return powerChange
end

function HighestPowerModule.setHighest(player: Player, highest: number)
	instanceTracker[player.UserId] = highest
end

return HighestPowerModule