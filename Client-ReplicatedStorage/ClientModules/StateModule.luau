-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

-- Folders
local ClientModules = ReplicatedStorage.ClientModules
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local Utility = HelperModules.Utility
local Remotes = ReplicatedStorage.Remotes

-- ClientModules
local InventoryModule = require(ClientModules.InventoryModule)
local VFXModule = require(ClientModules.VFXModule)
local PromptModule = require(ClientModules.PromptModule)
local MaterialPopupModule = require(ClientModules.MaterialPopupModule)
local RelicCrafterModule = require(ClientModules.RelicCrafterModule)
local SettingsModule = require(ClientModules.SettingsModule)
local LeaderboardModule = require(ClientModules.LeaderboardModule)
local ShopModule = require(ClientModules.ShopModule)
local UpgradeModule = require(ClientModules.UpgradeModule)
local UnlockLocationModule = require(ClientModules.UnlockLocationModule)
local UnlockGateModule = require(ClientModules.UnlockGateModule)
local DiscoveryModule = require(ClientModules.DiscoveryModule)
local MainGuiModule = require(ClientModules.MainGuiModule)
local DailyLootChestModule = require(ClientModules.DailyLootChestModule)
local RewardsModule = require(ClientModules.RewardsModule)

-- HelperModules
local Hitboxes = require(HelperModules.Hitboxes)
local Movement = require(HelperModules.Movement)
local Barriers = require(HelperModules.Barriers)
local EternalBarriers = require(HelperModules.EternalBarriers)
local InputCategorizer = require(HelperModules.InputCategorizer)
local ConfirmationPrompt = require(HelperModules.ConfirmationPrompt)
local NotificationPrompt = require(HelperModules.NotificationPrompt)
local SFXModule = require(HelperModules.SFXModule)
local Stack = require(HelperModules.Stack)
local Constants = require(SharedUtility.Constants)
local Entities = require(SharedUtility.Entities)
local ConvertToKeyValue = require(Utility.ConvertToKeyValue)
local UIScaleCategorizer = require(Utility.UIScaleCategorizer)

-- Remotes
local VFX = Remotes.VFX
local Material = Remotes.Material
local Lock = Remotes.Lock
local Relic = Remotes.Relic
local AmplifiedRelic = Remotes.AmplifiedRelic
local Equip = Remotes.Equip
local Notification = Remotes.Notification
local Upgrade = Remotes.Upgrade
local Perk = Remotes.Perk
local Chat = Remotes.Chat
local Sell = Remotes.Sell
local SellAll = Remotes.SellAll
local Stats = Remotes.Stats
local LeaderboardStats = Remotes.LeaderboardStats
local OnPress = Remotes.OnPress
local Claim = Remotes.Claim

local StateModule = {}
-- What's happening: Since "self" doesn't define functions itself, we need to know
-- where to look to find the function. By setting __index to StateModule, the functions defined
-- in StateModule will be used
StateModule.__index = StateModule

