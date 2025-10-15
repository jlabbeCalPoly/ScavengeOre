-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage.HelperModules.Utility

-- Modules
local ConvertToNumAbbr = require(Utility.ConvertToNumAbbr)

local LeaderstatsHandler = {}

local instanceTracker = {}

-- Set up the initial leaderstats for the player
function LeaderstatsHandler.onPlayerAdded(player, cashValue, amplifiedVouchersValue, powerValue)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local power = Instance.new("StringValue")
	power.Name = "Power"
	power.Value = ConvertToNumAbbr(powerValue)
	power.Parent = leaderstats

	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Value = ConvertToNumAbbr(cashValue)
	cash.Parent = leaderstats
	
	local amplifiedVouchers = Instance.new("StringValue")
	amplifiedVouchers.Name = "Amplified Vouchers"
	amplifiedVouchers.Value = ConvertToNumAbbr(amplifiedVouchersValue)
	amplifiedVouchers.Parent = leaderstats

	instanceTracker[player.UserId] = {
		["Cash"] = cash,
		["AmplifiedVouchers"] = amplifiedVouchers,
		["Power"] = {power, powerValue}
	}
end

function LeaderstatsHandler.updateCash(player, value)
	local data = instanceTracker[player.UserId]
	if data then
		data.Cash.Value = ConvertToNumAbbr(value)
	end
end

function LeaderstatsHandler.updateAmplifiedVouchers(player, value)
	local data = instanceTracker[player.UserId]
	if data then
		data.AmplifiedVouchers.Value = ConvertToNumAbbr(value)
	end
end

function LeaderstatsHandler.updatePower(player, value)
	local data = instanceTracker[player.UserId]
	if data then
		data.Power[2] += value
		data.Power[1].Value = ConvertToNumAbbr(data.Power[2])
	end
end

function LeaderstatsHandler.onPlayerRemoving(player)
	local data = instanceTracker[player.UserId]
	if data then
		data.Cash:Destroy()
		data.AmplifiedVouchers:Destroy()
		data.Power[1]:Destroy()
		instanceTracker[player.UserId] = nil
	end
end

return LeaderstatsHandler