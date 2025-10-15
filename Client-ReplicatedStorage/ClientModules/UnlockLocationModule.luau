-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage.Remotes
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local Utility = HelperModules.Utility
local GuiComponents = HelperModules.GuiComponents
local SummaryCards = GuiComponents.SummaryCards

-- Modules
local Stack = require(HelperModules.Stack)
local ConfirmationPrompt = require(HelperModules.ConfirmationPrompt)
local LocationData = require(SharedUtility.LocationData)
local GuiSkeleton = require(GuiComponents.GuiSkeleton)
local RequirementSummaryCard = require(SummaryCards.RequirementSummaryCard)
local LoadImage = require(Utility.LoadImage)

-- Remotes
local Upgrade = Remotes.Upgrade

-- Objects
local Content = script.Content

local UnlockLocationModule = {}
UnlockLocationModule.__index = UnlockLocationModule

function UnlockLocationModule.new(
	unlockedLocations,
	inventory
)
	local guiSkeleton, gui = GuiSkeleton.new()
	local Frame = gui.Frame

	for _, child in Content:GetChildren() do
		child:Clone()
		child.Parent = Frame
	end

	local CostFrame = Frame.CostFrame
	local ImageLabel = Frame.ImageLabel
	local Description = Frame.Description
	
	local requirementSummaryCard = RequirementSummaryCard.new(
		CostFrame,
		1,
		Vector2.new(0.5,0.5),
		UDim2.new(0.5,0,0.5,0),
		255,
		120,
		{"Glimmer", "Awaiting", "Enlarging"}
	)
	
	local self = {
		transitioning = false, -- Debounce if an action is made by the user while some transition is occuring (updating cards, etc.)
		previousEnabled = nil,
		
		unlockedLocations = unlockedLocations,
		inventory = inventory.Materials,
		
		guiSkeleton = guiSkeleton,
		CostFrame = CostFrame,
		ImageLabel = ImageLabel,
		Description = Description,
		requirementSummaryCard = requirementSummaryCard
	}
	setmetatable(self, UnlockLocationModule)
	
	return self
end

function UnlockLocationModule:setUnlockedLocations(location: number)
	self.unlockedLocations = location
end

function UnlockLocationModule:enableLocation(location: number)
	if self.transitioning then
		return
	end
	self.transitioning = true
	
	local locationData = LocationData.getData(location)
	-- Display the location data, otherwise update the gui to display that new locations are coming soon
	if locationData and locationData.Cost and self.previousEnabled ~= location and self.unlockedLocations < location then
		self.previousEnabled = location
		self.guiSkeleton:setContent(string.format(`Unlock "%s"!`, locationData.Name), "GoldLock")
		
		self.Description.Text = "Discover better materials, stronger relics and tools, and more!"
		
		self.requirementSummaryCard:setContent(
			self.inventory,
			locationData.Cost,
			"Unlock cost",
			"Unlock",
			function(button)
				self:unlockCallback(button)
			end
		)
		self.requirementSummaryCard:enable()
		
		self.ImageLabel.Image = LoadImage(locationData.Name)
	else
		self.guiSkeleton:setContent("New locations are coming!", "GoldLock")
		self.Description.Text = "Please like, favorite and share the game for more updates! Thanks!"
		
		self.ImageLabel.Image = ""
	end
	
	self.transitioning = false
end

function UnlockLocationModule:disableLocation()
	self.transitioning = true

	self.previousEnabled = nil
	self.requirementSummaryCard:disable()
	
	self.transitioning = false
end

function UnlockLocationModule:enable(location: number)
	if self.transitioning then
		return
	end

	self:enableLocation(location)
	self.guiSkeleton:enable(function()
		self:disable()
	end)

	Stack.push(self, location)
end

function UnlockLocationModule:disable()
	if self.transitioning then
		return
	end

	self:disableLocation()
	self.guiSkeleton:disable()

	Stack.pop()

	-- Return true so the stack can proceed with disabling other items in the stack
	return true
end

function UnlockLocationModule:sleep()
	self.guiSkeleton:sleep()
end


function UnlockLocationModule:unsleep()
	self.guiSkeleton:unsleep()
end

function UnlockLocationModule:onResize(scale)
	self.guiSkeleton:onResize(scale)
	
	self.requirementSummaryCard:onResize(scale)
end

---- CALLBACK FUNCTIONS ----
	function UnlockLocationModule:unlockCallback(button)
		if not button:getAwaiting() and self.previousEnabled then
			local location = self.previousEnabled
			ConfirmationPrompt.enable(
				"Would you like to unlock this location?",
				function()
					local firedTimestamp = workspace:GetServerTimeNow()
					button:enableAwaiting(Upgrade, firedTimestamp)
					Upgrade:FireServer(firedTimestamp, "Location", location)
				end
			)
		end
	end

return UnlockLocationModule