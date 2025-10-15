-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage.Remotes
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local GuiComponents = HelperModules.GuiComponents
local SummaryCards = GuiComponents.SummaryCards

-- Modules
local WeeklyData = require(SharedUtility.WeeklyData)
local MaterialPackData = require(SharedUtility.MaterialPackData)
local LoadingBar = require(GuiComponents.LoadingBar)
local TimelineCard = require(GuiComponents.TimelineCard)
local ClaimSummaryCard = require(SummaryCards.ClaimSummaryCard)
local PackSummaryCard = require(SummaryCards.PackSummaryCard)
local ConfirmationPrompt = require(HelperModules.ConfirmationPrompt)

-- Remotes
local Claim = Remotes.Claim

-- Objects
local Content = script.Content

local WeeklyRewards = {}
WeeklyRewards.__index = WeeklyRewards

function WeeklyRewards.new(
	parent,
	playerData
)
	for _, child in Content:GetChildren() do
		child:Clone()
		child.Parent = parent
	end

	local Description = parent.WeeklyDescription
	local DaySummaryFrame = parent.DaySummaryFrame
	local PackSummaryFrame = parent.PackSummaryFrame
	
	local weeklyData = playerData["WeeklyData"]
	
	local self = {
		enabled = false,
		transitioning = false,
		
		previousEnabled = nil, -- The previous (current) day data that's being displayed
		
		Description = Description,
		DaySummaryFrame = DaySummaryFrame,
		PackSummaryFrame = PackSummaryFrame,
		
		location = playerData["LevelStats"]["UnlockedLocations"],
		claimTime = weeklyData["ClaimTime"],
		day = weeklyData["Day"]
	}
	setmetatable(self, WeeklyRewards)
	
	self:initialize(parent)
	
	return self
end

function WeeklyRewards:onWeeklyClaim(claimTime: number, day: number)
	self.claimTime = claimTime + 86400
	self.day = day

	if self.enabled and self.previousEnabled and not self.transitioning then
		self.transitioning = true
		
		self:updateInfo(self.previousEnabled)
		self.timelineCard:setContent(self.day)
		self:startCountdown()
		
		self.transitioning = false
	end
end

function WeeklyRewards:onLocationUpgrade(location)
	self.location = location

	if self.enabled and self.previousEnabled and not self.transitioning then
		self.transitioning = true

		self:updateInfo(self.previousEnabled)
		
		self.transitioning = false
	end
end

function WeeklyRewards:updateInfo(index)
	self.previousEnabled = index
	local materialPackKey, data = WeeklyData.getDataClient(index, self.location)
	
	self.claimSummaryCard:disable()
	self.claimSummaryCard:setContent(
		string.format("Day %d Rewards!", index),
		data,
		"Claim",
		function(button)
			self:claimCallback(button)
		end
	)
	
	self.packSummaryCard:disable()
	
	local packContent = MaterialPackData.getMaterialPackLayoutData(materialPackKey, self.location)
	self.packSummaryCard:setContent(
		string.format("%s Material Pack", materialPackKey),
		packContent
	)
	self.packSummaryCard:enable()
	
	if index == self.day and (not self.claimTime or workspace:GetServerTimeNow() >= self.claimTime) then
		self.claimSummaryCard:setSatisfied(true)
	else
		self.claimSummaryCard:setSatisfied(false)
	end
	self.claimSummaryCard:enable()
end

function WeeklyRewards:startCountdown()
	local countdown = 0
	if self.claimTime then
		local tempCountdown = math.ceil(self.claimTime - workspace:GetServerTimeNow())
		if tempCountdown > 0 then
			countdown = tempCountdown
		end
	end
	
	self.loadingBar:disable()
	self.loadingBar:enable(
		nil,
		countdown,
		86400
	)
end

function WeeklyRewards:enable()
	if self.enabled or self.transitioning then	
		return
	end
	self.enabled = true
	self.transitioning = true
	
	self:updateInfo(self.day)
	
	self.timelineCard:enable(
		self.day
	)
	self:startCountdown()
	
	self.Description.Visible = true
	
	self.transitioning = false
end

function WeeklyRewards:disable()
	if not self.enabled or self.transitioning then
		return
	end
	self.enabled = false
	self.transitioning = true

	self.loadingBar:disable()
	self.timelineCard:disable()
	self.claimSummaryCard:disable()
	self.packSummaryCard:disable()

	self.Description.Visible = false
	self.previousEnabled = nil
	
	self.transitioning = false
end

function WeeklyRewards:initialize(parent)
	self.loadingBar = LoadingBar.new(
		parent,
		Vector2.new(0,0),
		UDim2.new(0.05,0,0,50),
		UDim2.new(0.9,0,0,15)
	)
	self.loadingBar:setup("Claim now!")
	self.loadingBar:setCompletionCallback(function()
		self:loadingBarCompletionCallback()
	end)
	
	self.timelineCard = TimelineCard.new(
		parent,
		Vector2.new(0.5,0),
		UDim2.new(0.5,0,0,67),
		UDim2.new(0,400,0,56),
		WeeklyData.getTimelineData()
	)
	self.timelineCard:setTimelineClickCallback(function(index)
		if self.transitioning or index == self.previousEnabled then
			return
		end
		self.transitioning = true
		
		self:updateInfo(index)
		
		self.transitioning = false
	end)
	
	self.claimSummaryCard = ClaimSummaryCard.new(
		self.DaySummaryFrame,
		1,
		Vector2.new(0.5,1),
		UDim2.new(0.5,0,1,0),
		255,
		50,
		{"Glimmer", "Awaiting", "Enlarging"}
	)
	
	self.packSummaryCard = PackSummaryCard.new(
		self.PackSummaryFrame,
		1,
		Vector2.new(0,0.5),
		UDim2.new(0,0,0.5,0),
		155,
		90
	)
end

function WeeklyRewards:loadingBarCompletionCallback()
	if self.enabled and self.day == self.previousEnabled and not self.transitioning then
		self.claimSummaryCard:setSatisfied(true)
	end
end

function WeeklyRewards:onResize(scale)
	self.claimSummaryCard:onResize(scale)
	self.packSummaryCard:onResize(scale)
end

---- CALLBACKS ----
function WeeklyRewards:claimCallback(button)
	if not button:getAwaiting() then
		ConfirmationPrompt.enable(
			string.format("Would you like to claim the reward for Day %d?", self.day),
			function()
				local firedTimestamp = workspace:GetServerTimeNow()
				button:enableAwaiting(Claim, firedTimestamp)
				Claim:FireServer(firedTimestamp, "Weekly")
			end
		)
	end
end

return WeeklyRewards