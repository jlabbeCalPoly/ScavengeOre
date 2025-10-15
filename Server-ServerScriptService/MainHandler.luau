-- General handler for all the backend functionality. Handles all remote events and
-- passes information down to the appropriate handlers

-- Services
local ServerScriptService = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Folders
local Handlers = ServerScriptService.Handlers
local Utility = ServerScriptService.Utility
local Remotes = ReplicatedStorage.Remotes
local SharedUtility = ReplicatedStorage.HelperModules.SharedUtility

-- Helper Modules
local MaterialHandler = require(Handlers.MaterialHandler)
local RelicHandler = require(Handlers.RelicHandler)
local PlayerDataHandler = require(Handlers.PlayerDataHandler)
local MarketplaceHandler = require(Handlers.MarketplaceHandler)
local SellHandler = require(Handlers.SellHandler)
local UpgradeHandler = require(Handlers.UpgradeHandler)
local TutorialHandler = require(Handlers.TutorialHandler)
local ToolHandler = require(Handlers.ToolHandler)
local PowerLabelHandler = require(Handlers.PowerLabelHandler)
local LeaderstatsHandler = require(Handlers.LeaderstatsHandler)
local LeaderboardHandler = require(Handlers.LeaderboardHandler)
local SettingsHandler = require(Handlers.SettingsHandler)
local VFXHandler = require(Handlers.VFXHandler)
local TeleportHandler = require(Handlers.TeleportHandler)
local BadgeHandler = require(Handlers.BadgeHandler)
local ClaimHandler = require(Handlers.ClaimHandler)
local ExploitHandler = require(Handlers.ExploitHandler)
local LockHandler = require(Handlers.LockHandler)
local SwingHandler = require(Handlers.SwingHandler)
local HighestPowerModule = require(Handlers.HighestPowerModule)
local DailyDataHandler = require(Handlers.DailyDataHandler)

-- Utility Modules
local Constants = require(Utility.Constants)
local DiscoveryMessage = require(Utility.DiscoveryMessage)
local StorageData = require(SharedUtility.StorageData)
local ShopData = require(SharedUtility.ShopData)

-- Remotes
local Material = Remotes.Material
local Lock = Remotes.Lock
local Relic = Remotes.Relic
local AmplifiedRelic = Remotes.AmplifiedRelic
local Sell = Remotes.Sell
local SellAll = Remotes.SellAll
local Equip = Remotes.Equip
local Tutorial = Remotes.Tutorial
local Chat = Remotes.Chat
local VFX = Remotes.VFX
local Notification = Remotes.Notification
local Stats = Remotes.Stats
local Upgrade = Remotes.Upgrade
local Perk = Remotes.Perk
local Settings = Remotes.Settings
local GetData = Remotes.GetData
local Claim = Remotes.Claim

local function checkMaterialBadge(player, materialList)
	local discovered = 0
	
	--[[
		Our material list should already be sorted in descending order, so 
		simply check if the preceding rarity ~= the previously discovered rarity and award badges accordingly
	]]
	for _, data in pairs(materialList) do
		if data.Rarity > 2 and data.Rarity ~= discovered then
			discovered = data.Rarity
			task.spawn(function()
				BadgeHandler.addRarityBadge(player, discovered)
			end)
		end
	end
end

--[[
	CONNECTIONS FOR REMOTE EVENTS
]]

