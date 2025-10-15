--[[
	Set up the barriers for each of the locations the player has yet to unlock
]]

-- Folders
local HelperModules = script.Parent
local SharedUtility = HelperModules.SharedUtility

-- Modules
local LocationData = require(SharedUtility.LocationData)

-- Objects
local Barrier = script.Barrier

local Barriers = {}

local instanceTracker = {}

function Barriers.createBarriers(unlockedLocations: number)
	-- Start out by creating the barrier for the next unlockable location
	local barrierToCreate = unlockedLocations + 1
	local locationData = LocationData.getData(barrierToCreate)
	
	while locationData do
		local barrier = Barrier:Clone()
		
		if locationData.Name then
			barrier.Interact.Gui.ContainerFrame.Textlabel.Text = string.format('Unlock "%s"!', locationData.Name)
		else
			barrier.Interact.Gui.ContainerFrame.Textlabel.Text = "Coming soon..."
		end
		
		barrier:SetAttribute("Specification", barrierToCreate)
		barrier:PivotTo(locationData.CFrame)
		barrier.Parent = workspace
		
		instanceTracker[barrierToCreate] = barrier
		
		barrierToCreate += 1
		locationData = LocationData.getData(barrierToCreate)
	end
end

function Barriers.destroyBarrier(location: number)
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

return Barriers