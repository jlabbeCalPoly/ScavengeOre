-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local GuiComponents = HelperModules.GuiComponents
local GuiParticles = GuiComponents.GuiParticles
local SharedUtility = HelperModules.SharedUtility

-- Modules
local Colors = require(HelperModules.Colors)
local AutoCenter = require(GuiComponents.AutoCenter)
local GlintGuiParticles = require(GuiParticles.GlintGuiParticles)
local Rarities = require(SharedUtility.Rarities)
local Constants = require(SharedUtility.Constants)

-- Objects
local Frame = script.Frame

local MysteryMaterialModule = {}
MysteryMaterialModule.__index = MysteryMaterialModule

function MysteryMaterialModule.new(
	parent
)
	local frame = Frame:Clone()
	frame.Parent = parent
	
	local autoCenter = AutoCenter.new(
		frame,
		Vector2.new(0.5, 1),
		UDim2.new(0.5,0,1,0),
		UDim2.new(0,300,0,25),
		300,
		25
	)
	
	local glintGuiParticles = GlintGuiParticles.new(
		frame.GlintFrame
	)
	
	local self = {
		frame = frame,
		autoCenter = autoCenter,
		glintGuiParticles = glintGuiParticles,
		lastRarity = nil
	}
	setmetatable(self, MysteryMaterialModule)
	
	return self
end

function MysteryMaterialModule:onRarityChange(rarity)
	local rarityString = Rarities.getRarity(rarity)
	local colors = Colors.getRarityColor(rarityString)
	
	self.frame.BarFrame.ProgressBar.BackgroundColor3 = colors.Static
	local image
	if rarity == 5 then
		image = "Sunstone Vein"
	else
		image = "Bloodstone Chunk"
	end
	self.autoCenter:setImage(image, colors.Static)
	self.autoCenter:setGradient(colors.Gradient, 15)
	self.autoCenter:setValue("Mystery "..rarityString, nil, string.format(`<i>%s %s</i>`, "Guaranteed" , rarityString.."!"))
	
	self.glintGuiParticles:disable()
	self.glintGuiParticles:setColors({colors.Static})
	self.glintGuiParticles:enable()
end

function MysteryMaterialModule:setContent(breakDetails)
	local breaks, rarity = unpack(breakDetails)
	
	local barFrame = self.frame.BarFrame
	barFrame.ProgressBar.Size = UDim2.new(breaks/100, 0, 1, 0)
	barFrame.Progress.Text = string.format(Constants.RATIO_STRING_FORMAT, breaks, 100)

	if rarity ~= self.lastRarity then
		self.lastRarity = rarity
		self:onRarityChange(rarity)
	end
end

return MysteryMaterialModule