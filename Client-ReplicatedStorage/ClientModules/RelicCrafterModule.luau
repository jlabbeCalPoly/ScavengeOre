-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage.Remotes
local HelperModules = ReplicatedStorage.HelperModules
local GuiComponents = HelperModules.GuiComponents
local SharedUtility = HelperModules.SharedUtility

-- Modules
local Stack = require(HelperModules.Stack)
local DisconnectAndDestroy = require(HelperModules.DisconnectAndDestroy)
local ConfirmationPrompt = require(HelperModules.ConfirmationPrompt)
local Colors = require(HelperModules.Colors)
local GuiSkeleton = require(GuiComponents.GuiSkeleton)
local CatalogContainer = require(GuiComponents.CatalogContainer)
local Relics = require(SharedUtility.Relics)
local Constants = require(SharedUtility.Constants)

-- Remotes
local Relic = Remotes.Relic

-- Objects
local ScrollingFrame = script.ScrollingFrame

local RelicCrafterModule = {}
RelicCrafterModule.__index = RelicCrafterModule

function RelicCrafterModule.new(playerData)
	local guiSkeleton, gui = GuiSkeleton.new()

	local frame = gui.Frame

	local scrollingFrame = ScrollingFrame:Clone()
	scrollingFrame.Parent = frame
	
	local self = {
		transitioning = false,
		previousSpecification = nil,
		guiSkeleton = guiSkeleton,
		scrollingFrame = scrollingFrame,
		inventory = playerData["Inventory"]["Materials"],
		tutorial = playerData["Tutorial"],
		scrollHeight = 220,  
		containerHeight = 195,
		scale = 1,
		containers = {},
		connections = {}
	}
	setmetatable(self, RelicCrafterModule)
	
	return self
end

--[[
	Enable the relic crafter with the specific relics found in the location
]]
function RelicCrafterModule:enableRelicCrafter(specification)
	if self.transitioning then
		return
	end
	self.transitioning = true
	
	if self.previousSpecification ~= specification then
		self.previousSpecification = specification
		local relics = Relics.getRelicsByLocation(specification)
		for _, relic in pairs(relics) do
			local relicData = Relics.getRelicsData(relic)
			
			-- Determine if the relic crafter is a normal or "Eternal" crafter
			if relicData[5] >= 0 then
				self.guiSkeleton:setContent("Relic Crafter", "NormalRelic")
			else
				self.guiSkeleton:setContent("Eternal Crafter", "EternalRelic")
			end
			
			local catalogContainer = CatalogContainer.new(
				self.scrollingFrame,
				"LargeCraft",
				self.scale
			)
			
			local colors = Colors.getBoostColors(relicData[2])
			catalogContainer:setContent(
				relic,
				{
					{
						relic,
						relic,
						colors.Static,
						Constants.WHITE_COLOR,
						{
							colors.Gradient,
							relicData[2],
							relicData[3]
						},
						self.inventory,
						self.tutorial,
						relicData[1],
						"Craft cost",
						"Craft",
						function(button)
							self:craftButtonCallback(button, relic)
						end,
					}
				}
			)
			catalogContainer:enable()
			
			table.insert(
				self.containers,
				catalogContainer
			)
		end
		
		self.scrollingFrame.CanvasPosition = Vector2.new(0, 0)
		self:scroll(0)

		table.insert(
			self.connections,
			self.scrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
				self:onScroll(self.scrollingFrame.CanvasPosition.Y)
			end)
		)
		
		self.scrollingFrame.CanvasSize = UDim2.new(0,0,0,#relics * 195)
	end
	
	self.transitioning = false
end

function RelicCrafterModule:disableRelicCrafter()
	if self.transitioning then
		return
	end
	self.transitioning = true
	
	self.previousSpecification = nil

	DisconnectAndDestroy(self.connections)
	for _, container in pairs(self.containers) do
		container:destroy()
	end
	table.clear(self.containers)

	self.transitioning = false
end

function RelicCrafterModule:enable(specification)
	if self.transitioning then
		return
	end

	self:enableRelicCrafter(specification)
	self.guiSkeleton:enable(function()
		self:disable()
	end)

	Stack.push(self, specification)
end

--[[
	Disable the upgrade gui and reset 
]]
function RelicCrafterModule:disable()
	if self.transitioning then
		return
	end

	self:disableRelicCrafter()
	self.guiSkeleton:disable()

	Stack.pop()

	-- Return true so the stack can proceed with disabling other items in the stack
	return true
end

function RelicCrafterModule:onResize(scale)
	-- Changed from 1, may have been a mistake before
	self.scale = scale
	self.scrollHeight = 220 * scale 
	self.containerHeight = 195 * scale
	self.guiSkeleton:onResize(scale)
	
	if not self.transitioning then
		self.transitioning = true
		
		for _, container in pairs(self.containers) do
			container:onResize(scale)
		end
		
		self.transitioning = false
	end
end

function RelicCrafterModule:onInventoryUpdate()
	if self.previousSpecification ~= nil then
		self.transitioning = true
		
		for _, container in pairs(self.containers) do
			container:onInventoryUpdate(self.inventory)
		end
		
		self.transitioning = false
	end
end

function RelicCrafterModule:onScroll(scrollYPos)
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
function RelicCrafterModule:scroll(scrollYPos)
	local scrollYEndPos = scrollYPos + self.scrollHeight

	for index = 1, #self.containers do
		if scrollYEndPos >= ((index-1) * self.containerHeight) and scrollYPos <= (index * self.containerHeight) then
			self.containers[index]:play()
		else
			self.containers[index]:cancel()
		end
	end
end

---- CALLBACK FUNCTIONS ----

	--[[
		Sell the selected amount (self.value) or the selected material (self.materialDisplayed) 
	]]
	function RelicCrafterModule:craftButtonCallback(
		button: TextButton,
		name: string
	)
		if not button:getAwaiting() then
			ConfirmationPrompt.enable(
				string.format("Would you like to craft %s?", name),
				function()
					local firedTimestamp = workspace:GetServerTimeNow()
					button:enableAwaiting(Relic, firedTimestamp)
					Relic:FireServer(firedTimestamp, name)
				end
			)
		end
	end

return RelicCrafterModule