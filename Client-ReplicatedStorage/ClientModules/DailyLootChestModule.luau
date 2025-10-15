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
local Constants = require(SharedUtility.Constants)
local DailyLootChestData = require(SharedUtility.DailyLootChestData)
local GuiSkeleton = require(GuiComponents.GuiSkeleton)
local LoadingBar = require(GuiComponents.LoadingBar)
local MovingIcon = require(GuiComponents.MovingIcon)
local ClaimSummaryCard = require(SummaryCards.ClaimSummaryCard)

-- Remotes
local Claim = Remotes.Claim

-- Objects
local Content = script.Content
local DailyLootChest = script.DailyLootChest

local DailyLootChestModule = {}
DailyLootChestModule.__index = DailyLootChestModule

function DailyLootChestModule.new(
	playerData
)
	local guiSkeleton, gui = GuiSkeleton.new()
	guiSkeleton:setContent("Daily Loot Chest!", "DailyLootChest")
	local frame = gui.Frame

	for _, child in Content:GetChildren() do
		child:Clone()
		child.Parent = frame
	end
	
	local chanceFrame = frame.ChanceFrame
	local imageFrame = frame.ImageFrame
	
	local movingIcon = MovingIcon.new(
		imageFrame,
		"DailyLootChest",
		"Rare"
	)
	local claimSummaryCard = ClaimSummaryCard.new(
		chanceFrame,
		1,
		Vector2.new(0.5,0.5),
		UDim2.new(0.5,0,0.5,0),
		255,
		85,
		{"Glimmer", "Awaiting", "Enlarging"}
	)
	local loadingBar = LoadingBar.new(
		frame,
		Vector2.new(0,0),
		UDim2.new(0.05,0,0,50),
		UDim2.new(0.9,0,0,15),
		true
	)
	
	local dailyLootChest = DailyLootChest:Clone()
	local countdownLabel = dailyLootChest.Interact.Gui.ContainerFrame.Countdown
	
	local self = {
		enabled = false,
		transitioning = false,
		satisfied = false,
		
		guiSkeleton = guiSkeleton,
		movingIcon = movingIcon,
		loadingBar = loadingBar,
		claimSummaryCard = claimSummaryCard,
		dailyLootChest = dailyLootChest,
		countdownLabel = countdownLabel,
		unlockedLocations = playerData["LevelStats"]["UnlockedLocations"]
	}
	setmetatable(self, DailyLootChestModule)
	
	return self
end

function DailyLootChestModule:updateCountdownLabel(remainingTime: number)
	local offset = 0
	
	while remainingTime > 0 do
		-- If the remaining time is over an hour, use the HOUR_STRING_FORMAT
		local message
		
		if remainingTime > 3600 then
			local hours = math.floor(remainingTime/3600)
			
			local remainder = remainingTime % 3600
			local mins = math.floor(remainder / 60)
			local secs = remainder % 60
			message = string.format(Constants.HOURS_STRING_FORMAT, hours, mins, secs)
		else
			local mins = math.floor(remainingTime / 60)
			local secs = remainingTime % 60
			message = string.format(Constants.MINS_STRING_FORMAT, mins, secs)
		end
		
		self.message = message
		self.countdownLabel.Text = message
		
		-- Pass this information to the loadingBar to sync changes
		self.loadingBar:setContent(message, remainingTime)
		
		remainingTime -= 1;
		local waited = task.wait(1 + offset)
		offset += (1 - waited)
	end
	
	self.message = self.completionText
	self.countdownLabel.Text = self.message
	self.loadingBar:setContent(self.completionText, remainingTime)
	
	self.claimSummaryCard:setSatisfied(true)
end

--[[
	Update the chest's location based on the location the player has 
]]
function DailyLootChestModule:updateChestLocation(location)
	self.dailyLootChest.Parent = nil
	self.dailyLootChest:PivotTo(DailyLootChestData.getLocationData()[location])
	self.dailyLootChest.Parent = workspace
end

