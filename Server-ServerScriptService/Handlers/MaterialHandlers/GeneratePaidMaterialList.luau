-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local SharedUtility = ReplicatedStorage.HelperModules.SharedUtility

-- Modules
local Materials = require(SharedUtility.Materials)
local MergeSort = require(SharedUtility.MergeSort)

function GeneratePaidMaterialList(list, location, rarityOverride)
	local materialsKeyValue = {}
	
	local rarity
	local count = 0
	if not rarityOverride then
		-- All locations past location 3 will have "Eternal" materials
		if location > 3 then
			rarity = 7
		else
			rarity = 6
		end
	else
		rarity = rarityOverride
	end
	
	for _, quantity in pairs(list) do
		local materialList = Materials.getMaterialData(location, rarity)
		
		-- Generate the specified amount of materials for that rarity
		for index = 1, quantity do
			local material = materialList[math.random(1, #materialList)]
			
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
			
			count += 1
		end
		
		rarity -= 1
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

	return materials, count
end

return GeneratePaidMaterialList