-- Handle material validation/creation
Material.OnServerEvent:Connect(function(player: Player,
										timeStamp: number,
										entity: Model)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end								
									
	if not MaterialHandler.validateTypes(player, timeStamp, entity) then
		return
	end
	
	local playerData = PlayerDataHandler.getData(player.UserId)
	if playerData == nil then
		return
	end
	
	-- Validate the speed of the mine
	if not SwingHandler.onRemoteReceived(player, timeStamp, playerData["MainStats"]["Speed"]) then
		return
	end
	
	local unlockedLocations = playerData["LevelStats"]["UnlockedLocations"]
	local entityName = string.sub(entity.Name, 1, string.len(entity.Name) - 2)
	if not MaterialHandler.validateArguments(timeStamp, entityName, unlockedLocations) then
		return
	end
	
	local entityLocation = MaterialHandler.getEntityLocation(entityName)
	local luck = playerData["MainStats"]["Luck"]
	
	local currentStorage = playerData["Materials"]
	local maxStorage = StorageData.getData(playerData["LevelStats"]["Storage"]).Value

	local generateCount = 1
	for harvestPerk, value in pairs(playerData["HarvestPerks"]) do
		if not value then
			generateCount += ShopData.getHarvestData(harvestPerk)
		end
	end
	
	local count = math.min(math.clamp(maxStorage - currentStorage, 0, maxStorage), generateCount)
	
	-- Check if the player has not completed the tutorial yet (only generate Mossrock Ore or Hollow Gem)
	local materialList, breaks
	if not playerData["Tutorial"][1] and playerData["Tutorial"][2] < 5 then
		materialList, breaks = MaterialHandler.generateTutorialMaterialList(count, playerData["Breaks"])
	else
		local guaranteedUltraRare = playerData["GuaranteedUltraRare"]
		materialList, breaks = MaterialHandler.generateMaterialList(entityName, luck, {entityLocation}, count, guaranteedUltraRare, playerData["Breaks"])
		
		playerData["GuaranteedUltraRare"] = math.clamp((guaranteedUltraRare - count), 0, math.huge)
	end
	
	if #materialList > 0 and materialList[1].Rarity >= 5 then
		local message = DiscoveryMessage.materialMessage(player.DisplayName, materialList[1].Rarity, materialList[1].Name)
		Chat:FireAllClients(message)
	end
	
	playerData["Inventory"]["Materials"], materialList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Materials"], materialList, "Name")
	
	PlayerDataHandler.offsetData(player.UserId, {"Materials"}, count)
	if breaks then
		PlayerDataHandler.setData(player.UserId, {"Breaks"}, breaks)
	end
	
	Material:FireClient(player, materialList, entity, breaks)
	
	checkMaterialBadge(player, materialList)
	
	local taskKeys = {
		["M"] = true,
		["Ra"] = true
	}
	DailyDataHandler.updateTaskData(playerData, materialList, taskKeys)
end)
									
	
Lock.OnServerEvent:Connect(function(player: Player, timeStamp: number, material: string, action: string)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		
	
	local function lockFailure()
		Lock:FireClient(
			player, 
			timeStamp, 
			string.format(Constants.NOTIFICATION_ERROR, " while locking")
		)
	end
	
	if not LockHandler.validateTypes(player, timeStamp, material, action) then
		lockFailure()
		return
	end
	
	local playerData = PlayerDataHandler.getData(player.UserId)
	if playerData == nil then
		lockFailure()
		return
	end
	
	-- Validates the arguments, also sets the "Lock" value appropriately for the given material if checks pass
	local success, isLocked = LockHandler.validateArguments(timeStamp, material, action, playerData["Inventory"]["Materials"])
	if not success then
		lockFailure()
		return
	end
	
	Lock:FireClient(
		player, 
		timeStamp, 
		string.format(Constants.NOTIFICATION_SUCCESS_SIMPLE, string.lower(action).."ed", material), 
		true,
		material,
		isLocked
	)
end)

-- Handle relic validation/creation
Relic.OnServerEvent:Connect(function(player: Player,
									 timeStamp: number,
									 relic: string
)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		
	
	local function craftFailure()
		Relic:FireClient(
			player, 
			timeStamp, 
			string.format(Constants.NOTIFICATION_ERROR, " while crafting"),
			false
		)
	end
	
	if not RelicHandler.validateTypes(player, timeStamp, relic) then
		craftFailure()
		return
	end
	
	local playerData = PlayerDataHandler.getData(player.UserId)
	if playerData == nil then
		craftFailure()
		return
	end
	
	-- First, check if the player is holding more than the max amount of relics (30+)
	local rCount = 0;
	for key, value in pairs(playerData["Inventory"]["Relics"]) do
		rCount += 1
	end
	if rCount > 29 then
		Relic:FireClient(
			player, 
			timeStamp, 
			"Cannot craft, relic inventory exceeds 30 relics",
			false
		)
		return
	end
	
	if not RelicHandler.validateArguments(timeStamp, relic) then
		craftFailure()
		return
	end
	
	local satisfied, craftCost, count = RelicHandler.validateCraft(relic, playerData["Inventory"]["Materials"])
	if not satisfied then
		craftFailure()
		return
	end
	
	local currentHighest = HighestPowerModule.getHighest(player)
	
	-- Remove the corresponding material from the player's inventory
	playerData["Inventory"]["Materials"], craftCost = PlayerDataHandler.updateInventory(playerData["Inventory"]["Materials"], craftCost, "Name")
	PlayerDataHandler.offsetData(player.UserId, {"Materials"}, count)
	
	local relicList = RelicHandler.generateRelicData(relic)
	playerData["Inventory"]["Relics"], relicList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Relics"], relicList, "Id")
	
	local powerChange = 0
	local relicData = relicList[1]

	if relicData.TypeValue > currentHighest then
		powerChange += HighestPowerModule.updateRelicData(player, playerData["Inventory"]["Relics"])
	end

	if powerChange ~= 0 then
		PlayerDataHandler.offsetData(player.UserId, {"MainStats", relicData.Type}, powerChange)
		LeaderstatsHandler.updatePower(player, powerChange)
		PowerLabelHandler.updateLabel(player, playerData["MainStats"][relicData.Type])
		Stats:FireClient(player, playerData["MainStats"])
	end
	
	Relic:FireClient(
		player, 
		timeStamp, 
		string.format(Constants.NOTIFICATION_SUCCESS_SIMPLE, "crafted", relic), 
		true, 
		relicList
	)
	Material:FireClient(player, craftCost)
	
	BadgeHandler.addRelicBadge(player, relic)
	
	local taskKeys = {
		["Re"] = true
	}
	DailyDataHandler.updateTaskData(playerData, relicList, taskKeys)
end)

