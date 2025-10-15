-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local GuiComponents = HelperModules.GuiComponents
local SharedUtility = HelperModules.SharedUtility
local Utility = HelperModules.Utility

-- Modules
local CapacityCard = require(GuiComponents.CapacityCard)
local Constants = require(SharedUtility.Constants)
local StorageData = require(SharedUtility.StorageData)
local ConvertToNumAbbr = require(Utility.ConvertToNumAbbr)

local MaterialManagerModule = {}
MaterialManagerModule.__index = MaterialManagerModule

function MaterialManagerModule.new(
	parent,
	playerData
)
	local capacityCard = CapacityCard.new(
		parent,
		Vector2.new(0,1),
		UDim2.new(0,0,0.5,-135),
		130,
		25,
		"Upgrade Storage"
	)
	
	local self = {
		inventory = playerData["Inventory"]["Materials"],
		capacityCard = capacityCard,
		leftVal = 0,
		rightVal = 0
	}
	setmetatable(self, MaterialManagerModule)
	
	self:setCapacity(playerData["Materials"], playerData["LevelStats"]["Storage"])
	self.capacityCard:enable(
		"Materials",
		function(name)
			if self.callback then
				self.callback(name)
			end
		end
	)
	
	return self
end

function MaterialManagerModule:updateInventory(materialList)
	for _, materialData in pairs(materialList) do
		if self.inventory[materialData.Name] then
			self.inventory[materialData.Name].Quantity = materialData.Quantity
		else
			self.inventory[materialData.Name] = {
				["Quantity"] = materialData.Quantity
			}
		end
	end
end

--[[
	Set the values of the capacity values if provided, then return the values in their updated format
]]
function MaterialManagerModule:setCapacity(leftVal, rightVal)
	if leftVal then
		self.leftVal += leftVal
	end
	if rightVal then
		self.rightVal = StorageData.getData(rightVal).Value
	end

	local color = Constants.WHITE_COLOR
	if self.leftVal >= self.rightVal then
		color = Constants.RED_COLOR
	end

	self.capacityCard:setContent(
		string.format(Constants.REQUIREMENT_STRING_FORMAT, ConvertToNumAbbr(self.leftVal), ConvertToNumAbbr(self.rightVal)),
		color		
	)
end

function MaterialManagerModule:setEnableGuiCallback(callback)
	self.callback = callback
end

return MaterialManagerModule