--[[
	Determine the location of an entity. Returns the location of the entity or nil if it doesn't exist
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local SharedUtility = ReplicatedStorage.HelperModules.SharedUtility

-- Modules
local Entities = require(SharedUtility.Entities)

function GetEntityLocation(entityName)
	local validatedEntity = Entities.getEntity(entityName)
	if validatedEntity then
		validatedEntity = validatedEntity.Location
	end
	
	return validatedEntity
end

return GetEntityLocation