-- Create a table of data (called "self"), then give data table a
-- collection of functions (contained in StateModules) so it can be manipulated
-- This allows self to act similarly to an object (like in Java)
function StateModule.new(playerData)
	local InventoryModule = InventoryModule.new(playerData)
	local VFXModule = VFXModule.new()
	local PromptModule = PromptModule.new()
	local MaterialPopupModule = MaterialPopupModule.new(playerData["Settings"])
	local UpgradeModule = UpgradeModule.new(playerData["LevelStats"], playerData["Inventory"])
	local UnlockLocationModule = UnlockLocationModule.new(playerData["LevelStats"]["UnlockedLocations"], playerData["Inventory"])
	local UnlockGateModule = UnlockGateModule.new(playerData)
	local ShopModule = ShopModule.new(playerData)
	local DiscoveryModule = DiscoveryModule.new(playerData)
	local MainGuiModule = MainGuiModule.new(playerData)
	local RelicCrafterModule = RelicCrafterModule.new(playerData)
	local SettingsModule = SettingsModule.new(playerData["Settings"])
	local LeaderboardModule = LeaderboardModule.new()
	local DailyLootChestModule = DailyLootChestModule.new(playerData)
	local RewardsModule = RewardsModule.new(playerData)
	
	Barriers.createBarriers(playerData["LevelStats"]["UnlockedLocations"])
	EternalBarriers.createBarriers(playerData["LevelStats"]["UnlockedEternalZones"])
	local swingHitbox, promptHitbox = Hitboxes.hitboxes()
	local overlapParams = OverlapParams.new()
	overlapParams.CollisionGroup = "Swing"
	
	--[[
		indexed modules to be accessed during button events that link to different guis
		< module, specification (can be nil), scrollPosition (can be nil) >
	]]
	local indexedModules = {
		["Materials"] = {InventoryModule, "Materials", nil},
		["Relics"] = {InventoryModule, "Relics", nil},
		["Discoveries"] = {DiscoveryModule, nil, nil},
		["Exclusive Shop"] = {ShopModule, nil, nil},
		["Cash"] = {ShopModule, nil, 900},
		["Upgrade Storage"] = {UpgradeModule, "Storage", nil},
		["Upgrade Tool"] = {UpgradeModule, "Tool", nil},
		["Relic Crafter"] = {RelicCrafterModule, nil, nil},
		["Daily Loot Chest"] = {DailyLootChestModule, nil, nil},
		["Unlock Location"] = {UnlockLocationModule, nil, nil},
		["Unlock Gate"] = {UnlockGateModule, nil, nil},
		["Daily"] = {RewardsModule, "Daily", nil},
		["Weekly"] = {RewardsModule, "Weekly", nil},
		["Amplified Relics"] = {RewardsModule, "Amplified Relics", nil},
		["Settings"] = {SettingsModule, nil, nil},
		["Leaderboard"] = {LeaderboardModule, nil, nil},
		["FromInventory"] = {
			["Materials"] = {UpgradeModule, "Storage", nil},
			["Relics"] = {ShopModule, nil, 450}
		}
	}
	
	local self = {
		-- Modules
		InventoryModule = InventoryModule,
		VFXModule = VFXModule,
		PromptModule = PromptModule,
		MaterialPopupModule = MaterialPopupModule,
		RelicCrafterModule = RelicCrafterModule,
		SettingsModule = SettingsModule,
		LeaderboardModule = LeaderboardModule,
		DailyLootChestModule = DailyLootChestModule,
		ShopModule = ShopModule,
		UpgradeModule = UpgradeModule,
		UnlockLocationModule = UnlockLocationModule,
		UnlockGateModule = UnlockGateModule,
		DiscoveryModule = DiscoveryModule,
		MainGuiModule = MainGuiModule,
		RewardsModule = RewardsModule,
		
		-- Indexed modules
		indexedModules = indexedModules,
		
		-- Objects (for hit detection)
		swingHitbox = swingHitbox,
		promptHitbox = promptHitbox,
		overlapParams = overlapParams,
		
		-- States
		enabled = true,
		swinging = false,
		bonusSwinging = false,
		
		-- Player data
		settings = playerData.Settings,
		mainStats = playerData.MainStats,
		levelStats = playerData.LevelStats,
		tutorial = playerData.Tutorial,
		
		-- Connections/animations
		animationTracks = {},
		connections = {}
	}
	-- If a function invoked by self is nil, refers to StateModule for it
	setmetatable(self, StateModule)
	
	self:initialize(playerData)
end

function StateModule:sell(timeStamp: number?, message: string, success: boolean, remainingCash: number, cashChange: number)
	if success then
		self.MainGuiModule:updateCashManagerModule(remainingCash, cashChange)
	end
	NotificationPrompt.enable(message, success)
end

function StateModule:equip(relic, equipped, totalEquipped)
	self.InventoryModule:setCapacity("Relics", totalEquipped)
	self.InventoryModule:onEquip(relic, equipped)
end

function StateModule:relic(relicList, totalEquipped)
	if totalEquipped then
		self.InventoryModule:setCapacity("Relics", totalEquipped)
	end
	self.InventoryModule:updateInventory("Relics", ConvertToKeyValue(relicList, "Id"))
	self.MainGuiModule:updateChangeList(relicList)
end

function StateModule:amplifiedRelic(relicList, amplifiedVoucherData)
	self.InventoryModule:updateInventory("Relics", ConvertToKeyValue(relicList, "Id"))
	
	self.MainGuiModule:updateAmplifiedVouchersModule(amplifiedVoucherData)
	self.RewardsModule:setCapacityCard(amplifiedVoucherData)
	
	self.RewardsModule:onInventoryUpdate()
	self.MainGuiModule:updateChangeList(relicList)
end

