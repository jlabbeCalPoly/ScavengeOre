--[[
	Function that generates a list of materials, sorted by rarity, based on the given luck and locations
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local SharedUtility = ReplicatedStorage.HelperModules.SharedUtility

-- Modules
local Materials = require(SharedUtility.Materials)
local Rarities = require(SharedUtility.Rarities)
local Entities = require(SharedUtility.Entities)
local MergeSort = require(SharedUtility.MergeSort)

-- Objects
local RNG = Random.new()

--[[
	Determine the rarity that the rarityPercent falls into based on a provided list of luckValues
]]
local function GenerateRarity(rarityPercent, luckValues, location)
	local rarity = 1
	local partitionOffset = 0
	local rarities = Rarities.getAllRarityTypes(location)
	
	for index, value in pairs(rarities) do
		partitionOffset += luckValues[value]
		if rarityPercent <= partitionOffset then
			rarity = index
			break
		end
		index += 1
	end
	
	return rarity
end

--[[
	Generate a list of materials, sorted by rarity, to pass to the player
]]
function GenerateMaterialList(entity: string,
							  luck: number,
							  locations: { number },
							  count: number,
							  guaranteedUltraRare: number,
							  breaks)
	local luckValues = Entities.calculateLuck(entity, luck)
	local materialsKeyValue = {}
	local breakData
	
	local function GenerateMaterial(location, rarity)
		-- get the material list based on the location and rarity,
		-- then randomly select a material
		local materialList = Materials.getMaterialData(location, rarity)
		local material = materialList[math.random(1, #materialList)]

		-- Will be passed back up to main handler and have a "Quantity" key set as well,
		-- representing the total amount of specific material that player has
		if materialsKeyValue[material] then
			materialsKeyValue[material].QuantityChanged += 1
		else
			materialsKeyValue[material] = 
				{
					["Name"] = material,
					["Rarity"] = rarity,
					["QuantityChanged"] = 1,
				}
		end
	end
	
	if count > 0 then
		if breaks then
			local breaks, rarity = unpack(breaks)
			local totalBreaks = breaks + 1
			if totalBreaks == 100 then
				totalBreaks = 0

				GenerateMaterial(locations[#locations], rarity)

				if rarity == 5 then
					rarity = 6
				else
					rarity = 5
				end

				count -= 1
			end
			breakData = {totalBreaks, rarity}
		end

		while count > 0 do
			-- calculate the rarity percent value and the corresponding rarity
			local rarityPercent = RNG:NextNumber(0, 100)

			-- randomly select a location to select material from (helpful 
			-- in the event there are more than one location to choose from)
			local location = locations[math.random(1, #locations)]
			
			local rarity
			
			if guaranteedUltraRare > 0 then
				rarity = GenerateRarity(rarityPercent, Entities.calculateLuck(entity, luck * 4), location)
				
				if rarity < 4 then
					rarity = 4
				end
				
				guaranteedUltraRare -= 1
			else
				rarity = GenerateRarity(rarityPercent, luckValues, location)
			end
			
			GenerateMaterial(location, rarity)
			
			count -= 1
		end
	end
	
	local materials = {}
	for _, materialData in pairs(materialsKeyValue) do
		table.insert(
			materials,
			materialData
		)
	end

	-- Sort the list of materials in descending order based on rarity
	if #materials > 1 then
		materials = MergeSort(materials, {"Rarity"})
	end

	return materials, breakData
end

return GenerateMaterialList