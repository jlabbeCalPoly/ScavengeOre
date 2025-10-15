--[[
	Global confirmation prompt used by different modules
]]

-- Services
local Players = game:GetService("Players")

-- Folders
local HelperModules = script.Parent
local SharedUtility = HelperModules.SharedUtility
local Utility = HelperModules.Utility
local GuiComponents = HelperModules.GuiComponents

-- Modules
local SFXModule = require(HelperModules.SFXModule)
local Constants = require(SharedUtility.Constants)
local LoadImage = require(Utility.LoadImage)
local GuiTween = require(GuiComponents.GuiTween)

-- Objects
local ScreenGui = script.ScreenGui
local hideTask = nil
local self = nil

local NotificationPrompt = {}

function NotificationPrompt.setup(settings)
	local gui = ScreenGui:Clone()
	gui.Parent = Players.LocalPlayer.PlayerGui
	
	local guiTween = GuiTween.new(gui.Frame)

	local UIScale = gui.UIScale

	self = {
		enabled = false,
		settings = settings,
		gui = gui,
		UIScale = UIScale,
		guiTween = guiTween
	}
end

function NotificationPrompt.disable()
	if not self.enabled then
		return
	end
	self.enabled = false
	
	if hideTask ~= nil then
		task.cancel(hideTask)
	end

	self.gui.Enabled = false
	self.guiTween:disable()
end

function NotificationPrompt.enable(message: String, success: boolean)
	-- Determine if the player has notifications turned off or on
	if self.settings[5][2] then
		if self.enabled then
			NotificationPrompt.disable()
		end
		self.enabled = true

		local frame = self.gui.Frame
		local textLabel = frame.TextLabel
		local imageLabel = frame.ImageLabel

		local image
		local color
		if success then
			image = "Success"
			color = Constants.GREEN_COLOR
		else
			image = "Fail"
			color = Constants.RED_COLOR
			SFXModule.playSound("Error")
		end

		textLabel.TextColor3 = color
		textLabel.Text = message
		imageLabel.Image = LoadImage(image)	

		self.gui.Enabled = true
		self.guiTween:enable()

		hideTask = task.delay(5, function()
			hideTask = nil
			NotificationPrompt.disable()
		end)
	end
end

function NotificationPrompt.onResize(scale)
	self.UIScale.Scale = scale
end

return NotificationPrompt