--[[
	Params:
	1) materialList: table of materials, providing the material name, rarity, and quantity. Sorted in desc order
	3) instance (optional): Only present if the material was earned by breaking something
]]
function StateModule:material(materialList, instance, skipPopup)
	-- Determine if there are any materials that the player gained
	local addList = {}
	local inventoryChange = 0
	
	for _, materialData in pairs(materialList) do
		local change = materialData.QuantityChanged
		inventoryChange += change
		
		if change > 0 then
			table.insert(
				addList,
				materialData
			)
		end
	end
	
	-- Update the material inventory with the new materials, converted into a key-pair table indexed by material name
	self.InventoryModule:updateInventory("Materials", ConvertToKeyValue(materialList, "Name"))
	
	-- Update the storage values in the material inventory / storage space gui element
	self.InventoryModule:setCapacity("Materials", inventoryChange, nil)
	
	self.MainGuiModule:updateInventory(materialList)
	self.MainGuiModule:setInventoryCapacity(inventoryChange, nil)
	
	self.RelicCrafterModule:onInventoryUpdate()
	self.UpgradeModule:onInventoryUpdate()
	self.UnlockGateModule:onInventoryUpdate()
	
	self.DiscoveryModule:update(materialList)
	task.spawn(function()
		self.MainGuiModule:updateChangeList(materialList)
	end)
	
	local function enableMaterialPopup()
		task.spawn(function()
			self.MaterialPopupModule:enable(addList)
		end)
	end
	
	local function enableRaritySFX()
		task.spawn(function()
			SFXModule.playRaritySFX(addList[1].Rarity)
		end)
	end
	
	local function playMaterialVFX()
		task.spawn(function()
			self.VFXModule:playMaterialVFX(instance, addList[1].Name)
		end)
	end
	
	local function playRarityVFX(rarity: number)
		task.spawn(function()
			self.VFXModule:playRarityVFX(instance, rarity)
		end)
	end

	local function resetEntity()
		Entities.resetEntity(instance)
	end
	
	-- Nothing was gained or lost, meaning the player's inventory is full
	if #materialList == 0 then
		NotificationPrompt.enable("Max materials stored. Upgrade your storage or sell materials!", false)
	end

	-- Return the addList if materials are being added (to enable the popup)
	if instance and #addList > 0 then
		enableRaritySFX()
		if not skipPopup then
			enableMaterialPopup()
			playRarityVFX(addList[1].Rarity)
			resetEntity()
			return addList
		end
		
	elseif #addList > 0 then
		enableRaritySFX()
		if not skipPopup then
			enableMaterialPopup()
			return addList
		end
		
	elseif instance then
		playRarityVFX(1)
		resetEntity()
	end
	
	return nil
end

--function StateModule:bonusSwing(instance)
--	local bonusPosition = math.round((Constants.BONUS_BAR_SIZE - Constants.BONUS_FRAME_SIZE) * math.random(0,100) * 0.01)
--	local timeStart = self.BonusModule:enable(instance, bonusPosition, self.mainStats.Luck)

--	local clickListener
--	clickListener = UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
--		if processed then
--			return
--		end

--		if input.UserInputType == Constants.BONUS_SWING_KEYCODE_MOUSE
--			or input.KeyCode == Constants.BONUS_SWING_KEYCODE_KEY 
--			or input.KeyCode == Constants.BONUS_SWING_GAMEPAD then
--			if not self.bonusSwinging then
--				return
--			end
--			self.bonusSwinging = false
--			clickListener:Disconnect()

--			local timeStamp = workspace:GetServerTimeNow()
--			local elapsed = timeStamp - timeStart
--			Material:FireServer(timeStamp, instance, elapsed, bonusPosition)
			
--			self.BonusModule:disable(elapsed, bonusPosition, self.mainStats.Luck)		
--			self.swinging = false
--		end
--	end)
--end

-- Handle the swing logic
function StateModule:swing()
	local instance
	local hits = workspace:GetPartsInPart(self.swingHitbox, self.overlapParams)
	if #hits > 0 then
		instance = hits[1].Parent
		local health = instance:GetAttribute("Health")
		-- make sure the health isn't already 0
	    -- if so, means the object is in the process of resetting
		if health ~= 0 then
			local power = self.mainStats.Power
			
			if health - power <= 0 then
				local timeStamp = workspace:GetServerTimeNow()
				Material:FireServer(timeStamp, instance)
				
				power = health
			end
			instance:SetAttribute("Health", health - power)
			
			VFX:FireServer(instance)
			self.VFXModule:VFX(instance, self.mainStats.Speed/2, "TestParticles")
			self.VFXModule:playHitmarkerVFX(instance, power)
			SFXModule.playDamageSFX(instance, instance:GetAttribute("SFX"))
		end
	end

	task.delay(self.mainStats.Speed, function()
		self.swinging = false
		
		-- Check if the player has Auto-Swing enabled
		if self.settings[1][2] and not self.swinging then
			self.swinging = true
			self:swing()
		end
	end)
	
	local speed = self.animationTracks.TestSwing.length / self.mainStats.Speed
	self.animationTracks.TestSwing:Play(0.1, 1, speed)
