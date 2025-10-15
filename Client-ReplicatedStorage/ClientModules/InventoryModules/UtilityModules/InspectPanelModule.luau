-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local GuiComponents = HelperModules.GuiComponents

-- Modules
local Constants = require(SharedUtility.Constants)
local Slider = require(GuiComponents.Slider) 
local AutoCenter = require(GuiComponents.AutoCenter)

-- Objects
local InspectPanelTemplate = script.InspectFrame

local InspectPanelModule = {}
InspectPanelModule.__index = InspectPanelModule

--[[
	Create a new InspectPanel, specifically for the InventoryModule
]]
function InspectPanelModule.new(parent)
	local inspectPanel = InspectPanelTemplate:Clone()
	inspectPanel.Parent = parent
	
	local slider = Slider.new(
		inspectPanel, 
		UDim2.new(0.5,0,0,90),
		UDim2.new(1,0,0,50),
		135
	)
	local itemFrame = inspectPanel.ItemFrame
	local size = itemFrame.Rarity.AbsoluteSize
	
	local autoCenter = AutoCenter.new(
		itemFrame,
		Vector2.new(0.5,0),
		UDim2.new(0.5,0,0.8,0),
		UDim2.new(1,0,0.2,0),
		size.X,
		size.Y,
		Constants.UNCOMMON_COLOR_DARK,
		"Cash"
	)
	
	local self = {
		inspectPanel = inspectPanel,
		slider = slider,
		autoCenter = autoCenter
	}
	setmetatable(self, InspectPanelModule)
	
	return self
end

--[[
	Enable the inspect module
]]
function InspectPanelModule:enable()
	self.inspectPanel.Visible = true
end

--[[
	Disable the inspect module
]]
function InspectPanelModule:disable()
	self.inspectPanel.Visible = false
end

function InspectPanelModule:disableSlider()
	self.slider:disable()
end

function InspectPanelModule:onResize(scale)
	self.slider:setPositionAndSize(scale)
end

--[[
	Clean up script
]]
function InspectPanelModule:destroy()
	self.slider:destroy()
	self.inspectPanel:Destroy()
end

return InspectPanelModule