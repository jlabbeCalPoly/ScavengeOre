-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local GuiComponents = HelperModules.GuiComponents
local SharedUtility = HelperModules.SharedUtility
local Utility = HelperModules.Utility

-- Modules
local SFXModule = require(HelperModules.SFXModule)
local CapacityCard = require(GuiComponents.CapacityCard)
local CashChangeVFX = require(script.CashChangeVFX)
local Constants = require(SharedUtility.Constants)
local ConvertToNumAbbr = require(Utility.ConvertToNumAbbr)

local CashManagerModule = {}
CashManagerModule.__index = CashManagerModule

--[[
	Cash is temporarily stored in the materials inventory to be used in requirementSummaryCards, 
	and the value is displayed in the CapacityCard
]]
function CashManagerModule.new(
	parent, 
	playerData
)
	local capacityCard = CapacityCard.new(
		parent,
		Vector2.new(0,1),
		UDim2.new(0,0,0.5,-105),
		130,
		25,
		"Cash"
	)
	
	local CashChangeVFX = CashChangeVFX.new(capacityCard:getFrame())
	
	local self = {
		capacityCard = capacityCard,
		CashChangeVFX = CashChangeVFX,
		inventory = playerData["Inventory"],
		materialInventory = playerData["Inventory"]["Materials"]
	}
	setmetatable(self, CashManagerModule)
	
	self:setValue(playerData["Inventory"]["Cash"], nil)
	self:initialize()
	
	return self
end

function CashManagerModule:setValue(remainingCash: number, cashChange: number)
	self.materialInventory["Cash"] = {
		["Quantity"] = remainingCash
	}
	self.inventory["Cash"] = remainingCash
	
	self.capacityCard:setContent(ConvertToNumAbbr(remainingCash, "Cash"))
	
	if cashChange then
		local cashString = ConvertToNumAbbr(math.abs(cashChange), "Cash")
		local color, prefix
		if cashChange >= 0 then
			prefix = "+"
			color = Constants.GREEN_COLOR
			SFXModule.playSound("Cash")
		else
			prefix = "-"
			color = Constants.RED_COLOR
		end
		
		self.CashChangeVFX:play(prefix..cashString, color)
	end
end

function CashManagerModule:setEnableGuiCallback(callback)
	self.callback = callback
end

function CashManagerModule:initialize()
	self.capacityCard:setColor(Constants.UNCOMMON_COLOR_BASE, Constants.BLACK_COLOR)
	self.capacityCard:enable(
		"Cash",
		function(name)
			if self.callback then
				self.callback(name)
			end
		end
	)
end

return CashManagerModule