end

--[[
	Callback function for enabling guis based on the button pressed. Simply enable the module, as the module pushes itself onto the stack
	Params:
	1) keys: a list of keys to determine which specific entry in self.indexedModules to access
]]
function StateModule:pushToStack(keys: { string })
	local info = self.indexedModules
	for _, key in pairs(keys) do
		info = info[key]
	end
	
	local module, specification, scrollPosition = unpack(info)
	module:enable(specification, scrollPosition)
end

--[[
	Callback function for enabling guis based on the button pressed, specfically ones that reset the stack
]]
function StateModule:resetStack(key: string, specificationOverride)
	local info = self.indexedModules[key]

	local module, specification, scrollPosition = unpack(info)
	if specificationOverride then
		specification = specificationOverride
	end
	
	Stack.resetStack(module, specification, scrollPosition)
	
	-- If the tutorial is not completed, fire the OnPress event to track button clicks
	if not self.tutorial[1] then
		OnPress:Fire(key)
	end
end

--[[
	Set the UI scale, then pass the scale to each module involving a Screen Gui
]]
function StateModule:onResize()
	local scale = UIScaleCategorizer(workspace.CurrentCamera.ViewportSize.X)
	
	self.InventoryModule:onResize(scale)
	self.UpgradeModule:onResize(scale)
	self.UnlockLocationModule:onResize(scale)
	self.UnlockGateModule:onResize(scale)
	self.VFXModule:onResize(scale)
	self.MaterialPopupModule:onResize(scale)
	self.MainGuiModule:onResize(scale)
	self.PromptModule:onResize(scale)
	self.ShopModule:onResize(scale)
	self.RelicCrafterModule:onResize(scale)
	self.DiscoveryModule:onResize(scale)
	self.SettingsModule:onResize(scale)
	self.LeaderboardModule:onResize(scale)
	self.DailyLootChestModule:onResize(scale)
	self.RewardsModule:onResize(scale)
	NotificationPrompt.onResize(scale)
	ConfirmationPrompt.onResize(scale)
end