AmplifiedRelic.OnServerEvent:Connect(function(player: Player,
											  timeStamp: number,
											  relic: string)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		

	local function craftFailure()
		Relic:FireClient(
			player, 
			timeStamp, 
			string.format(Constants.NOTIFICATION_ERROR, " while crafting"),
			false
		)
	end

	if not RelicHandler.validateTypes(player, timeStamp, relic) then
		craftFailure()
		return
	end

	local playerData = PlayerDataHandler.getData(player.UserId)
	if playerData == nil then
		craftFailure()
		return
	end
	
	-- First, check if the player is holding more than the max amount of relics (30+)
	local rCount = 0;
	for key, value in pairs(playerData["Inventory"]["Relics"]) do
		rCount += 1
	end
	if rCount > 29 then
		Relic:FireClient(
			player, 
			timeStamp, 
			"Cannot craft, relic inventory exceeds 30 relics",
			false
		)
		return
	end

	if not RelicHandler.validateArguments(timeStamp, relic) then
		craftFailure()
		return
	end
	
	local satisfied, amplifedVoucherCost = RelicHandler.validateAmplifiedCraft(relic, playerData["Inventory"]["Amplified Voucher"])
	if not satisfied then
		craftFailure()
		return
	end
	playerData["Inventory"]["Amplified Voucher"] -= amplifedVoucherCost
	
	local highestPower = HighestPowerModule.getHighest(player)
	local relicList = RelicHandler.generateRelicData(relic, highestPower)
	playerData["Inventory"]["Relics"], relicList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Relics"], relicList, "Id")
	
	AmplifiedRelic:FireClient(
		player, 
		timeStamp, 
		string.format(Constants.NOTIFICATION_SUCCESS_SIMPLE, "crafted", relic), 
		true, 
		relicList,
		playerData["Inventory"]["Amplified Voucher"]
	)
end)

Equip.OnServerEvent:Connect(function(player: Player,
									 timeStamp: number,
								     relic: string,
								     action: string
)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		
	
	local function equipFailure()
		Equip:FireClient(
			player, 
			timeStamp, 
			string.format(Constants.NOTIFICATION_ERROR, " while equipping"),
			false
		)
	end
	
	if not RelicHandler.validateEquipTypes(player, timeStamp, relic, action) then
		equipFailure()
		return
	end
	
	local userId = player.UserId
	local playerData = PlayerDataHandler.getData(userId)
	if playerData == nil then
		equipFailure()
		return
	end
	
	local relicInventory = playerData["Inventory"]["Relics"]
	local equipped = playerData["Relics"]
	local maxEquipped = playerData["LevelStats"]["UnlockedSlots"]
	
	if not RelicHandler.validateEquipArguments(timeStamp, relic, action, relicInventory, equipped, maxEquipped) then
		equipFailure()
		return
	end
	
	local relicData = playerData["Inventory"]["Relics"][relic]
	local typeValue
	local equipped
	local change
	local stringInsert
	local func
	if action == "Equip" then
		equipped = 1
		change = 1
		stringInsert = "equipped"
		typeValue = relicData.TypeValue
		func = RelicHandler.addRelicMeshes
	else
		equipped = 0
		change = -1
		stringInsert = "unequipped"
		typeValue = -relicData.TypeValue
		func = RelicHandler.removeRelicMeshes
	end
	
	local relicList = {}
	relicList[relic] = relicData.Name
	
	PlayerDataHandler.setData(userId, {"Inventory", "Relics", relic, "Equipped"}, equipped)
	PlayerDataHandler.offsetData(userId, {"Relics"}, change)
	PlayerDataHandler.offsetData(userId, {"MainStats", relicData.Type}, typeValue)
	func(player, relicList, playerData["Relics"])
	LeaderstatsHandler.updatePower(player, typeValue)

	Equip:FireClient(
		player, 
		timeStamp, 
		string.format(Constants.NOTIFICATION_SUCCESS_SIMPLE, stringInsert, relicInventory[relic].Name), 
		true, 
		relic,
		equipped, 
		playerData["Relics"]
	)
	Stats:FireClient(player, playerData["MainStats"])
	PowerLabelHandler.updateLabel(player, playerData["MainStats"][relicData.Type])
end)

