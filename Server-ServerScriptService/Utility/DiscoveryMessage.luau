-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = script.Parent
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local Colors = require(HelperModules.Colors)
local Rarities = require(SharedUtility.Rarities)
local Constants = require(Utility.Constants)

local DiscoveryMessage = {}

function DiscoveryMessage.materialMessage(player, rarity, item)
	local rarityString = Rarities.getRarity(rarity)
	local hexColor = Colors.getHexColor(rarityString)
	
	return string.format(Constants.DISCOVERY_MESSAGE_STRING_FORMAT, player, hexColor, rarityString, item)
end

function DiscoveryMessage.relicMessage(player, relic)
	local hexColor = Colors.getHexColor("Legendary")
	
	return string.format(Constants.DISCOVERY_MESSAGE_RELIC_STRING_FORMAT, player, hexColor, relic)
end

return DiscoveryMessage