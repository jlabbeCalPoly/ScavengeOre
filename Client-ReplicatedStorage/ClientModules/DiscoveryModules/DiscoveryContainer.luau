-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local Colors = require(HelperModules.Colors)
local Rarities = require(SharedUtility.Rarities)
local Locations = require(SharedUtility.Locations)
local DiscoveryCard = require(script.DiscoveryCard)

-- Objects
local Frame = script.Frame

local DiscoveryContainer = {}
DiscoveryContainer.__index = DiscoveryContainer

function DiscoveryContainer.new(
	parent,
	location, 
	rarities, 
	playerMaterials
)
	local frame = Frame:Clone()
	frame.Parent = parent
	
	local locationName, textColor, frameColor = unpack(Locations.getLocationData(location))
	
	local colorFrame = frame.ColorFrame
	colorFrame.UIGradient.Color = frameColor
	local title = colorFrame.Title
	title.Text = string.format('"%s" Materials:', locationName)
	title.UIGradient.Color = textColor
	
	local self = {
		frame = frame,
		discovered = 0,
		discoverable = 0,
		list = {}
	}
	setmetatable(self, DiscoveryContainer)
	
	local height = self:initialize(rarities, playerMaterials)
	
	return self, height
end

function DiscoveryContainer:initialize(rarities, playerMaterials)
	local displayFrame = self.frame.DisplayFrame
	local count = 0
	
	for rarity, materials in pairs(rarities) do
		local rarityString = Rarities.getRarity(rarity)
		local colors = Colors.getRarityColor(rarityString)
		
		for _, material in pairs(materials) do
			local discoveryCard = DiscoveryCard.new(displayFrame, rarityString, colors)
			if playerMaterials[material] then
				discoveryCard:setContent(material)
				self.discovered += 1
			end
			self.list[material] = discoveryCard
			
			count += 1
		end
	end

	self.discoverable = count
	self:setDiscovered()
	
	local frameHeight = 60 * math.ceil(count / 7)
	self.frame.DisplayFrame.Size = UDim2.new(1, 0, 0, frameHeight)
	
	local height = frameHeight + 29
	self.frame.Size = UDim2.new(1, 0, 0, height)
	
	return height;
end

function DiscoveryContainer:setDiscovered()
	self.frame.ColorFrame.Ratio.Text = string.format("%d/%d Discovered", self.discovered, self.discoverable)
end

function DiscoveryContainer:update(name)
	self.list[name]:setContent(name)
	
	self.discovered += 1
	self:setDiscovered()
end

return DiscoveryContainer