--[[
    Initialize user input connnections, animations, callbacks, listeners, etc.
]]
function StateModule:initialize(playerData)
	-- animations for the player
	local animationFolder = ReplicatedStorage.Animations
	local animator = Players.LocalPlayer.Character.Humanoid.Animator

	local animationTracks = {}
	for _, animation in animationFolder:GetChildren() do
		local animationTrack = animator:LoadAnimation(animation)
		animationTracks[animation.Name] = animationTrack
	end
	self.animationTracks = animationTracks
	
	-- setup
	SFXModule.setup(playerData["Settings"])
	NotificationPrompt.setup(playerData["Settings"])
	ConfirmationPrompt.setup()
	self.DailyLootChestModule:setup(
		playerData["DailyClaim"],
		"Claim now!",
		playerData["LevelStats"]["UnlockedLocations"]
	)
	
	-- User input listeners
	table.insert(
		self.connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
			if processed then
				return
			end
			
			if input.UserInputType == Constants.SWING_KEYCODE_MOUSE
			or input.KeyCode == Constants.SWING_KEYCODE_KEY 
			or input.KeyCode == Constants.SWING_GAMEPAD then
				if not self.swinging then
					self.swinging = true
					self:swing()
				end
			end
		end)
	)
	
	-- PromptHitbox listener
	table.insert(
		self.connections,
		self.promptHitbox.Touched:Connect(function(touchDetector)
			self.PromptModule:addPrompt(touchDetector, self.mainStats.Luck, self.mainStats.Speed/2)
		end)
	)
	table.insert(
		self.connections,
		self.promptHitbox.TouchEnded:Connect(function(touchDetector)
			self.PromptModule:removePrompt(touchDetector, self.mainStats.Luck, self.mainStats.Speed/2)
		end)
	)
	
	-- Material listener
	table.insert(
		self.connections,
		Material.OnClientEvent:Connect(function(materialList, instance, breaks)
			if breaks then
				self.MainGuiModule:updateMysteryMaterialModule(breaks)
			end
			local materialList = self:material(materialList, instance)
			self.MaterialPopupModule:enable(nil, materialList)
		end)
	)
	
	table.insert(
		self.connections,
		Relic.OnClientEvent:Connect(function(timeStamp, message, success, relicList, totalEquipped)
			if message then
				NotificationPrompt.enable(message, success)
			end
			
			if success then
				self:relic(relicList, totalEquipped)
				if message then
					SFXModule.playCraftSound()
				end
			end
		end)
	)
	
	table.insert(
		self.connections,
		AmplifiedRelic.OnClientEvent:Connect(function(timeStamp, message, success, relicList, amplifiedVoucherData)
			if message then
				NotificationPrompt.enable(message, success)NotificationPrompt.enable(message, success)
			end
			
			if success then
				self:amplifiedRelic(relicList, amplifiedVoucherData)
			end
		end)
	)
	
	table.insert(
		self.connections,
		Notification.OnClientEvent:Connect(function(message: string, success: boolean)
			NotificationPrompt.enable(message, success)
		end)
	)
	
	-- Equip listener
	table.insert(
		self.connections,
		Equip.OnClientEvent:Connect(function(timeStamp, message, success, relic, equipped, totalEquipped)
			if success then
				self:equip(relic, equipped, totalEquipped)
			end
			NotificationPrompt.enable(message, success)
		end)
	)
	
	table.insert(
		self.connections,
		Stats.OnClientEvent:Connect(function(mainStats)
			self.mainStats = mainStats
		end)
	)
	
	-- Sell listener
	table.insert(
		self.connections,
		Sell.OnClientEvent:Connect(function(...)
			self:sell(...)
		end)
	)
	
	table.insert(
		self.connections,
		SellAll.OnClientEvent:Connect(function(...)
			self:sell(...)
		end)
	)
	
	table.insert(
		self.connections,
		Lock.OnClientEvent:Connect(function(timeStamp: number,
											message: string,
											success: boolean,
											material: string,
											isLocked: boolean?
		)
			if success then
				self.InventoryModule:onLock(material, isLocked)
			end
			NotificationPrompt.enable(message, success)
		end)
	)
	
	table.insert(
		self.connections,
		Claim.OnClientEvent:Connect(function(timeStamp: number,
											message: string,
											success: boolean,
											claimType: string,
											taskNum: number,
											relicList,
											materialList,
											cashData,
											amplifiedVoucherData
		)
			if success then
				if claimType == "Chest" then
					self.DailyLootChestModule:onClaim(timeStamp)

					self:material(materialList, nil, true)
					if relicList then
						self:relic(relicList)
					end

					self.MaterialPopupModule:enable(relicList, materialList)
				elseif claimType == "Daily" then
					self.RewardsModule:onDailyClaim(taskNum)
					
					self.MainGuiModule:updateAmplifiedVouchersModule(amplifiedVoucherData)
					self.RewardsModule:setCapacityCard(amplifiedVoucherData)
					
					self.RewardsModule:onInventoryUpdate()
					
					SFXModule.playSound("LevelUp")
					
					NotificationPrompt.enable(message, success)
				elseif claimType == "Weekly" then
					-- Pass the claim timestamp and taskNum (Day) to the WeeklyRewards module
					self.RewardsModule:onWeeklyClaim(timeStamp, taskNum)
					
					self:material(materialList, nil, true)
					if relicList then
						self:relic(relicList)
					end
					
					if cashData then
						self.MainGuiModule:updateCashManagerModule(cashData[1], cashData[2])
					end
					
					if amplifiedVoucherData then
						self.MainGuiModule:updateAmplifiedVouchersModule(amplifiedVoucherData)
						self.RewardsModule:setCapacityCard(amplifiedVoucherData)
						
						self.RewardsModule:onInventoryUpdate()
					end

					self.MaterialPopupModule:enable(relicList, materialList)
				else
					-- Rewards are coming from a bundle (relic bundle)
					self:material(materialList, nil, true)
					self:relic(relicList)

					self.MaterialPopupModule:enable(relicList, materialList)
					
					NotificationPrompt.enable(message, success)
				end
			else
				--[[
					Notifications get in the way of the certain popups on success, so
				    only display it on failure
				]]
				NotificationPrompt.enable(message, success)
			end
		end)
	)
	
	table.insert(
		self.connections,
		Upgrade.OnClientEvent:Connect(function(timeStamp, message, success, upgradeType, value, cost: { any }?)
			if success then
				if upgradeType == "Tool" then
					self.ShopModule:setToolLevel(value)
					self.UpgradeModule:setLevel(upgradeType, value)
					if cost then
						self:material(cost)
					end
				elseif upgradeType == "Storage" then
					self.MainGuiModule:updateCashManagerModule(cost[1], cost[2])
					self.MainGuiModule:onStorageUpgrade(value)
					self.UpgradeModule:setLevel(upgradeType, value)
					self.InventoryModule:onUpgrade("Materials", value)
				elseif upgradeType == "Equip" then
					self.ShopModule:setEquipLevel(value)
					self.InventoryModule:onUpgrade("Relics", value)
				elseif upgradeType == "Location" then
					self.UnlockLocationModule:setUnlockedLocations(value)
					-- destroy the barrier, update the prox prompt by removing the specific promptPart
					local promptPart = Barriers.destroyBarrier(value)
					if promptPart then
						self.PromptModule:removePrompt(promptPart, self.mainStats.Luck, self.mainStats.Speed/2)
					end
					
					self.UnlockLocationModule:disable()
					
					self.MainGuiModule:updateCashManagerModule(cost[1], cost[2])
					self.ShopModule:setBundleData(value)
					self.DailyLootChestModule:onLocationUpgrade(value)
					self.RewardsModule:onLocationUpgrade(value)
					
					SFXModule.playSound("LevelUp")
				elseif upgradeType == "Gate" then
					self.UnlockGateModule:setUnlockedGates(value)
					-- destroy the barrier, update the prox prompt by removing the specific promptPart
					local promptPart = EternalBarriers.destroyBarrier(value)
					if promptPart then
						self.PromptModule:removePrompt(promptPart, self.mainStats.Luck, self.mainStats.Speed/2)
					end
					
					self.UnlockGateModule:disable()
					self:material(cost)
					
					SFXModule.playSound("LevelUp")
				end 
			end
			NotificationPrompt.enable(message, success)
		end)
	)
	
	table.insert(
		self.connections,
		Perk.OnClientEvent:Connect(function(message, success, perks)
			self.ShopModule:setHarvestCondition(perks)
			NotificationPrompt.enable(message, success)
		end)
	)
	
	local RBXGeneral = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
	table.insert(
		self.connections,
		Chat.OnClientEvent:Connect(function(message)
			RBXGeneral:DisplaySystemMessage(message)
		end)
	)
	
	table.insert(
		self.connections,
		VFX.OnClientEvent:Connect(function(instance, speed, particles)
			-- Determine if the player has others' VFX on or off
			if playerData["Settings"][4][2] and instance and speed and particles then
				self.VFXModule:ReplicatedVFX(instance, speed, particles)
			end
		end)
	)
	
	table.insert(
		self.connections,
		LeaderboardStats.OnClientEvent:Connect(function(untilRefresh, cashLeaderboard, powerLeaderboard)
			self.LeaderboardModule:setContent(untilRefresh, cashLeaderboard, powerLeaderboard)
		end)
	)
	LeaderboardStats:FireServer()
	
	-- UI Scale listener
	table.insert(
		self.connections,
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self:onResize()
		end)
	)

	-- Callbacks
	self.InventoryModule:setEnableGuiCallback(function(keys)
		self:pushToStack(keys)
	end)
	self.MainGuiModule:setEnableGuiCallback(function(key)
		self:resetStack(key)
	end)
	self.MainGuiModule:setSwingButtonCallback(function()
		if not self.swinging then
			self.swinging = true
			self:swing()
		end
	end)
	self.PromptModule:setEnableGuiCallback(function(key, specification)
		self:resetStack(key, specification)
	end)
	self.SettingsModule:setAutoSwingCallback(function()
		if not self.swinging then
			self.swinging = true
			self:swing()
		end
	end)
	
	-- Start/Stop the music
	self.SettingsModule:setMusicState()
	-- Start the Auto-Swing if enabled
	self.SettingsModule:setAutoSwingState()

	-- Set the UI scale and determine the input type
	self:onResize()
	
	-- Check if the player has yet to complete the tutorial
	self.MainGuiModule:checkForTutorial(playerData)
	
	Movement.enable()
end

return StateModule