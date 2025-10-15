-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage.Remotes
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local GuiComponents = HelperModules.GuiComponents
local SummaryCards = GuiComponents.SummaryCards

-- Modules
local Stack = require(HelperModules.Stack)
local ConfirmationPrompt = require(HelperModules.ConfirmationPrompt)
local EternalLocationData = require(SharedUtility.EternalLocationData)
local GuiSkeleton = require(GuiComponents.GuiSkeleton)
local RequirementSummaryCard = require(SummaryCards.RequirementSummaryCard)

-- Remotes
local Upgrade = Remotes.Upgrade

-- Objects
local Content = script.Content

local UnlockGateModule = {}
UnlockGateModule.__index = UnlockGateModule

function UnlockGateModule.new(
	playerData
)
	local guiSkeleton, gui = GuiSkeleton.new()
	guiSkeleton:setContent("Unlock gate!", "RedLock")
	local frame = gui.Frame

	for _, child in Content:GetChildren() do
		child:Clone()
		child.Parent = frame
	end
	
	local CostFrame = frame.CostFrame
	
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
		previousEnabled = nil, -- Keep track of the unlock zone that was enabled previously, if any
		
		guiSkeleton = guiSkeleton,
		requirementSummaryCard = requirementSummaryCard,
		
		unlockedEternalZones = playerData["LevelStats"]["UnlockedEternalZones"],
		inventory = playerData["Inventory"]["Materials"]
	}
	setmetatable(self, UnlockGateModule)
	
	return self
end

function UnlockGateModule:enableGate(gate: number)
	if self.transitioning then
		return
	end
	self.transitioning = true
	
	if self.previousEnabled ~= gate and not self.unlockedEternalZones[gate] then
		self.previousEnabled = gate
		
		local locationData = EternalLocationData.getData(gate)
		
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
	end
	
	self.transitioning = false
end

function UnlockGateModule:disableGate()
	self.transitioning = true

	self.previousEnabled = nil
	self.requirementSummaryCard:disable()

	self.transitioning = false
end

function UnlockGateModule:enable(gate: number)
	if self.transitioning then
		return
	end

	self:enableGate(gate)
	self.guiSkeleton:enable(function()
		self:disable()
	end)

	Stack.push(self, gate)
end

function UnlockGateModule:disable()
	if self.transitioning then
		return
	end

	self:disableGate()
	self.guiSkeleton:disable()

	Stack.pop()

	-- Return true so the stack can proceed with disabling other items in the stack
	return true
end

function UnlockGateModule:onResize(scale)
	self.guiSkeleton:onResize(scale)
	
	self.requirementSummaryCard:onResize(scale)
end

function UnlockGateModule:onInventoryUpdate()
	if self.previousEnabled and not self.transitioning then
		self.transitioning = true

		local locationData = EternalLocationData.getData(self.previousEnabled)
		if locationData then
			self.requirementSummaryCard:updateContent(self.inventory, locationData.Cost)
		end

		self.transitioning = false
	end
end

function UnlockGateModule:setUnlockedGates(gate: number)
	self.unlockedEternalZones[gate] = true
end

---- CALLBACKS ----
function UnlockGateModule:unlockCallback(button)
	if not button:getAwaiting() and self.previousEnabled then
		local gate = self.previousEnabled
		ConfirmationPrompt.enable(
			"Would you like to unlock this gate?",
			function()
				local firedTimestamp = workspace:GetServerTimeNow()
				button:enableAwaiting(Upgrade, firedTimestamp)
				Upgrade:FireServer(firedTimestamp, "Gate", gate)
			end
		)
	end
end

return UnlockGateModule