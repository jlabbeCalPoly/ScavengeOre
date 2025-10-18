-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local BadgeHandler = require(script.Parent.BadgeHandler)
local HelperModules = ReplicatedStorage.HelperModules
local Utility = HelperModules.Utility
local ServerUtility = ServerScriptService.Utility
local SharedUtility = HelperModules.SharedUtility

-- Modules
local ConvertToNumAbbr = require(Utility.ConvertToNumAbbr)
local ServerConstants = require(ServerUtility.Constants)
local ShopData = require(SharedUtility.ShopData)
local ToolData = require(SharedUtility.ToolData)

local MarketplaceHandler = {}

function MarketplaceHandler.WadOfCashCallback(player: Player, Sell: RemoteEvent, PlayerDataHandler, LeaderstatsHandler)
	local playerData = PlayerDataHandler.getData(player.UserId)

	local cashChange = ShopData.calculateCash("WadOfCash", playerData["LevelStats"]["UnlockedLocations"])
	local remainingCash = PlayerDataHandler.offsetData(player.UserId, {"Inventory", "Cash"}, cashChange)
	LeaderstatsHandler.updateCash(player, remainingCash)

	Sell:FireClient(
		player, 
		nil, 
		string.format(ServerConstants.CASH_ADDED_STRING_FORMAT, ConvertToNumAbbr(cashChange, "Cash")),
		true,
		remainingCash,
		cashChange
	)
end

function MarketplaceHandler.BagOfCashCallback(player: Player, Sell: RemoteEvent, PlayerDataHandler, LeaderstatsHandler)
	local playerData = PlayerDataHandler.getData(player.UserId)

	local cashChange = ShopData.calculateCash("BagOfCash", playerData["LevelStats"]["UnlockedLocations"])
	local remainingCash = PlayerDataHandler.offsetData(player.UserId, {"Inventory", "Cash"}, cashChange)
	LeaderstatsHandler.updateCash(player, remainingCash)

	Sell:FireClient(
		player, 
		nil, 
		string.format(ServerConstants.CASH_ADDED_STRING_FORMAT, ConvertToNumAbbr(cashChange, "Cash")),
		true,
		remainingCash,
		cashChange
	)
end

function MarketplaceHandler.VaultOfCashCallback(player: Player, Sell: RemoteEvent, PlayerDataHandler, LeaderstatsHandler)
	local playerData = PlayerDataHandler.getData(player.UserId)

	local cashChange = ShopData.calculateCash("VaultOfCash", playerData["LevelStats"]["UnlockedLocations"])
	local remainingCash = PlayerDataHandler.offsetData(player.UserId, {"Inventory", "Cash"}, cashChange)
	LeaderstatsHandler.updateCash(player, remainingCash)

	Sell:FireClient(
		player, 
		nil, 
		string.format(ServerConstants.CASH_ADDED_STRING_FORMAT, ConvertToNumAbbr(cashChange, "Cash")),
		true,
		remainingCash,
		cashChange
	)
end

function MarketplaceHandler.ToolBundleCallback(player: Player, 
	Material: RemoteEvent,
	Upgrade: RemoteEvent,
	Stats: RemoteEvent,
	MaterialHandler,
	PlayerDataHandler,
	ToolHandler,
	DailyDataHandler
)
	local playerData = PlayerDataHandler.getData(player.UserId)
	local unlockedLocations = playerData["LevelStats"]["UnlockedLocations"]
	
	local toolLevel, rarityList = unpack(ShopData.getBundleData(unlockedLocations, "Tool"))
	local materialList, count = MaterialHandler.generatePaidMaterialList(rarityList, unlockedLocations)
	
	PlayerDataHandler.setData(player.UserId, {"LevelStats", "Tool"}, toolLevel)
	PlayerDataHandler.setData(player.UserId, {"MainStats", "Luck"}, ToolData.getData(toolLevel).Value)
	PlayerDataHandler.offsetData(player.UserId, {"Materials"}, count)
	playerData["Inventory"]["Materials"], materialList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Materials"], materialList, "Name")
	
	ToolHandler.setTool(player, toolLevel)
	
	Material:FireClient(player, materialList)
	Upgrade:FireClient(player, nil, 'Successfully purchased "Tool Bundle"!', true, "Tool", toolLevel)
	Stats:FireClient(player, playerData["MainStats"])
	
	local taskKeys = {
		["M"] = true,
		["Ra"] = true
	}
	DailyDataHandler.updateTaskData(playerData, materialList, taskKeys)
	
	return materialList
end

function MarketplaceHandler.RelicBundleCallback(player: Player,
	Claim: RemoteEvent,
	MaterialHandler,
	RelicHandler,
	PlayerDataHandler,
	DailyDataHandler
)
	local playerData = PlayerDataHandler.getData(player.UserId)
	local unlockedLocations = playerData["LevelStats"]["UnlockedLocations"]

	local relic, rarityList = unpack(ShopData.getBundleData(unlockedLocations, "Relic"))
	local materialList, count = MaterialHandler.generatePaidMaterialList(rarityList, unlockedLocations)
	
	local relicList = RelicHandler.generateRelicData(relic)
	playerData["Inventory"]["Relics"], relicList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Relics"], relicList, "Id")
	
	PlayerDataHandler.offsetData(player.UserId, {"Materials"}, count)
	playerData["Inventory"]["Materials"], materialList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Materials"], materialList, "Name")
	
	Claim:FireClient(
		player,
		nil, 
		'Successfully purchased "Relic Bundle"!',
		true,
		"Bundle",
		nil,
		relicList,
		materialList
	)
	
	local taskKeys = {
		["M"] = true,
		["Ra"] = true
	}
	DailyDataHandler.updateTaskData(playerData, materialList, taskKeys)
	
	BadgeHandler.addRelicBadge(player, relic)
	
	return playerData, materialList, relicList
end

function MarketplaceHandler.RelicEquipSlotCallback(player: Player, Upgrade: RemoteEvent, PlayerDataHandler)
	local playerData = PlayerDataHandler.getData(player.UserId)
	local unlockedSlots = playerData["LevelStats"]["UnlockedSlots"]
	
	if unlockedSlots < 10 then
		unlockedSlots += 1
		PlayerDataHandler.setData(player.UserId, {"LevelStats", "UnlockedSlots"}, unlockedSlots)
		Upgrade:FireClient(player, nil, 'Successfully purchased "+1 Relic Equip Slots"!', true, "Equip", unlockedSlots)
	else
		Upgrade:FireClient(player, nil, 'Unable to purchase additional relic equip slots', false)
	end
end

function MarketplaceHandler.HarvestPerkCallback(player: Player, Perk: RemoteEvent, PlayerDataHandler, perk: number)
	local playerData = PlayerDataHandler.getData(player.UserId)
	local harvestPerks = playerData["HarvestPerks"]
	
	harvestPerks[perk] = false
	local perkValue = ShopData.getHarvestData(perk)
	Perk:FireClient(player, string.format('Successfully purchased "x%d Materials"!', perkValue + 1), true, harvestPerks)
end

function MarketplaceHandler.GuaranteedUltraRareCallback(player: Player, PlayerDataHandler, Notification: RemoteEvent)
	local playerData = PlayerDataHandler.getData(player.UserId)
	playerData["GuaranteedUltraRare"] += 1
	
	Notification:FireClient(player, 'Successfully activated "4x Luck!" on your next swing!', true)
end

return MarketplaceHandler