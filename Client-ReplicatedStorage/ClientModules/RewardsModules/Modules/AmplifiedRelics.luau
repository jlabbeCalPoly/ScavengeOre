-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage.Remotes
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local GuiComponents = HelperModules.GuiComponents

-- Modules
local DisconnectAndDestroy = require(HelperModules.DisconnectAndDestroy)
local ConfirmationPrompt = require(HelperModules.ConfirmationPrompt)
local Colors = require(HelperModules.Colors)
local Constants = require(SharedUtility.Constants)
local Relics = require(SharedUtility.Relics)
local CatalogContainer = require(GuiComponents.CatalogContainer)

-- Remotes
local AmplifiedRelic = Remotes.AmplifiedRelic

-- Objects
local Content = script.Content

local AmplifiedRelics = {}
AmplifiedRelics.__index = AmplifiedRelics

function AmplifiedRelics.new(
	parent,
	playerData
)
	for _, child in Content:GetChildren() do
		child:Clone()
		child.Parent = parent
	end
	
	local scrollingFrame = parent.ScrollingFrame
	local amplifiedDescription = parent.AmplifiedDescription
	
	local self = {
		enabled = false,
		scrollingFrame = scrollingFrame,
		amplifiedDescription = amplifiedDescription,
		inventory = playerData["Inventory"]["Materials"],
		tutorial = playerData["Tutorial"],
		scrollHeight = 200,  
		containerHeight = 195,
		scale = 1,
		containers = {},
		connections = {}
	}
	setmetatable(self, AmplifiedRelics)
	
	return self
end

function AmplifiedRelics:enable()
	if self.enabled then
		return
	end
	self.enabled = true
	
	local relics = Relics.getAmplifiedRelics()
	for _, relic in pairs(relics) do
		local relicData = Relics.getRelicsData(relic)
		
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
					Constants.AMPLIFIED_COLOR,
					Constants.WHITE_COLOR,
					{
						colors.Gradient,
						relicData[2],
						relicData[3],
						{"Times", "Power!"}
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
	
	self.scrollingFrame.Visible = true
	self.amplifiedDescription.Visible = true
end

function AmplifiedRelics:disable()
	if not self.enabled then
		return
	end
	self.enabled = false

	DisconnectAndDestroy(self.connections)
	for _, container in pairs(self.containers) do
		container:destroy()
	end
	table.clear(self.containers)
	
	self.scrollingFrame.Visible = false
	self.amplifiedDescription.Visible = false
end

function AmplifiedRelics:onResize(scale)
	-- Changed from 1, may have been a mistake before
	self.scale = scale
	self.scrollHeight = 200 * scale 
	self.containerHeight = 195 * scale

	if self.enabled then
		for _, container in pairs(self.containers) do
			container:onResize(scale)
		end
	end
end

function AmplifiedRelics:onInventoryUpdate()
	if self.enabled then
		for _, container in pairs(self.containers) do
			container:onInventoryUpdate(self.inventory)
		end
	end
end

function AmplifiedRelics:onScroll(scrollYPos)
	self:scroll(scrollYPos)
end

	--[[
		Bypass the transitioning variable set in :enable() to get the initial scroll
	]]
function AmplifiedRelics:scroll(scrollYPos)
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

function AmplifiedRelics:craftButtonCallback(
	button: TextButton,
	name: string
)
	if not button:getAwaiting() then
		ConfirmationPrompt.enable(
			string.format("Would you like to craft %s?", name),
			function()
				local firedTimestamp = workspace:GetServerTimeNow()
				button:enableAwaiting(AmplifiedRelic, firedTimestamp)
				AmplifiedRelic:FireServer(firedTimestamp, name)
			end
		)
	end
end

return AmplifiedRelics