--[[
	If claimTime is nil, means the player has never claimed a chest yet. 
	If that is the case, make the wait time 15 mins
	
	Runs only once when the player's modules are being set up
]]
function DailyLootChestModule:setup(
	claimTime: number?,
	completionText: string,
	unlockedLocations: number
)
	self.completionText = completionText
	self.loadingBar:setup(completionText)
	
	self:updateChestLocation(unlockedLocations)
	
	if claimTime then
		self.claimTime = claimTime
		self.countdownLength = 43200 -- 12 hours
	else
		self.claimTime = os.time() + 900
		self.countdownLength = 900 -- 15 minutes
	
		--[[
			Testing purposes:
			
			self.claimTime = os.time() + 5
			self.countdownLength = 5
		]]
	end
	
	--[[
		Start the countdown label above the model in the workspace,
		defaulting to 15 minutes if chest hasn't been claimed before
	]]
	task.spawn(function()
		--[[
			Finally, set the countdown to be the difference between the
			claim time and the current time
		]]
		self:updateCountdownLabel(
			math.clamp(self.claimTime - os.time(), 0, math.huge)
		)
	end)
end

function DailyLootChestModule:enable()
	if self.enabled or self.transitioning then
		return
	end
	self.enabled = true
	self.transitioning = true

	self.movingIcon:enable()
	self.loadingBar:enable(
		self.message,
		math.clamp(self.claimTime - os.time(), 0, math.huge),
		self.countdownLength
	)
	self.claimSummaryCard:setContent(
		"Drop rates!",
		DailyLootChestData.getDropRateData(self.unlockedLocations),
		"Claim",
		function(button)
			self:claimCallback(button)
		end
	)
	self.claimSummaryCard:enable()
	
	self.guiSkeleton:enable(function()
		self:disable()
	end)

	Stack.push(self)
	self.transitioning = false
end

function DailyLootChestModule:disable()
	if not self.enabled or self.transitioning then
		return
	end
	self.enabled = false
	self.transitioning = true
	
	self.movingIcon:disable()
	self.loadingBar:disable()
	self.claimSummaryCard:disable()

	self.guiSkeleton:disable()

	Stack.pop()

	self.transitioning = false
	-- Return true so the stack can proceed with disabling other items in the stack
	return true
end

function DailyLootChestModule:onResize(scale)
	self.guiSkeleton:onResize(scale)
	
	self.claimSummaryCard:onResize(scale)
end

function DailyLootChestModule:onClaim(claimTime: number)
	-- The passed in timeStamp from the server will represent the time that the player claimed
	-- the Daily Loot Chest. Therefore, set the claim time to be 12 hours from that time
	self.claimTime = claimTime + 43200
	self.countdownLength = 43200 -- 12 hours
	
	-- Reset the claim summary card
	self.loadingBar:updateCountdownLength(self.countdownLength)
	self.claimSummaryCard:setSatisfied(false)

	task.spawn(function()
		--[[
			Set the countdown to be the difference between the
			claim time and the current time
		]]
		self:updateCountdownLabel(
			math.clamp(self.claimTime - os.time(), 0, math.huge)
		)
	end)
end

function DailyLootChestModule:onLocationUpgrade(location)
	self.unlockedLocations = location
	
	self:updateChestLocation(location)
	
	if self.enabled then
		self.claimSummaryCard:setContent(
			"Drop rates!",
			DailyLootChestData.getDropRateData(location),
			"Claim",
			function(button)
				self:claimCallback(button)
			end
		)
	end
end

---- CALLBACKS ----
function DailyLootChestModule:claimCallback(button)
	if not button:getAwaiting() then
		ConfirmationPrompt.enable(
			"Would you like to claim the Daily Loot Chest?",
			function()
				local firedTimestamp = workspace:GetServerTimeNow()
				button:enableAwaiting(Claim, firedTimestamp)
				Claim:FireServer(firedTimestamp)
			end
		)
	end
end

return DailyLootChestModule