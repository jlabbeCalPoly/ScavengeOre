-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local DailyLootChestData = require(SharedUtility.DailyLootChestData)
local ShopData = require(SharedUtility.ShopData)

-- Objects
local RNG = Random.new()

function RelicGeneration(unlockedLocations, grant: boolean?)
	if grant or RNG:NextNumber(0, 100) < DailyLootChestData.getRelicDropRateData()[1][2] then
		return ShopData.getBundleData(unlockedLocations, "Relic")[1], 1
	else
		return nil, 0
	end
end

return RelicGeneration