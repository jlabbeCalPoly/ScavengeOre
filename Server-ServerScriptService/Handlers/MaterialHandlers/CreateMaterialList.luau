-- Format the material list to be appropriately passed back to the client

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local Materials = require(SharedUtility.Materials)

function CreateMaterialList(list)
	local materials = {}
	
	for _, itemDetails in pairs(list) do
		local name, quantityChanged = unpack(itemDetails)
		local rarity = Materials.getMaterialRarity(name)
		
		table.insert(
			materials,
			{
				["Name"] = name,
				["Rarity"] = rarity,
				["QuantityChanged"] = quantityChanged
			}
		)
	end
	
	return materials
end

return CreateMaterialList