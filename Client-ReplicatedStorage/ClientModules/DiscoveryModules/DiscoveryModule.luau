-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local GuiComponents = HelperModules.GuiComponents
local SharedUtility = HelperModules.SharedUtility

-- Modules
local GuiSkeleton = require(GuiComponents.GuiSkeleton)
local Materials = require(SharedUtility.Materials)
local DiscoveryContainer = require(script.DiscoveryContainer)
local Stack = require(HelperModules.Stack)

-- Objects
local ScrollingFrame = script.ScrollingFrame

local DiscoveryModule = {}
DiscoveryModule.__index = DiscoveryModule

function DiscoveryModule.new(playerData)
	local guiSkeleton, gui = GuiSkeleton.new()
	guiSkeleton:setContent("Discoveries", "Discovery")
	
	local frame = gui.Frame

	local scrollingFrame = ScrollingFrame:Clone()
	scrollingFrame.Parent = frame
	
	local self = {
		enabled = false,
		guiSkeleton = guiSkeleton,
		scrollingFrame = scrollingFrame,
		containers = {}
	}
	setmetatable(self, DiscoveryModule)
	
	self:initialize(playerData["Inventory"]["Materials"], Materials.getAllMaterialData())
	
	return self
end

function DiscoveryModule:update(materialList)
	for _, materialData in pairs(materialList) do
		if materialData.New then
			local name = materialData.Name
			local location = Materials.getMaterialLocation(name)
			self.containers[location]:update(name)
		end
	end
end

function DiscoveryModule:enable()
	self.guiSkeleton:enable(function()
		self:disable()
	end)

	Stack.push(self)
end

--[[
	Disable the InventoryModule gui and reset 
]]
function DiscoveryModule:disable()
	self.guiSkeleton:disable()

	Stack.pop()

	-- Return true so the stack can proceed with disabling other items in the stack
	return true
end

function DiscoveryModule:sleep()
	self.guiSkeleton:sleep()
end

function DiscoveryModule:unsleep()
	self.guiSkeleton:unsleep()
end

function DiscoveryModule:onResize(scale)
	self.guiSkeleton:onResize(scale)
end

function DiscoveryModule:initialize(playerMaterials, allMaterials)
	local totalHeight = 0
	for location, rarities in pairs(allMaterials) do
		local discoveryContainer, height = DiscoveryContainer.new(self.scrollingFrame, location, rarities, playerMaterials)
		totalHeight += height
		
		table.insert(
			self.containers,
			discoveryContainer
		)
	end
	
	self.scrollingFrame.CanvasSize = UDim2.new(0,0,0,totalHeight)
end

return DiscoveryModule