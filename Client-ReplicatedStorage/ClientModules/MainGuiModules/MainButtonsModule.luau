-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local GuiComponents = HelperModules.GuiComponents
local GuiParticles = GuiComponents.GuiParticles
local Buttons = GuiComponents.Buttons

-- Modules
local Constants = require(SharedUtility.Constants)
local ExpandableButton = require(Buttons.ExpandableButton)
local CustomizableButton = require(Buttons.CustomizableButton)
local GlintGuiParticles = require(GuiParticles.GlintGuiParticles)

-- Objects
local LargeFrame = script.LargeFrame
local MediumFrame = script.MediumFrame
local SmallFrame = script.SmallFrame

local MainButtonsModule = {}
MainButtonsModule.__index = MainButtonsModule

function MainButtonsModule.new(
	parent
)
	local largeFrame = LargeFrame:Clone()
	local mediumFrame = MediumFrame:Clone()
	local smallFrame = SmallFrame:Clone()
	largeFrame.Parent = parent
	mediumFrame.Parent = parent
	smallFrame.Parent = parent
	
	local upgradeChildButtons = {
		ExpandableButton.new(
			nil,
			UDim2.new(0,0,0.5,0),
			60,
			"UpgradeStorage",
			"Upgrade Storage",
			true,
			false
		),
		ExpandableButton.new(
			nil,
			UDim2.new(0,0,0.5,0),
			60,
			"UpgradeTool",
			"Upgrade Tool",
			true,
			false
		)
	}
	
	local upgradeButton = ExpandableButton.new(
		largeFrame,
		UDim2.new(0,70,0,0),
		60,
		"Upgrade",
		"Upgrades",
		false,
		true,
		upgradeChildButtons
	)
	
	local discoveryButton = ExpandableButton.new(
		largeFrame,
		UDim2.new(0,0,0,0),
		60,
		"Discovery",
		"Discoveries",
		false,
		false
	)
	
	local inventoryChildButtons = {
		ExpandableButton.new(
			nil,
			UDim2.new(0,0,0.5,0),
			60,
			"Materials",
			"Materials",
			true,
			false
		),
		ExpandableButton.new(
			nil,
			UDim2.new(0,0,0.5,0),
			60,
			"Relics",
			"Relics",
			true,
			false
		)
--		ExpandableButton.new(
--			nil,
--			UDim2.new(0,0,0.5,0),
--			60,
--			"Materials",
--			"Special Items",
--			true,
--			false
--		)
	}
	local inventoryButton = ExpandableButton.new(
		largeFrame,
		UDim2.new(0,70,0,70),
		60,
		"Storage",
		"Inventories",
		false,
		true,
		inventoryChildButtons
	)
	
	local shopButton = ExpandableButton.new(
		largeFrame,
		UDim2.new(0,0,0,70),
		60,
		"Shop",
		"Exclusive Shop",
		false,
		false
	)
	
	local rewardsChildButtons = {
		ExpandableButton.new(
			nil,
			UDim2.new(0,0,0.5,0),
			60,
			"Weekly",
			"Weekly",
			true,
			false
		),
		ExpandableButton.new(
			nil,
			UDim2.new(0,0,0.5,0),
			60,
			"Daily",
			"Daily",
			true,
			false
		),
		ExpandableButton.new(
			nil,
			UDim2.new(0,0,0.5,0),
			60,
			"Amplified Relics",
			"Amplified Relics",
			true,
			false
		)
	}
	local rewardsButton = ExpandableButton.new(
		largeFrame,
		UDim2.new(0,32,0,140),
		60,
		"Rewards",
		"Rewards",
		false,
		true,
		rewardsChildButtons
	)
	
	local settingButton = ExpandableButton.new(
		smallFrame,
		UDim2.new(0,0,0,0),
		30,
		"Settings",
		"Settings",
		false,
		false,
		nil,
		true
	)
	local leaderboardButton = ExpandableButton.new(
		smallFrame,
		UDim2.new(0,35,0,0),
		30,
		"Leaderboard",
		"Leaderboard",
		false,
		false,
		nil,
		true
	)
	
	-- Set up the medium frame "4x Luck" button
	local luckButton = CustomizableButton.new(
		mediumFrame,
		Vector2.new(0.5,0),
		UDim2.new(0.5,0,0,5),
		UDim2.new(0,70,0,30),
		true,
		Constants.ULTRA_RARE_COLOR_BASE,
		Constants.ULTRA_RARE_COLOR_DARK,
		"4x Luck!",
		"Text",
		{"Glimmer", "Enlarging"}
	)
	luckButton:enable(function()
		local luckId = 3392885348
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, luckId)
	end)
	
	local glintGuiParticles = GlintGuiParticles.new(
		mediumFrame.ParticleFrame
	)
	glintGuiParticles:setColors({Constants.ULTRA_RARE_COLOR_BASE})
	glintGuiParticles:enable()
	
	local self = {
		upgradeButton = upgradeButton,
		inventoryButton = inventoryButton,
		shopButton = shopButton,
		discoveryButton = discoveryButton,
		rewardsButton = rewardsButton,
		settingButton = settingButton,
		leaderboardButton = leaderboardButton
	}
	setmetatable(self, MainButtonsModule)
	
	return self
end

function MainButtonsModule:setEnableGuiCallback(callback)
	self.inventoryButton:setCallback(callback)
	self.shopButton:setCallback(callback)
	self.upgradeButton:setCallback(callback)
	self.discoveryButton:setCallback(callback)
	self.rewardsButton:setCallback(callback)
	self.settingButton:setCallback(callback)
	self.leaderboardButton:setCallback(callback)
end

return MainButtonsModule