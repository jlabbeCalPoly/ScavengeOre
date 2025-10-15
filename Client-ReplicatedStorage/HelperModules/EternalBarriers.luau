--[[
	Set up the eternal barriers for each of the eternal locations the player has yet to unlock
]]

-- Folders
local HelperModules = script.Parent
local SharedUtility = HelperModules.SharedUtility

-- Modules
local EternalLocationData = require(SharedUtility.EternalLocationData)

-- Objects
local Barrier = script.Barrier

local EternalBarriers = {}

local instanceTracker = {}

--[[
	Roblox serializes negative nums to a string, so make sure we're comparing those values
]]
function EternalBarriers.createBarriers(unlockedLocations)
	for index, locationData in pairs(EternalLocationData.getAllData()) do
		local stringIndex = tostring(index)
		if not unlockedLocations[stringIndex] then
			local barrier = Barrier:Clone()
			
			barrier:SetAttribute("Specification", index)
			barrier:PivotTo(locationData.CFrame)
			barrier.Parent = workspace
			
			instanceTracker[index] = barrier
		end
	end
end

function EternalBarriers.destroyBarrier(location: number)
	local barrier = instanceTracker[location]
	local promptPart
	
	if barrier then
		promptPart = barrier.PrimaryPart
		
		-- Search for the proximityPrompt
		local proxPrompt = promptPart:FindFirstChild("InteractProxPrompt")
		if proxPrompt then
			proxPrompt.Parent = nil
		end
		
		barrier:Destroy()
		instanceTracker[location] = nil
	end
	
	return promptPart
end

return EternalBarriers