-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
	
-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local GuiComponents = HelperModules.GuiComponents

-- Modules
local TaskList = require(GuiComponents.TaskList)
local TaskData = require(SharedUtility.TaskData)
local Timer = require(GuiComponents.Timer)

-- Objects
local Content = script.Content

local DailyRewards = {}
DailyRewards.__index = DailyRewards

function DailyRewards.new(
	parent,
	playerData
)
	for _, child in Content:GetChildren() do
		child:Clone()
		child.Parent = parent
	end
	
	local Description = parent.DailyDescription

	local timer = Timer.new(
		parent,
		Vector2.new(1,0),
		UDim2.new(1, 0, 0, 57),
		UDim2.new(0, 135, 0, 18)
	)
	
	-- create the taskcards
	local taskList = TaskList.new(
		parent,
		Vector2.new(0,0),
		UDim2.new(0,0,0,75),
		UDim2.new(1,0,0,175),
		playerData
	)
	
	local dailyData = playerData["DailyData"]
	
	local self = {
		enabled = false,
		
		Description = Description,
		
		playerData = playerData,
		resetTimestamp = dailyData["Reset"],
		location = playerData["LevelStats"]["UnlockedLocations"],
		timer = timer,
		taskList = taskList	
	}
	setmetatable(self, DailyRewards)
	
	self:initialize()
	
	return self
end

function DailyRewards:onDailyClaim(taskNum)
	self.taskList:onClaim(taskNum)
end

function DailyRewards:onLocationUpgrade(location)
	self.location = location
end

function DailyRewards:enable()
	if self.enabled then	
		return
	end
	self.enabled = true
	
	local countdown = math.ceil(self.resetTimestamp - workspace:GetServerTimeNow())
	if countdown < 0 then
		countdown = 0
	end
	self.timer:enable(countdown)
	
	self.Description.Visible = true
	self.taskList:enable()
end

function DailyRewards:disable()
	if not self.enabled then
		return
	end
	self.enabled = false
	
	self.timer:disable()

	self.Description.Visible = false
	self.taskList:disable()
end

function DailyRewards:initialize()
	local countdown = math.ceil(self.resetTimestamp - workspace:GetServerTimeNow())
	if countdown > 0 then
		task.delay(countdown, function()
			self:reset()
		end)
		self.timer:updateCountdown(countdown)
	else
		self:reset()
	end
end

function DailyRewards:reset()
	self.resetTimestamp += 86400
	
	self.playerData["DailyData"] = TaskData.generateTaskDataClient(self.playerData["DailyData"], self.location)
	self.taskList:reset(self.playerData["DailyData"])
	
	self:initialize()
end

return DailyRewards