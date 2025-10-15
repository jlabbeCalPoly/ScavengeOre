-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage.Remotes
local HelperModules = ReplicatedStorage.HelperModules
local GuiComponents = HelperModules.GuiComponents

-- Modules
local Stack = require(HelperModules.Stack)
local GuiSkeleton = require(GuiComponents.GuiSkeleton)
local SettingCard = require(GuiComponents.SettingCard)
local SFXModule = require(HelperModules.SFXModule)

-- Remotes
local Settings = Remotes.Settings

-- Objects
local ScrollingFrame = script.ScrollingFrame
local Acknowledgements = script.Acknowledgments

local Descriptions = {
	["Auto-Swing"] = "Automatically swing your tool without clicking",
	["Music"] = "Enable/disable the in-game music",
	["SFX"] = "Enable/disable the in-game sound effects",
	["Others' VFX"] = "Enable/disable visual effects caused by others",
	["Notifications"] = "Enable/disable all notification popups",
	["Material Popup"] = "Enable/disable the material discovery popup",
	["Resource Log"] = "Enable/disable the resource log"
}

local SettingsModule = {}
SettingsModule.__index = SettingsModule

function SettingsModule.new(settings)
	local guiSkeleton, gui = GuiSkeleton.new()
	guiSkeleton:setContent("Settings", "Settings")

	local frame = gui.Frame

	local scrollingFrame = ScrollingFrame:Clone()
	scrollingFrame.Parent = frame
	
	local settingCards = {}
	local compareSettings = {}
	for _, settingData in pairs(settings) do
		local title, setting = unpack(settingData)
		table.insert(
			settingCards,
			SettingCard.new(scrollingFrame, title, Descriptions[title], setting)
		)
		table.insert(
			compareSettings,
			{title, setting}
		)
	end
	
	local acknowledgements = Acknowledgements:Clone()
	acknowledgements.Parent = scrollingFrame
	
	-- Set the height of the scrolling frame (setting card height + padding)
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, (#settingCards * 50) + 20)
	
	local self = {
		enabled = false,
		transitioning = false,
		guiSkeleton = guiSkeleton,
		settings = settings,
		compareSettings = compareSettings,
		settingCards = settingCards
	}
	setmetatable(self, SettingsModule)
	
	return self
end

function SettingsModule:updateSettings(index, setting)
	self.settings[index][2] = setting
	
	-- Check if the setting is specifically for auto-swing or music
	if index == 1 then
		self:setAutoSwingState()
	elseif index == 2 then
		self:setMusicState()
	end
end

function SettingsModule:enable()
	if self.enabled or self.transitioning then
		return
	end
	self.enabled = true
	self.transitioning = true

	-- Get the default settings the player had enabled when enabling the settings gui
	for index, settingData in pairs(self.settings) do
		local title, setting = unpack(settingData)
		local compareSetting = self.compareSettings[index]
		compareSetting[1] = title
		compareSetting[2] = setting
	end
	for index, settingCard in pairs(self.settingCards) do
		settingCard:enable(function(setting)
			self:updateSettings(index, setting)
		end)
	end
	self.guiSkeleton:enable(function()
		self:disable()
	end)

	Stack.push(self)
	self.transitioning = false
end

--[[
	Disable the upgrade gui and reset 
]]
function SettingsModule:disable()
	if not self.enabled or self.transitioning then
		return
	end
	self.enabled = false
	self.transitioning = true
	
	local settingsChanged = false
	local settingsChangedList = {}

	for index, settingCard in pairs(self.settingCards) do
		settingCard:disable()
		local setting = settingCard:getSetting()
		if self.compareSettings[index][2] ~= setting then
			table.insert(
				settingsChangedList,
				{index, setting}
			)
			settingsChanged = true
		end
	end
	self.guiSkeleton:disable()

	Stack.pop()

	if settingsChanged then
		Settings:FireServer(settingsChangedList)
	end
	
	self.transitioning = false
	-- Return true so the stack can proceed with disabling other items in the stack
	return true
end

function SettingsModule:setMusicState()
	-- The music setting is specifically the second in the list
	if self.settings[2][2] then
		SFXModule.playMusic()
	else
		SFXModule.stopMusic()
	end
end

function SettingsModule:setAutoSwingState()
	if self.settings[1][2] then
		if self.autoSwingCallback then
			self.autoSwingCallback()
		end
	end
end

function SettingsModule:onResize(scale)
	self.guiSkeleton:onResize(scale)
end

function SettingsModule:setAutoSwingCallback(callback)
	self.autoSwingCallback = callback
end

return SettingsModule