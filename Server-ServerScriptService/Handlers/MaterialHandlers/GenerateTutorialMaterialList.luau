-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local SharedUtility = ReplicatedStorage.HelperModules.SharedUtility

-- Modules
local Materials = require(SharedUtility.Materials)
local MergeSort = require(SharedUtility.MergeSort)

function GenerateTutorialMaterialList(count, breaks)
	local materialsKeyValue = {}
	local breakData

	if count > 0 then
		if breaks then
			local breaks, rarity = unpack(breaks)
			local totalBreaks = breaks + 1
			if totalBreaks == 100 then
				totalBreaks = 0

				if rarity == 5 then
					rarity = 6
				else
					rarity = 5
				end
			end
			
			while count > 0 do
				local materialName
				if breaks % 2 == 0 then
					materialName = "Hollow Gem"
				else
					materialName = "Mossrock Ore"
				end
				local materialInfo = Materials.getMaterialInfo(materialName)
				local rarity = materialInfo[2]
				
				if materialsKeyValue[materialName] then
					materialsKeyValue[materialName].QuantityChanged += 1
				else
					materialsKeyValue[materialName] = 
						{
							["Name"] = materialName,
							["Rarity"] = rarity,
							["QuantityChanged"] = 1,
						}
				end
				count -= 1
			end
			
			breakData = {totalBreaks, rarity}
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

return GenerateTutorialMaterialList