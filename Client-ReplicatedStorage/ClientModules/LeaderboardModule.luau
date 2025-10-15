-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local GuiComponents = HelperModules.GuiComponents

-- Modules
local Stack = require(HelperModules.Stack)
local Constants = require(SharedUtility.Constants)
local GuiSkeleton = require(GuiComponents.GuiSkeleton)
local Timer = require(GuiComponents.Timer)
local LeaderboardCard = require(GuiComponents.LeaderboardCard)

-- Objects
local Description = script.Description

local LeaderboardModule = {}
LeaderboardModule.__index = LeaderboardModule

function LeaderboardModule.new()
	local guiSkeleton, gui = GuiSkeleton.new()
	guiSkeleton:setContent("Leaderboard", "Leaderboard")

	local frame = gui.Frame
	
	local description = Description:Clone()
	description.Parent = frame
	
	local timer = Timer.new(
		frame,
		Vector2.new(1,0),
		UDim2.new(1, 0, 0, 25),
		UDim2.new(0, 135, 0, 18)
	)
	local cashLeaderboard = LeaderboardCard.new(
		frame,
		Vector2.new(0,1),
		UDim2.new(0,0,1,0),
		UDim2.new(0,205,0,195),
		"Cash",
		Constants.BLACK_COLOR,
		Constants.GREEN_COLOR
	)
	local powerLeaderboard = LeaderboardCard.new(
		frame,
		Vector2.new(1,1),
		UDim2.new(1,0,1,0),
		UDim2.new(0,205,0,195),
		"Power",
		nil,
		nil,
		ColorSequence.new{
			ColorSequenceKeypoint.new(0, Constants.FABLED_COLOR_DARK),
			ColorSequenceKeypoint.new(1, Constants.FABLED_COLOR_BASE)
		}
	)
	
	local self = {
		enabled = false,
		transitioning = false,
		guiSkeleton = guiSkeleton,
		timer = timer,
		cashLeaderboard = cashLeaderboard,
		powerLeaderboard = powerLeaderboard
	}
	setmetatable(self, LeaderboardModule)
	
	return self
end

function LeaderboardModule:enable()
	if self.enabled or self.transitioning then
		return
	end
	self.enabled = true
	self.transitioning = true
	
	if self.refreshTime then
		self.timer:enable(self.refreshTime - os.time())
	else
		self.timer:enable(0)
	end
	
	self.cashLeaderboard:enable()
	self.powerLeaderboard:enable()
	
	self.guiSkeleton:enable(function()
		self:disable()
	end)

	Stack.push(self)
	self.transitioning = false
end

function LeaderboardModule:disable()
	if not self.enabled or self.transitioning then
		return
	end
	self.enabled = false
	self.transitioning = true
	
	self.timer:disable()
	self.cashLeaderboard:disable()
	self.powerLeaderboard:disable()
	self.guiSkeleton:disable()

	Stack.pop()

	self.transitioning = false
	-- Return true so the stack can proceed with disabling other items in the stack
	return true
end

function LeaderboardModule:setContent(untilRefresh, cashLeaderboard, powerLeaderboard)
	self.transitioning = true
	
	-- Check to make sure the refreshes didn't occur to close between each other
	if self.resetReceived and (os.time() - self.resetReceived) <= 3 then
		return
	end
	
	self.resetReceived = os.time()
	self.refreshTime = self.resetReceived + untilRefresh
	
	self.cashLeaderboard:setContent(cashLeaderboard)
	self.powerLeaderboard:setContent(powerLeaderboard)
	self.timer:updateCountdown(untilRefresh)
	
	self.transitioning = false
end

function LeaderboardModule:onResize(scale)
	self.guiSkeleton:onResize(scale)
end

return LeaderboardModule