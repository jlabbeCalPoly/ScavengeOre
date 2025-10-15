-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules

-- Modules
local MainButtonsModule = require(script.MainButtonsModule)
local InputGuiModule = require(script.InputGuiModule)
local AmplifiedVouchersModule = require(script.AmplifiedVouchersModule)
local CashManagerModule = require(script.CashManagerModule)
local ChangeListModule = require(script.ChangeListModule)
local MysteryMaterialModule = require(script.MysteryMaterialModule)
local MaterialManagerModule = require(script.MaterialManagerModule)
local TutorialModule = require(script.TutorialModule)
local RecipeCard = require(HelperModules.RecipeCard)

-- Objects
local ScreenGui = script.ScreenGui

local MainGuiModule = {}
MainGuiModule.__index = MainGuiModule

function MainGuiModule.new(playerData)
	local gui = ScreenGui:Clone()
	gui.Parent = Players.LocalPlayer.PlayerGui
	
	local scale = gui.UIScale
	
	local MainButtonsModule = MainButtonsModule.new(gui)
	local InputGuiModule = InputGuiModule.new(gui)
	local CashManagerModule = CashManagerModule.new(gui, playerData)
	local AmplifiedVouchersModule = AmplifiedVouchersModule.new(playerData)
	local MaterialManagerModule = MaterialManagerModule.new(gui, playerData)
	local ChangeListModule = ChangeListModule.new(gui, playerData["Settings"])
	local MysteryMaterialModule = MysteryMaterialModule.new(gui)
	RecipeCard.setup(gui, playerData)
	
	local self = {
		scale = scale,
		gui = gui,
		MainButtonsModule = MainButtonsModule,
		MysteryMaterialModule = MysteryMaterialModule,
		MaterialManagerModule = MaterialManagerModule,
		InputGuiModule = InputGuiModule,
		AmplifiedVouchersModule = AmplifiedVouchersModule,
		CashManagerModule = CashManagerModule,
		ChangeListModule = ChangeListModule
	}
	setmetatable(self, MainGuiModule)
	
	self:initialize(playerData)
	
	return self
end

function MainGuiModule:onResize(scale)
	self.scale.Scale = scale
end

-- TODO: Eventually change to handle if main buttons module is enabled or not if I want to add minigame features, etc.
function MainGuiModule:setEnableGuiCallback(callback)
	self.MainButtonsModule:setEnableGuiCallback(callback)
	self.CashManagerModule:setEnableGuiCallback(callback)
	self.MaterialManagerModule:setEnableGuiCallback(callback)
end

function MainGuiModule:setSwingButtonCallback(callback)
	self.InputGuiModule:setSwingButtonCallback(callback)
end

function MainGuiModule:updateCashManagerModule(remainingCash: number, cashChange: number)
	self.CashManagerModule:setValue(remainingCash, cashChange)
end

function MainGuiModule:updateAmplifiedVouchersModule(remainingAmplifiedVouchers: number)
	self.AmplifiedVouchersModule:setValue(remainingAmplifiedVouchers)
end

function MainGuiModule:updateMysteryMaterialModule(breaks)
	self.MysteryMaterialModule:setContent(breaks)
end

function MainGuiModule:updateChangeList(list)
	self.ChangeListModule:addItems(list)
end

function MainGuiModule:updateInventory(list)
	self.MaterialManagerModule:updateInventory(list)
end

function MainGuiModule:setInventoryCapacity(leftVal, rightVal)
	self.MaterialManagerModule:setCapacity(leftVal, rightVal)
end

function MainGuiModule:onStorageUpgrade(value)
	self.MaterialManagerModule:setCapacity(nil, value)
end

function MainGuiModule:checkForTutorial(playerData)
	local completed, step = unpack(playerData["Tutorial"])
	if not completed then
		TutorialModule.new(
			self.gui,
			playerData,
			step
		)
	end
end

function MainGuiModule:initialize(playerData)
	self.MysteryMaterialModule:setContent(playerData["Breaks"])
end

return MainGuiModule