Sell.OnServerEvent:Connect(function(player: Player,
									timeStamp: number,
									item: string,
									itemType: string,
									quantity: number
)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		
	
	local function sellFailure()
		Sell:FireClient(
			player, 
			timeStamp, 
			string.format(Constants.NOTIFICATION_ERROR, " while selling"),
			false
		)
	end
	
	if not SellHandler.validateTypes(player, timeStamp, item, itemType, quantity) then
		sellFailure()
		return
	end
	
	local userId = player.UserId
	local playerData = PlayerDataHandler.getData(userId)
	if playerData == nil then
		sellFailure()
		return
	end
	
	if not SellHandler.validateArguments(timeStamp, item, itemType, quantity, playerData) then
		sellFailure()
		return
	end

	if itemType == "Materials" then
		local materialList = MaterialHandler.createMaterialList({{item, -quantity}})
		playerData["Inventory"]["Materials"], materialList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Materials"], materialList, "Name")
		PlayerDataHandler.offsetData(player.UserId, {"Materials"}, -quantity)

		Material:FireClient(player, materialList)
	else
		local relicData = playerData["Inventory"]["Relics"][item]
		local itemValue = relicData.Value
		local itemType = relicData.Type
		local itemTypeValue = relicData.TypeValue
		local isAmplified = relicData["Amplified"] == "Amplified"
		
		local relicList = RelicHandler.createRelicList({{item, relicData.Name, -quantity}})
		playerData["Inventory"]["Relics"], relicList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Relics"], relicList, "Id")
		
		local powerChange = 0
		local capacityChange
		-- Check if the relic is currently equipped
		if relicData.Equipped == 1 then
			powerChange -= relicData.TypeValue
			PlayerDataHandler.offsetData(userId, {"Relics"}, -quantity)
			
			capacityChange = playerData["Relics"]
			
			local list = {}
			list[item] = relicData.Name
			RelicHandler.removeRelicMeshes(player, list, capacityChange)
		end

		Relic:FireClient(player, nil, nil, true, relicList, capacityChange)
		PlayerDataHandler.setData(userId, {"Inventory", "Relics", item}, nil)

		-- If the relic isn't Amplified, check to see if it's greater than/equal to the highestpower
		if not isAmplified then
			if itemTypeValue >= HighestPowerModule.getHighest(player) then
				powerChange += HighestPowerModule.updateRelicData(player, playerData["Inventory"]["Relics"])
			end
		end
		
		if powerChange ~= 0 then
			PlayerDataHandler.offsetData(userId, {"MainStats", itemType}, powerChange)
			LeaderstatsHandler.updatePower(player, powerChange)
			PowerLabelHandler.updateLabel(player, playerData["MainStats"][itemType])
			Stats:FireClient(player, playerData["MainStats"])
		end
		
		item = itemValue
	end
	
	local cashChange, message = SellHandler.getSellDetails(item, itemType, quantity)
	local remainingCash = PlayerDataHandler.offsetData(player.UserId, {"Inventory", "Cash"}, cashChange)
	LeaderstatsHandler.updateCash(player, remainingCash)

	Sell:FireClient(
		player, 
		timeStamp, 
		string.format(Constants.CASH_ADDED_STRING_FORMAT, message),
		true,
		remainingCash,
		cashChange
	)
end)

SellAll.OnServerEvent:Connect(function(player: Player, timeStamp: number)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		

	local function sellAllFailure()
		SellAll:FireClient(
			player, 
			timeStamp, 
			string.format(Constants.NOTIFICATION_ERROR, " while selling all"),
			false
		)
	end
	
	if not SellHandler.validateTypesSellAll(player, timeStamp) then
		sellAllFailure()
		return
	end
	
	local playerData = PlayerDataHandler.getData(player.UserId)
	if playerData == nil then
		sellAllFailure()
		return
	end
	
	if not SellHandler.validateArgumentsSellAll(timeStamp) then
		sellAllFailure()
		return
	end
	
	local sellList, cashChange, count, message = SellHandler.getSellAllDetails(playerData["Inventory"]["Materials"])
	
	local materialList = MaterialHandler.createMaterialList(sellList)
	playerData["Inventory"]["Materials"], materialList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Materials"], materialList, "Name")
	PlayerDataHandler.offsetData(player.UserId, {"Materials"}, -count)

	Material:FireClient(player, materialList)
	
	local remainingCash = PlayerDataHandler.offsetData(player.UserId, {"Inventory", "Cash"}, cashChange)
	LeaderstatsHandler.updateCash(player, remainingCash)
	
	SellAll:FireClient(
		player,
		timeStamp,
		string.format(Constants.CASH_ADDED_STRING_FORMAT, message),
		true,
		remainingCash,
		cashChange
	)
end)

