-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local DailyLootChestData = require(SharedUtility.DailyLootChestData)

local RarityGeneration = {}

-- Objects
local RNG = Random.new()

--[[
	Determine the rarity that the rarityPercent falls into based on a provided list of luckValues
]]
local function GenerateRarity(rarityPercent, dropRates)
	local selectIndex = 1
	local partitionOffset = 0
	
	for index, value in pairs(dropRates) do
		partitionOffset += value
		if rarityPercent <= partitionOffset then
			selectIndex = index
			break
		end
		index += 1
	end

	return selectIndex
end

function RarityGeneration(unlockedLocations, count)
	local dropRates = DailyLootChestData.getMaterialDropRateData(unlockedLocations)
	
	-- Create the skeleton table
	local list = {}
	for index, dropRate in pairs(dropRates) do
		list[index] = 0
	end
	
	while count > 0 do
		local rarityPercent = RNG:NextNumber(0, 100)
		local index = GenerateRarity(rarityPercent, dropRates)
		list[index] += 1
		
		count -= 1
	end
	
	return list
end

return RarityGeneration