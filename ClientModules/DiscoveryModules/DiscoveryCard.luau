-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local Utility = HelperModules.Utility

-- Modules
local LoadImage = require(Utility.LoadImage)

-- Objects
local Frame = script.Frame

local DiscoveryCard = {}
DiscoveryCard.__index = DiscoveryCard

function DiscoveryCard.new(
	parent,
	rarity,
	colors
)
	local frame = Frame:Clone()
	frame.Parent = parent
	
	local self = {
		frame = frame
	}
	setmetatable(self, DiscoveryCard)
	
	self:initialize(rarity, colors)
	
	return self
end

function DiscoveryCard:setContent(name)
	self.frame.ItemName.Text = name
	self.frame.ItemImage.Image = LoadImage(name)
end

function DiscoveryCard:initialize(rarity, colors)
	local Particles = self.frame.Particles
	for _, particle in Particles:GetChildren() do
		if particle.Name == "Particle" then
			particle.ImageColor3 = colors.Static
		end
	end
	
	local Rarity = self.frame.Rarity
	Rarity.Text = rarity
	Rarity.UIGradient.Color = colors.Gradient
end

return DiscoveryCard