Upgrade.OnServerEvent:Connect(function(player, timeStamp, upgradeType, nextLevel)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		
	
	local function upgradeFailure()
		Upgrade:FireClient(
			player, 
			timeStamp, 
			string.format(Constants.NOTIFICATION_ERROR, " while upgrading"),
			false
		)
	end
	
	if not UpgradeHandler.validateTypes(player, timeStamp, upgradeType, nextLevel) then
		upgradeFailure()
		return
	end
	
	local userId = player.UserId
	local playerData = PlayerDataHandler.getData(userId)
	if playerData == nil then
		upgradeFailure()
		return
	end
	
	local success, upgradeCost, count = UpgradeHandler.validateArguments(timeStamp, upgradeType, nextLevel, playerData)
	if not success then
		upgradeFailure()
		return
	end
	
	local message
	if upgradeType == "Storage" then
		local cashCost = upgradeCost[1]
		local remainingCash = PlayerDataHandler.offsetData(player.UserId, {"Inventory", "Cash"}, -cashCost[2])
		PlayerDataHandler.setData(player.UserId, {"LevelStats", "Storage"}, nextLevel)
		LeaderstatsHandler.updateCash(player, remainingCash)
		
		message = string.format("Successfully upgraded %s to level %s!", string.lower(upgradeType), nextLevel)
		Upgrade:FireClient(player, timeStamp, message, true, upgradeType, nextLevel, {remainingCash, -cashCost[2]})
	elseif upgradeType == "Tool" then
		-- Remove the corresponding material from the player's inventory
		playerData["Inventory"]["Materials"], upgradeCost = PlayerDataHandler.updateInventory(playerData["Inventory"]["Materials"], upgradeCost, "Name")
		PlayerDataHandler.offsetData(player.UserId, {"Materials"}, count)
		PlayerDataHandler.setData(player.UserId, {"LevelStats", "Tool"}, nextLevel)
		
		ToolHandler.setTool(player, nextLevel)
		
		message = string.format("Successfully upgraded %s to level %s!", string.lower(upgradeType), nextLevel)
		Upgrade:FireClient(player, timeStamp, message, true, upgradeType, nextLevel, upgradeCost)
		Stats:FireClient(player, playerData["MainStats"])
	elseif upgradeType == "Location" then
		local cashCost = upgradeCost[1]
		local remainingCash = PlayerDataHandler.offsetData(player.UserId, {"Inventory", "Cash"}, -cashCost[2])
		PlayerDataHandler.setData(player.UserId, {"LevelStats", "UnlockedLocations"}, nextLevel)
		LeaderstatsHandler.updateCash(player, remainingCash)

		message = "Successfully unlocked the next location!"
		Upgrade:FireClient(player, timeStamp, message, true, upgradeType, nextLevel, {remainingCash, -cashCost[2]})
	elseif upgradeType == "Gate" then
		playerData["Inventory"]["Materials"], upgradeCost = PlayerDataHandler.updateInventory(playerData["Inventory"]["Materials"], upgradeCost, "Name")
		PlayerDataHandler.offsetData(player.UserId, {"Materials"}, count)
		
		message = "Successfully unlocked the gate"
		Upgrade:FireClient(player, timeStamp, message, true, upgradeType, nextLevel, upgradeCost)
	end	
end)

VFX.OnServerEvent:Connect(function(player: Player, instance)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		
	
	if not VFXHandler.validateTypes(player, instance) then
		return
	end
	
	if not VFXHandler.validateArguments(instance) then
		return
	end
	
	for _, p: Player in pairs(Players:GetChildren()) do
		if p.UserId ~= player.UserId then
			VFX:FireClient(p, instance, 0.4, "TestParticles")
		end
	end
end)

Settings.OnServerEvent:Connect(function(player, settingsList)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		
	
	if not SettingsHandler.validateInitialTypes(player, settingsList) then
		return
	end
	
	local playerData = PlayerDataHandler.getData(player.UserId)
	if playerData == nil then
		return
	end
	
	for _, settingDetails in pairs(settingsList) do
		local settingIndex, settingValue = unpack(settingDetails)
		if SettingsHandler.validateTypes(settingIndex, settingValue) and SettingsHandler.validateArguments(settingIndex) then
			playerData["Settings"][settingIndex][2] = settingValue
		end
	end
end)

Tutorial.OnServerEvent:Connect(function(player: Player, completed: boolan, step: boolean)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		
	
	if not TutorialHandler.validateTypes(player, completed, step) then
		return
	end
	
	local playerData = PlayerDataHandler.getData(player.UserId)
	if playerData == nil then
		return
	end
	
	if not TutorialHandler.validateArguments(completed, step, playerData["Tutorial"]) then
		return
	end
	
	playerData["Tutorial"][1] = completed
	if not completed then
		playerData["Tutorial"][2] = step
	else
		Tutorial:FireClient(player)
	end
end)

