--[[
	Global confirmation prompt used by different modules
]]

-- Services
local Players = game:GetService("Players")

-- Folders
local HelperModules = script.Parent
local SharedUtility = HelperModules.SharedUtility
local GuiComponents = HelperModules.GuiComponents
local Buttons = GuiComponents.Buttons

-- Modules
local Constants = require(SharedUtility.Constants)
local GuiTween = require(GuiComponents.GuiTween)
local CustomizableButton = require(Buttons.CustomizableButton)

-- Objects
local ScreenGui = script.ScreenGui
local self = nil

local ConfirmationPrompt = {}

function ConfirmationPrompt.setup()
	local gui = ScreenGui:Clone()
	gui.Parent = Players.LocalPlayer.PlayerGui
	
	local guiTween = GuiTween.new(gui.Frame)
	
	local Frame = gui.Frame
	local UIScale = gui.UIScale
	
	local cancelButton = CustomizableButton.new(
		Frame,
		Vector2.new(0,1),
		UDim2.new(0,10,1,0),
		UDim2.new(0,80,0,35),
		true,
		Constants.RED_COLOR,
		Constants.DARK_RED_COLOR,
		"Cancel",
		"Text",
		{"Glimmer", "Enlarging"}
	)
	
	local confirmButton = CustomizableButton.new(
		Frame,
		Vector2.new(1,1),
		UDim2.new(1,-10,1,0),
		UDim2.new(0,80,0,35),
		true,
		Constants.UNCOMMON_COLOR_BASE,
		Constants.UNCOMMON_COLOR_DARK,
		"Confirm",
		"Text",
		{"Glimmer", "Enlarging"}
	)
	
	self = {
		enabled = false,
		gui = gui,
		UIScale = UIScale,
		cancelButton = cancelButton,
		confirmButton = confirmButton,
		guiTween = guiTween
	}
end

function ConfirmationPrompt.disable()
	if not self.enabled then
		return
	end
	self.enabled = false
	
	self.cancelButton:disable()
	self.confirmButton:disable()
	
	self.gui.Enabled = false
	self.guiTween:disable()
end

function ConfirmationPrompt.enable(message: String, callback)
	if self.enabled then
		ConfirmationPrompt.disable()
	end
	self.enabled = true
	
	self.gui.Frame.TextLabel.Text = message
	self.cancelButton:enable(function()
		ConfirmationPrompt.disable()
	end)
	self.confirmButton:enable(function()
		ConfirmationPrompt.disable()
		callback()
	end)
	
	self.gui.Enabled = true
	self.guiTween:enable()
end

function ConfirmationPrompt.onResize(scale)
	self.UIScale.Scale = scale
end

return ConfirmationPrompt