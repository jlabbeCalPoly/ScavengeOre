-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local Utility = HelperModules.Utility

-- Modules
local Colors = require(HelperModules.Colors)
local Constants = require(SharedUtility.Constants)
local Rarities = require(SharedUtility.Rarities)
local ChangeListItem = require(script.ChangeListItem)
local LoadImage = require(Utility.LoadImage)
local ConvertToNumAbbr = require(Utility.ConvertToNumAbbr)

-- Objects
local Frame = script.Frame

local ChangeListModule = {}
ChangeListModule.__index = ChangeListModule

function ChangeListModule.new(
	parent,
	settings
)
	local frame = Frame:Clone()
	frame.Parent = parent
	
	local self = {
		frame = frame,
		settings = settings
	}
	setmetatable(self, ChangeListModule)
	
	return self
end

function ChangeListModule:addItems(list)
	-- Determine if the player has the resource log turned on or off
	if self.settings[7][2] then
		for _, info in pairs(list) do
			local prefix, color
			if info.QuantityChanged > 0 then
				prefix = "+"
				color = Constants.GREEN_COLOR
			else
				prefix = ""
				color = Constants.RED_COLOR
			end

			local particleColor
			if info.Rarity then
				particleColor = Colors.getRarityColor(Rarities.getRarity(info.Rarity)).Static
			end

			ChangeListItem.new(
				self.frame,
				info.Name,
				LoadImage(info.Name),
				prefix..ConvertToNumAbbr(info.QuantityChanged),
				color,
				particleColor
			)
			task.wait(0.1)
		end
	end
end

return ChangeListModule