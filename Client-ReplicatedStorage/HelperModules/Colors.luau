--[[
	Store the color data for each rarity
]]

-- Folders
local SharedUtility = script.Parent.SharedUtility

-- Modules
local Constants = require(SharedUtility.Constants)

local Colors = {}

--[[
	Contains the color values associated with different rarities.
	Each key contains two values, a static color and a gradient value
]]
local rarityColors = {
	["Common"] = {
		["Static"] = Constants.COMMON_COLOR_BASE,
		["Gradient"] = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Constants.COMMON_COLOR_BASE),
			ColorSequenceKeypoint.new(0.5, Constants.COMMON_COLOR_DARK),
			ColorSequenceKeypoint.new(1, Constants.COMMON_COLOR_BASE)
		}
	},
	["Uncommon"] = {
		["Static"] = Constants.UNCOMMON_COLOR_BASE,
		["Gradient"] = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Constants.UNCOMMON_COLOR_BASE),
			ColorSequenceKeypoint.new(0.5, Constants.UNCOMMON_COLOR_DARK),
			ColorSequenceKeypoint.new(1, Constants.UNCOMMON_COLOR_BASE)
		}
	},
	["Rare"] = {
		["Static"] = Constants.RARE_COLOR_BASE,
		["Gradient"] = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Constants.RARE_COLOR_BASE),
			ColorSequenceKeypoint.new(0.5, Constants.RARE_COLOR_DARK),
			ColorSequenceKeypoint.new(1, Constants.RARE_COLOR_BASE)
		}
	},
	["Ultra Rare"] = {
		["Static"] = Constants.ULTRA_RARE_COLOR_BASE,
		["Gradient"] = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Constants.ULTRA_RARE_COLOR_BASE),
			ColorSequenceKeypoint.new(0.5, Constants.ULTRA_RARE_COLOR_DARK),
			ColorSequenceKeypoint.new(1, Constants.ULTRA_RARE_COLOR_BASE)
		}
	},
	["Legendary"] = {
		["Static"] = Constants.LEGENDARY_COLOR_BASE,
		["Gradient"] = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Constants.LEGENDARY_COLOR_BASE),
			ColorSequenceKeypoint.new(0.5, Constants.LEGENDARY_COLOR_DARK),
			ColorSequenceKeypoint.new(1, Constants.LEGENDARY_COLOR_BASE)
		}
	},
	["Fabled"] = {
		["Static"] = Constants.FABLED_COLOR_BASE,
		["Gradient"] = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Constants.FABLED_COLOR_BASE),
			ColorSequenceKeypoint.new(0.5, Constants.FABLED_COLOR_DARK),
			ColorSequenceKeypoint.new(1, Constants.FABLED_COLOR_BASE)
		}
	},
	["Eternal"] = {
		["Static"] = Constants.ETERNAL_COLOR_PINK,
		["Gradient"] = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Constants.ETERNAL_COLOR_YELLOW),
			ColorSequenceKeypoint.new(0.25, Constants.ETERNAL_COLOR_PINK),
			ColorSequenceKeypoint.new(0.5, Constants.ETERNAL_COLOR_PURPLE),
			ColorSequenceKeypoint.new(0.75, Constants.ETERNAL_COLOR_BLUE),
			ColorSequenceKeypoint.new(1, Constants.ETERNAL_COLOR_TEAL)
		}
	}
}

local relicColors = {
	["Normal"] = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Constants.WHITE_COLOR),
		ColorSequenceKeypoint.new(1, Constants.WHITE_COLOR)
	},
	["Special"] = rarityColors.Legendary.Gradient,
	["Eternal"] = rarityColors.Eternal.Gradient,
	["Amplified"] = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Constants.AMPLIFIED_COLOR),
		ColorSequenceKeypoint.new(1, Constants.AMPLIFIED_COLOR_DARK)
	}
}

local rarityByHex = {
	["Common"] = "#d2d6e1",
	["Uncommon"] = "#0df300",
	["Rare"] = "#39d2fc",
	["Ultra Rare"] = "#da51ff",
	["Legendary"] = "#ffee64",
	["Fabled"] = "#f34f52",
	["Eternal"] = "#fca9ff"
}

local boostColors = {
	["Power"] = {
		["Static"] = Constants.FABLED_COLOR_DARK,
		["Gradient"] = ColorSequence.new(Constants.FABLED_COLOR_DARK, Constants.FABLED_COLOR_BASE)
	},
	["Luck"] = {
		["Static"] = Constants.UNCOMMON_COLOR_BASE,
		["Gradient"] = ColorSequence.new(Constants.UNCOMMON_COLOR_DARK, Constants.UNCOMMON_COLOR_BASE)
	},
	["Speed"] = {
		["Static"] = Constants.ULTRA_RARE_COLOR_DARK,
		["Gradient"] = ColorSequence.new(Constants.ULTRA_RARE_COLOR_DARK, Constants.ULTRA_RARE_COLOR_BASE)
	}
}

--[[
	Get the color values associated with the rarity
]]
function Colors.getRarityColor(rarity)
	return rarityColors[rarity]
end

function Colors.getRelicColor(relicType: string)
	return relicColors[relicType]
end

function Colors.getHexColor(rarity)
	return rarityByHex[rarity]
end

function Colors.getBoostColors(boost)
	return boostColors[boost]
end

return Colors