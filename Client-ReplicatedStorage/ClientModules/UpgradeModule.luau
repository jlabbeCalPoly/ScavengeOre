--[[
	Handle the enabling/disabling of the upgrade gui
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage.Remotes
local HelperModules = ReplicatedStorage.HelperModules
local GuiComponents = HelperModules.GuiComponents
local SummaryCards = GuiComponents.SummaryCards
local SharedUtility = HelperModules.SharedUtility
local Utility = HelperModules.Utility

-- Modules
local Stack = require(HelperModules.Stack)
local ConfirmationPrompt = require(HelperModules.ConfirmationPrompt)
local LevelCard = require(GuiComponents.LevelCard)
local Dots = require(GuiComponents.Dots)
local GuiSkeleton = require(GuiComponents.GuiSkeleton)
local RequirementSummaryCard = require(SummaryCards.RequirementSummaryCard)
local Constants = require(SharedUtility.Constants)
local StorageData = require(SharedUtility.StorageData)
local ToolData = require(SharedUtility.ToolData)
local LoadImage = require(Utility.LoadImage)

-- Remotes
local Upgrade = Remotes.Upgrade

-- Objects
local Content = script.Content

local UpgradeModule = {}
UpgradeModule.__index = UpgradeModule

--[[
	Stores the player's material inventory and the amount of cash they own
]]
function UpgradeModule.new(LevelStats, InventoryStats)	
	local guiSkeleton, gui = GuiSkeleton.new()
	local Frame = gui.Frame
	
	for _, child in Content:GetChildren() do
		child:Clone()
		child.Parent = Frame
	end
	
	local CostFrame = Frame.CostFrame
	local LevelFrame = Frame.LevelFrame
	local DescriptionFrame = Frame.Description
	
	local currentLevelCard = LevelCard.new(
		LevelFrame,
		Vector2.new(0,0),
		UDim2.new(0,0,0,0)
	)
	
	local nextLevelCard = LevelCard.new(
		LevelFrame,
		Vector2.new(0,1),
		UDim2.new(0,0,1,0)
	)
	
	local dots = Dots.new(
		LevelFrame
	)
	
	local requirementSummaryCard = RequirementSummaryCard.new(
		CostFrame,
		1,
		Vector2.new(0.5,0.5),
		UDim2.new(0.5,0,0.5,0),
		255,
		120,
		{"Glimmer", "Awaiting", "Enlarging"}
	)
	
	-- The modules, specific icons and colors to be used in autoCenter based on the upgrade type
	local indexedModules = {
		["Storage"] = {
			StorageData, 
			"Materials", 
			Constants.BLACK_COLOR, 
			nil,
			"Upgrade your storage to hold more materials in your inventory!"
		},
		["Tool"] = {
			ToolData, 
			"Luck", 
			Constants.BLACK_COLOR, 
			Constants.UNCOMMON_COLOR_BASE,
			"Upgrade your tool to increase your luck! (Better materials on average)"
		}
	}
	
	local self = {
		transitioning = false, -- Debounce if an action is made by the user while some transition is occuring (updating cards, etc.)
		previousEnabled = nil, -- Keep track of the upgrade type that was enabled previously, if any

		guiSkeleton = guiSkeleton,
		DescriptionFrame = DescriptionFrame,
		currentLevelCard = currentLevelCard,
		nextLevelCard = nextLevelCard,
		dots = dots,
		requirementSummaryCard = requirementSummaryCard,
		
		levelData = {
			["Storage"] = LevelStats.Storage,
			["Tool"] = LevelStats.Tool
		},
		inventory = InventoryStats.Materials,
		indexedModules = indexedModules
	}
	setmetatable(self, UpgradeModule)

	return self
end

--[[
	Set the level stat for one of the values in levelData
]]
function UpgradeModule:setLevel(key, value)
	self.levelData[key] = value
	
	if self.previousEnabled == key and not self.transitioning then
		self.transitioning = true
		self:disableUpgrade(key)
		self.transitioning = false
		self:enableUpgrade(key)
	end
end

function UpgradeModule:enableUpgrade(upgradeType)
	if self.transitioning then
		return
	end
	self.transitioning = true
	
	if self.previousEnabled ~= upgradeType then
		self.previousEnabled = upgradeType
		
		local module, autoCenterImage, primaryColor, secondaryColor, description = unpack(self.indexedModules[self.previousEnabled])
		self.DescriptionFrame.Text = description
		
		local level = self.levelData[upgradeType]
		local nextLevel = level + 1

		-- Set the content of the guiSkeleton
		self.guiSkeleton:setContent(string.format(`Upgrade %s!`, upgradeType), "Upgrade"..self.previousEnabled)
		
		-- Enable each of the LevelCards
		self.currentLevelCard:enable(
			module, 
			level, 
			autoCenterImage, 
			primaryColor, 
			secondaryColor
		)
		
		-- Check if the player can still level up the specific stat
		if module.getTotalLevels() >= nextLevel then
			self.nextLevelCard:enable(
				module, 
				nextLevel, 
				autoCenterImage, 
				primaryColor, 
				secondaryColor
			)

			-- Enable the Dots visual effect
			self.dots:enable()

			self.requirementSummaryCard:setContent(
				self.inventory,
				module.getData(nextLevel).Cost,
				"Upgrade cost",
				"Upgrade",
				function(button)
					self:upgradeCallback(button)
				end
			)
			self.requirementSummaryCard:enable()
		end
	end

	self.transitioning = false
end

function UpgradeModule:disableUpgrade()
	self.currentLevelCard:disable()
	self.nextLevelCard:disable()
	self.dots:disable()
	self.requirementSummaryCard:disable()
	
	self.previousEnabled = nil
end

function UpgradeModule:enable(upgradeType: string)
	if self.transitioning then
		return
	end
	
	self:enableUpgrade(upgradeType)
	self.guiSkeleton:enable(function()
		self:disable()
	end)

	Stack.push(self, upgradeType)
end

--[[
	Disable the upgrade gui and reset 
]]
function UpgradeModule:disable()
	if self.transitioning then
		return
	end

	self:disableUpgrade()
	self.guiSkeleton:disable()

	Stack.pop()
	
	-- Return true so the stack can proceed with disabling other items in the stack
	return true
end

function UpgradeModule:sleep()
	self.guiSkeleton:sleep()
end

function UpgradeModule:unsleep()
	self.guiSkeleton:unsleep()
end

function UpgradeModule:onResize(scale)
	self.guiSkeleton:onResize(scale)
	
	self.requirementSummaryCard:onResize(scale)
end

function UpgradeModule:onInventoryUpdate()
	if self.previousEnabled == "Tool" and not self.transitioning then
		self.transitioning = true

		local module = self.indexedModules["Tool"][1]
		local data = module.getData(self.levelData["Tool"] + 1)
		if data then
			self.requirementSummaryCard:updateContent(self.inventory, data.Cost)
		end

		self.transitioning = false
	end
end

---- CALLBACKS ----
function UpgradeModule:upgradeCallback(button)
	if not button:getAwaiting() and self.previousEnabled then
		local upgradeType = self.previousEnabled
		local nextLevel = self.levelData[upgradeType] + 1
		ConfirmationPrompt.enable(
			string.format("Would you like to upgrade your %s to level %d?", string.lower(upgradeType), nextLevel),
			function()
				local firedTimestamp = workspace:GetServerTimeNow()
				button:enableAwaiting(Upgrade, firedTimestamp)
				Upgrade:FireServer(firedTimestamp, upgradeType, nextLevel)
			end
		)
	end
end

return UpgradeModule