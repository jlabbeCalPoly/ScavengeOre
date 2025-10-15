local AmplifiedVouchersModule = {}
AmplifiedVouchersModule.__index = AmplifiedVouchersModule

--[[
	Amplified Vouchers are temporarily stored in the materials inventory to be used in requirementSummaryCards
]]
function AmplifiedVouchersModule.new(
	playerData
)
	local self = {
		inventory = playerData["Inventory"],
		materialInventory = playerData["Inventory"]["Materials"]
	}
	setmetatable(self, AmplifiedVouchersModule)
	
	self:setValue(playerData["Inventory"]["Amplified Voucher"], nil)
	
	return self
end

function AmplifiedVouchersModule:setValue(remainingAmplifiedVouchers: number)
	self.materialInventory["Amplified Voucher"] = {
		["Quantity"] = remainingAmplifiedVouchers
	}
	self.inventory["Amplified Voucher"] = remainingAmplifiedVouchers
end

return AmplifiedVouchersModule