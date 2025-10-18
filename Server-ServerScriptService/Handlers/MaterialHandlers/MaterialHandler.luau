--[[
	Determine the materials to grant to the player
]]

-- Modules
local validateArguments = require(script.ValidateArguments)
local ValidateTypes = require(script.ValidateTypes)
local GenerateMaterialList = require(script.GenerateMaterialList)
local GeneratePaidMaterialList = require(script.GeneratePaidMaterialList)
local GenerateTutorialMaterialList = require(script.GenerateTutorialMaterialList)
local GetEntityLocation = require(script.GetEntityLocation)
local CreateMaterialList = require(script.CreateMaterialList)

local MaterialModule = {}

-- Validate the specific values received by the client
function MaterialModule.validateArguments(timeStamp: number,
									      entityName: string,
										  unlockedLocations: number)
	return validateArguments(timeStamp, entityName, unlockedLocations)
end

-- Validate the types of the values received by the client
function MaterialModule.validateTypes(player: Player,
									  timeStamp: number,
									  entity: Model)
	return ValidateTypes(player, timeStamp, entity)
end

--[[
	Generate a list of materials, based on the entity, player's luck and the specified location(s) to pull from
	Additionally, pass in the number of materials to generate
]]
function MaterialModule.generateMaterialList(entityName: string,
											 luck: number,
											 locations: { number },
											 count: number,
										     guaranteedUltraRare: number,
											 breaks)
	return GenerateMaterialList(entityName, luck, locations, count, guaranteedUltraRare, breaks)
end
											
function MaterialModule.generateTutorialMaterialList(count, breaks)
	return GenerateTutorialMaterialList(count, breaks)
end
	
--[[
	Generate a list of materials based on a pre-decided quantity of each rarity (listed in descending order)
]]
function MaterialModule.generatePaidMaterialList(list, location, rarityOverride)
	return GeneratePaidMaterialList(list, location, rarityOverride)
end											

--[[
	Create a premade material list based on the materials provided
]]
function MaterialModule.createMaterialList(list)
	return CreateMaterialList(list)
end
											
function MaterialModule.getEntityLocation(entityName: string)
	return GetEntityLocation(entityName)
end

return MaterialModule