-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local GuiComponents = HelperModules.GuiComponents
local SharedUtility = HelperModules.SharedUtility

-- Modules
local Stack = require(HelperModules.Stack)
local DisconnectAndDestroy = require(HelperModules.DisconnectAndDestroy)
local GuiSkeleton = require(GuiComponents.GuiSkeleton)
local CatalogContainer = require(GuiComponents.CatalogContainer)
local ShopData = require(SharedUtility.ShopData)

-- Objects
local ScrollingFrame = script.ScrollingFrame

local ShopModule = {}
ShopModule.__index = ShopModule

function ShopModule.new(playerData)
	local guiSkeleton, gui = GuiSkeleton.new()
	guiSkeleton:setContent("Exclusive Shop", "Shop")
	
	local frame = gui.Frame

	local scrollingFrame = ScrollingFrame:Clone()
	scrollingFrame.Parent = frame
	
	local unlockedLocations = playerData["LevelStats"]["UnlockedLocations"]
	local defaultShopData = ShopData.getDefaultShopData(unlockedLocations)
	local containers = {}
	for _, entry in pairs(defaultShopData) do
		local catalogContainerType, catalogContainerTitle, details = unpack(entry)
		
		local catalogContainer = CatalogContainer.new(
			scrollingFrame,
			catalogContainerType,
			1
		)
		catalogContainer:setContent(catalogContainerTitle, details)
		
		table.insert(
			containers,
			catalogContainer
		)
	end

	-- Set the conditions for the tool bundle ...
	containers[1]:setCondition(
		{playerData["LevelStats"]["Tool"]}, 
		"NumberCondition",
		{ShopData.getTool(unlockedLocations)}
	)
	-- ... and relic equip container
	containers[3]:setCondition(
		{playerData["LevelStats"]["UnlockedSlots"]},
		"NumberCondition",
		{10}
	)
	containers[3]:setConditionUI(
		playerData["LevelStats"]["UnlockedSlots"],
		10,
		"Unlocked"
	)
	containers[4]:setCondition(
		playerData["HarvestPerks"],
		"BooleanCondition",
		{false, false, false}
	)
	
	local self = {
		enabled = false,
		transitioning = false,
		guiSkeleton = guiSkeleton,
		scrollingFrame = scrollingFrame,
		containers = containers,
		--[[
		   The following 3 represent the default heights for the containers/frames, 
		   used later to determine which elements are visible duing a scroll
		]]
		scrollHeight = 220,  
		containerHeight = 225,
		scale = 1,
		connections = {}
	}
	setmetatable(self, ShopModule)
	
	self.scrollingFrame.CanvasSize = UDim2.new(0,0,0,self.containerHeight * #containers)
	
	return self
end

function ShopModule:setToolLevel(level)
	self.containers[1]:setCondition(
		{level},
		nil,
		{nil}
	)
end

function ShopModule:setToolCondition(location)
	self.containers[1]:setCondition(
		{nil},
		"NumberCondition",
		ShopData.getTool(location)
	)
end

function ShopModule:setHarvestCondition(perks)
	self.containers[4]:setCondition(
		perks,
		"BooleanCondition",
		{false, false, false}
	)
end

function ShopModule:setEquipLevel(level)
	local container = self.containers[3]
	container:setCondition(
		{level},
		nil,
		{nil}
	)
	container:setConditionUI(
		level
	)
end

function ShopModule:setBundleData(location)
	local locationData = ShopData.getBundleShopData(location)
	
	for index, bundleData in pairs(locationData) do
		local containerType, title, details = unpack(bundleData)
		self.containers[index]:setContent(title, details)
	end

	-- Set the conditions for the tool bundle
	self.containers[1]:setCondition(
		{1}, 
		"NumberCondition",
		{ShopData.getTool(location)}
	)
	
	-- Set the values for the cash bundles
	self.containers[5]:setContent(
		"Cash Bundles!",
		ShopData.getCashData(location)
	)
end

function ShopModule:enable(specification, scrollPos)
	if self.transitioning or self.enabled then
		return
	end
	self.transitioning = true
	self.enabled = true
	
	for _, container in (self.containers) do
		container:enable()
	end
	
	local initalPos
	if scrollPos then
		initalPos = scrollPos * self.scale
	else
		initalPos = 0
	end
	self.scrollingFrame.CanvasPosition = Vector2.new(0, initalPos)
	self:scroll(initalPos)
	
	table.insert(
		self.connections,
		self.scrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			self:onScroll(self.scrollingFrame.CanvasPosition.Y)
		end)
	)
	
	self.guiSkeleton:enable(function()
		self:disable()
	end)

	Stack.push(self)
	
	self.transitioning = false
end

function ShopModule:disable()
	if self.transitioning or not self.enabled then
		return
	end
	self.transitioning = true
	self.enabled = false
	
	self.guiSkeleton:disable()
	
	DisconnectAndDestroy(self.connections)	
	for _, container in pairs(self.containers) do
		container:cancel()
	end

	Stack.pop()

	self.transitioning = false
	-- Return true so the stack can proceed with disabling other items in the stack
	return true
end

function ShopModule:onResize(scale)
	self.scale = scale
	self.scrollHeight = 220 * scale
	self.containerHeight = 225 * scale
	
	self.guiSkeleton:onResize(scale)
	
	for _, container in (self.containers) do
		container:onResize(scale)
	end
end

function ShopModule:onScroll(scrollYPos)
	if self.transitioning then
		return
	end
	self.transitioning = true
	
	self:scroll(scrollYPos)
	
	self.transitioning = false
end

	--[[
		Bypass the transitioning variable set in :enable() to get the initial scroll
	]]
	function ShopModule:scroll(scrollYPos)
		local scrollYEndPos = scrollYPos + self.scrollHeight

		for index = 1, #self.containers do
			if scrollYEndPos >= ((index-1) * self.containerHeight) and scrollYPos <= (index * self.containerHeight) then
				self.containers[index]:play()
			else
				self.containers[index]:cancel()
			end
		end
	end

return ShopModule