Claim.OnServerEvent:Connect(function(player: Player, timeStamp: number, claimType: string, taskNum: number)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		
	
	local function ClaimFailure(message)
		if not message then
			message = string.format(Constants.NOTIFICATION_ERROR, " while claiming")
		end
		Claim:FireClient(
			player, 
			timeStamp, 
			message,
			false
		)
	end
	
	-- Validate the general types for the claim
	if not ClaimHandler.validateTypes(player, timeStamp, claimType) then
		ClaimFailure()
		return
	end

	local playerData = PlayerDataHandler.getData(player.UserId)
	if playerData == nil then
		return
	end

	local success, errorMessage = ClaimHandler.validateArguments(timeStamp, claimType, taskNum, playerData)
	if not success then
		ClaimFailure(errorMessage)
		return
	end
	
	local currentHighest = HighestPowerModule.getHighest(player)
	
	local message = ""
	local relicList
	local materialList
	local cashData
	local amplifiedVoucherData
	
	if claimType == "Chest" then
		local count = 5
		local unlockedLocations = playerData["LevelStats"]["UnlockedLocations"]

		-- Check if the player will receive a relic or not
		local relic, relicCount = ClaimHandler.relicGeneration(unlockedLocations)

		if relic then
			relicList = RelicHandler.generateRelicData(relic)
			playerData["Inventory"]["Relics"], relicList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Relics"], relicList, "Id")
		end
		count -= relicCount

		-- Generate the materials the player will recieve
		local rarityList = ClaimHandler.rarityGeneration(unlockedLocations, count)
		materialList = MaterialHandler.generatePaidMaterialList(rarityList, unlockedLocations)

		PlayerDataHandler.offsetData(player.UserId, {"Materials"}, count)
		playerData["Inventory"]["Materials"], materialList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Materials"], materialList, "Name")

		local taskKeys = {
			["M"] = true,
			["Ra"] = true
		}
		DailyDataHandler.updateTaskData(playerData, materialList, taskKeys)
	else
		local indexedFunctions = {
			["Amplified Voucher"] = function(voucherChange)
				amplifiedVoucherData = PlayerDataHandler.offsetData(player.UserId, {"Inventory", "Amplified Voucher"}, voucherChange)
				LeaderstatsHandler.updateAmplifiedVouchers(player, amplifiedVoucherData)
			end,
			["Cash"] = function(cashChange)
				local remainingCash = PlayerDataHandler.offsetData(player.UserId, {"Inventory", "Cash"}, cashChange)
				cashData = {remainingCash, cashChange}
				LeaderstatsHandler.updateCash(player, remainingCash)
			end,
			["Guaranteed Ultra Rare"] = function(count)
				playerData["GuaranteedUltraRare"] += count
			end,
			["Material Pack"] = function(packId)
				local count = 0
				local location = playerData["LevelStats"]["UnlockedLocations"]
				
				local rarityOverride, rarityList = unpack(ClaimHandler.getMaterialPackData(packId, location))
				materialList, count = MaterialHandler.generatePaidMaterialList(rarityList, location, rarityOverride)

				PlayerDataHandler.offsetData(player.UserId, {"Materials"}, count)
				playerData["Inventory"]["Materials"], materialList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Materials"], materialList, "Name")

				local taskKeys = {
					["M"] = true,
					["Ra"] = true
				}
				DailyDataHandler.updateTaskData(playerData, materialList, taskKeys)
			end,
			["Special relic"] = function()
				local unlockedLocations = playerData["LevelStats"]["UnlockedLocations"]

				-- Pass the "Grant" flag to the relicGeneration function to generate a relic
				local relic = ClaimHandler.relicGeneration(unlockedLocations, true)
				
				relicList = RelicHandler.generateRelicData(relic)
				playerData["Inventory"]["Relics"], relicList = PlayerDataHandler.updateInventory(playerData["Inventory"]["Relics"], relicList, "Id")
			end
		}
		
		local rewards
		-- Determine the rewards to retrieve for the player
		if claimType == "Daily" then
			rewards = ClaimHandler.getDailyRewardData(taskNum, playerData["DailyData"]["Tasks"])
			message = string.format(`Successfully claimed x%d "Amplified Vouchers"!`, rewards["Amplified Voucher"])
		else
			local weeklyData = playerData["WeeklyData"]
			local day = weeklyData["Day"]
			rewards = ClaimHandler.getWeeklyRewardData(day, playerData["LevelStats"]["UnlockedLocations"])
			message = string.format(`Successfully claimed the rewards for Day %d!`, day)
			
			-- Update the day to the next value, then set taskNum to Days (so it can be passed to the client)
			weeklyData["Day"] = (day % 7) + 1
			taskNum = weeklyData["Day"]
		end
		
		for key, rewardDetails in pairs(rewards) do
			indexedFunctions[key](rewardDetails)
		end
	end
	
	Claim:FireClient(
		player, 
		timeStamp, 
		message, 
		true,
		claimType,
		taskNum,
		relicList,
		materialList,
		cashData,
		amplifiedVoucherData
	)

	if relicList then
		local powerChange = 0
		local relicData = relicList[1]

		if relicData.TypeValue > currentHighest then
			powerChange += HighestPowerModule.updateRelicData(player, playerData["Inventory"]["Relics"])
		end

		if powerChange ~= 0 then
			PlayerDataHandler.offsetData(player.UserId, {"MainStats", relicData.Type}, powerChange)
			LeaderstatsHandler.updatePower(player, powerChange)
			PowerLabelHandler.updateLabel(player, playerData["MainStats"][relicData.Type])
			Stats:FireClient(player, playerData["MainStats"])
		end
		
		local relicName = relicData.Name
		BadgeHandler.addRelicBadge(player, relicName)
		local message = DiscoveryMessage.relicMessage(player.DisplayName, relicName)
		Chat:FireAllClients(message)
	end
	
	if materialList then
		checkMaterialBadge(player, materialList)
		if #materialList > 0 and materialList[1].Rarity >= 5 then
			local message = DiscoveryMessage.materialMessage(player.DisplayName, materialList[1].Rarity, materialList[1].Name)
			Chat:FireAllClients(message)
		end
	end
end)

