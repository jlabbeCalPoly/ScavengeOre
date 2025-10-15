-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local GuiComponents = HelperModules.GuiComponents
local Buttons = GuiComponents.Buttons

-- Modules
local TouchButton = require(Buttons.TouchButton)

-- Objects
local Frame = script.Frame

local TouchGuiModule = {}
TouchGuiModule.__index = TouchGuiModule

function TouchGuiModule.new(
	parent
)
	local frame = Frame:Clone()
	frame.Parent = parent
	
	local button = TouchButton.new(frame, "Swing")
	
	local self = {
		enabled = false,
		frame = frame,
		button = button,
		connections = {}
	}
	setmetatable(self, TouchGuiModule)
	
	return self
end

function TouchGuiModule:enable()
	if self.enabled then
		return
	end
	self.enabled = true
	
	self.frame.Visible = true
	self.button:enable()
end

function TouchGuiModule:disable()
	if not self.enabled then
		return
	end
	self.enabled = false

	self.frame.Visible = false
	self.button:disable()
end

function TouchGuiModule:setSwingButtonCallback(callback)
	self.button:setSwingButtonCallback(callback)
end

return TouchGuiModule