-- Process the purchase receipt
local function processReceipt(receiptInfo)
	local MarketplaceHandlers = {
		[3336695618] = function(player: Player)
			MarketplaceHandler.WadOfCashCallback(player, Sell, PlayerDataHandler, LeaderstatsHandler)
		end,
		[3336850561] = function(player: Player)
			MarketplaceHandler.BagOfCashCallback(player, Sell, PlayerDataHandler, LeaderstatsHandler)
		end,
		[3336859373] = function(player: Player)
			MarketplaceHandler.VaultOfCashCallback(player, Sell, PlayerDataHandler, LeaderstatsHandler)
		end,
		[3338092781] = function(player: Player)
			local materialList = MarketplaceHandler.ToolBundleCallback(player, Material, Upgrade, Stats, MaterialHandler, PlayerDataHandler, ToolHandler, DailyDataHandler)
			if #materialList > 0 and materialList[1].Rarity >= 5 then
				local message = DiscoveryMessage.materialMessage(player.DisplayName, materialList[1].Rarity, materialList[1].Name)
				Chat:FireAllClients(message)
			end
			
			checkMaterialBadge(player, materialList)
		end,
		[3338245452] = function(player: Player)
			local currentHighest = HighestPowerModule.getHighest(player)
			
			local playerData, materialList, relicList = MarketplaceHandler.RelicBundleCallback(player, Claim, MaterialHandler, RelicHandler, PlayerDataHandler, DailyDataHandler)
			
			local powerChange = 0
			local relicData = relicList[1]

			if relicData.TypeValue > currentHighest then
				powerChange += HighestPowerModule.updateRelicData(player, playerData["Inventory"]["Relics"])
			end

			if powerChange ~= 0 then
				PlayerDataHandler.offsetData(player.UserId, {"MainStats", relicData.Type}, powerChange)
				LeaderstatsHandler.updatePower(player, powerChange)
				PowerLabelHandler.updateLabel(player, playerData["MainStats"][relicData.Type])
				Stats:FireClient(player, playerData["MainStats"])
			end

			local relicName = relicData.Name
			
			local message = DiscoveryMessage.relicMessage(player.DisplayName, relicName)
			Chat:FireAllClients(message)
			
			BadgeHandler.addRelicBadge(player, relicName)
			checkMaterialBadge(player, materialList)
		end,
		[3340370077] = function(player: Player)
			MarketplaceHandler.RelicEquipSlotCallback(player, Upgrade, PlayerDataHandler)
		end,
		[3376915874] = function(player: Player)
			MarketplaceHandler.HarvestPerkCallback(player, Perk, PlayerDataHandler, 1)
		end,
		[3376919698] = function(player: Player)
			MarketplaceHandler.HarvestPerkCallback(player, Perk, PlayerDataHandler, 2)
		end,
		[3376923137] = function(player: Player)
			MarketplaceHandler.HarvestPerkCallback(player, Perk, PlayerDataHandler, 3)
		end,
		[3392885348] = function(player: Player)
			MarketplaceHandler.GuaranteedUltraRareCallback(player, PlayerDataHandler, Notification)
		end,
	}
	
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	local handler = MarketplaceHandlers[receiptInfo.ProductId]
	if player and handler then
		handler(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end
MarketplaceService.ProcessReceipt = processReceipt
								
-- Handle initial data transfer to the client
GetData.OnServerEvent:Connect(function(player: Player)
	if not ExploitHandler.onRemoteReceived(player) then
		return
	end		
	
	GetData:FireClient(player, PlayerDataHandler.getData(player.UserId))
end)

-- Handle player data setup/retrieval
Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Once(function(character: Model)
		local success, hrp = PlayerDataHandler.onPlayerAdded(player)
		if success then
			PlayerDataHandler.setCollisionGroup(character)

			local playerData = PlayerDataHandler.getData(player.UserId)
			
			--for id, data in pairs(playerData["Inventory"]["Relics"]) do
			--	if data.Quantity == 0 then
			--		playerData["Inventory"]["Relics"][id] = nil
			--	end
			--end
			
			ExploitHandler.onPlayerAdded(player)
			SwingHandler.onPlayerAdded(player)
			RelicHandler.onPlayerAdded(player, playerData)
			ToolHandler.onPlayerAdded(player, playerData["LevelStats"]["Tool"])

			TeleportHandler.teleport(hrp, playerData["LevelStats"]["UnlockedLocations"])

			HighestPowerModule.onPlayerAdded(player, playerData["Inventory"]["Relics"])
			PowerLabelHandler.onPlayerAdded(player, playerData["MainStats"]["Power"])
			LeaderstatsHandler.onPlayerAdded(player, playerData["Inventory"]["Cash"], playerData["Inventory"]["Amplified Voucher"], playerData["MainStats"]["Power"])
			BadgeHandler.onPlayerAdded(player)
		end
	end)
end)

-- Handle saving player data when disconnecting
Players.PlayerRemoving:Connect(function(player: Player)
	local userId = player.UserId
	local playerData = PlayerDataHandler.getData(userId)
	if playerData then
		local success, cash, power = PlayerDataHandler.onPlayerLeaving(userId)
		if success then
			LeaderboardHandler.onPlayerLeaving(userId, cash, power)
		end
	end

	ExploitHandler.onPlayerLeaving(player)
	SwingHandler.onPlayerLeaving(player)
	RelicHandler.onPlayerRemoving(player)
	ToolHandler.onPlayerRemoving(player)
	PowerLabelHandler.onPlayerRemoving(player)
	HighestPowerModule.onPlayerRemoving(player)
	LeaderstatsHandler.onPlayerRemoving(player)
	BadgeHandler.onPlayerRemoving(player)
end)

--[[
	The following function is taken directly from Roblox's documentation for BindToClose() code sample, with small adjustments
	Required in the event the server shuts down/resets
]]
game:BindToClose(function(closeReason)
	if RunService:IsStudio() then
		return
	end
	
	-- Reference for yielding and resuming later
	local mainThread = coroutine.running()

	-- Counts up for each new thread, down when the thread finishes. When 0 is reached,
	-- the individual thread knows it's the last thread to finish and should resume the main thread
	local numThreadsRunning = 0
	
	-- Calling this function later starts on a new thread because of coroutine.wrap
	local startSaveThread = coroutine.wrap(function(userId, playerData, delaySpacer)
		task.wait(0.4 * delaySpacer)
		-- Perform the save operation
		local success, cash, power = PlayerDataHandler.onPlayerLeaving(userId)
		if success then
			LeaderboardHandler.onPlayerLeaving(userId, cash, power)
		end

		-- Thread finished, decrement counter
		numThreadsRunning -= 1

		if numThreadsRunning == 0 then
			-- This was the last thread to finish, resume main thread
			coroutine.resume(mainThread)
		end
	end)
	
	local delaySpacer = 1
	for userId, playerData in pairs(PlayerDataHandler.getAllOutstandingData()) do
		numThreadsRunning += 1
		startSaveThread(userId, playerData, delaySpacer)
		delaySpacer += 1
	end
	
	if numThreadsRunning > 0 then
		-- Stall shutdown until save threads finish. Resumed by the last save thread when it finishes
		coroutine.yield()
	end

	if closeReason ~= Enum.CloseReason.ServerEmpty then
		warn(`Server shut down due to {closeReason}`)
	end
end)

--[[
	Manually set the data for a given player
]]
-- 3887161217
local function saveData()
	--[[
		"c4950635-e0ce-474e-94cb-4b45995e6710" {
        "Equipped": 0,
        "Name": "Sliced Blade",
        "Quantity": 1,
        "Type": "Power",
        "TypeValue": 8000,
        "Value": 20910000
      }
      ["c4950635-e0ce-474e-94cb-4b45995e6710"] = {
      	["Equipped"] = 0,
      	["Name"] = "Sliced Blade",
      	["Quantity"] = 1,
      	["Type"] = "Power",
      	["TypeValue"] = 8000,
      	["Value"] = 20910000
      }
      
      ["e4950634-e0ce-474e-94cb-4b45995e6710"] = {
					["Equipped"] = 0,
					["Name"] = "Sorcerer's Book",
					["Quantity"] = 1,
					["Type"] = "Power",
					["TypeValue"] = 400,
					["Value"] = 233300
				},
				["f4950633-e0ce-474e-94cb-4b45995e6710"] = {
					["Equipped"] = 0,
					["Name"] = "Infused Flower",
					["Quantity"] = 1,
					["Type"] = "Power",
					["TypeValue"] = 2000,
					["Value"] = 3710000
				},
	]]
	
	
	local data = {
		["Settings"] = {
			{"Auto-Swing", false}, 
			{"Music", true},
			{"SFX", true},
			{"Others' VFX", true},
			{"Notifications", true},
			{"Material Popup", true},
			{"Resource Log", true}
		},
		["MainStats"] = {
			["Power"] = 1,
			["Speed"] = 0.8,
			["Luck"] = 1
		},
		["LevelStats"] = {
			["Level"] = {			  -- Level, XP
				0,
				0
			},
			["Tool"] = 1,
			["Storage"] = 1,
			["UnlockedSlots"] = 5,        -- The number of equip slots for relics the player has unlocked
			["UnlockedLocations"] = 1,    -- The furthest location the player has unlocked
			["UnlockedEternalZones"] = {} -- The Eternal zones the player has unlocked. May either hold higher-tier entities or an Eternal Relic Crafter
		},
		["Inventory"] = {
			["Cash"] = 0,
			["Amplified Voucher"] = 0,
			["Materials"] = {},
			["Relics"] = {},
			["Special Items"] = {}
		},
		["DailyData"] = {},
		["WeeklyData"] = {
			["ClaimTime"] = nil,
			["Day"] = 1
		},
		["Materials"] = 0,            -- The number of materials the player has in their inventory
		["Relics"] = 0,               -- The number of relics the player has equipped
		["Special Items"] = 0,        -- The number of special items the player has in their inventory
		["GuaranteedUltraRare"] = 0,  -- The number of guaranteed ultra rare swings the player has
		["HarvestPerks"] = {          -- The perks the player can still purchase regarding multi harvest
			[1] = true,
			[2] = true,
			[3] = true
		},
		["Breaks"] = {0, 5},          -- The number of breaks the player has done relative to earning the next mystery material and the rarity they will receive
		["Tutorial"] = {false, 1}	  -- Completed tutorial: boolean, Step: number
	}
	
	local success = PlayerDataHandler.overrideExistingData(8378857461, nil)
	if success then
		print("successfully saved data")
	else
		warn("There was an issue saving the data, try again")
	end
end

--saveData()

PlayerDataHandler.setAutoSaveCallback(function(userId)
	local success, cash, power = PlayerDataHandler.saveData(userId)
	if success then
		LeaderboardHandler.onPlayerLeaving(userId, cash, power)
	end
end)

-- Set up the leaderboard data, start the countdown
task.spawn(function()
	LeaderboardHandler.setup()
end)