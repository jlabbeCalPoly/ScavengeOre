-- Services
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local Utility = HelperModules.Utility

-- Modules
local Entities = require(SharedUtility.Entities)
local Constants = require(SharedUtility.Constants)
local ConvertToNumAbbr = require(Utility.ConvertToNumAbbr)

-- Objects
local guiTemplate = script.Gui

local EntityPromptModule = {}
EntityPromptModule.__index = EntityPromptModule

function EntityPromptModule.new()
	local gui = guiTemplate:Clone()
	gui.Parent = workspace
	
	local scale = gui.UIScale
	
	local self = {
		gui = gui,
		scale = scale,
		cachedSpeed = nil,
		-- cachedHealth represents the current health, cachedEntityHealth represents the max health of the entity
		cachedHealth = nil,
		cachedEntityHealth = nil,
		cachedHealthListener = nil,
		-- Cache the tweens so they can be cancelled if needed
		cachedHealthBarTween = nil,
		cachedSlideBarTween = nil,
	}
	setmetatable(self, EntityPromptModule)
	
	return self
end


--[[
	Fill in the initial information displaying the Entity's luck/health/name info
	when the player gets near
]]
function EntityPromptModule:initializePrompt(instance, luck, speed)
	if self.cachedHealthListener then
		self.cachedHealthListener:Disconnect()
	end
	self.gui.Enabled = false

	local health = instance:GetAttribute("Health")
	local entityId = string.sub(instance.Name, 1, string.len(instance.Name) - 2)
	self.cachedEntityHealth = Entities.getHealth(entityId)

	self:updateEntityLuck(entityId, luck)
	self:updateEntitySpeed(speed)
	self:updateEntityHealth(health)
end

--[[
	Enable the prompt if checks in PromptModule pass
]]
function EntityPromptModule:enablePrompt(instance)
	self.cachedHealthListener = instance:GetAttributeChangedSignal("Health"):Connect(function()
		local health = instance:GetAttribute("Health")
		self:updateEntityHealth(health)
	end)
	-- Since we're specifically in the EntityPromptModule, we can adnoree the
	-- prompt specifically to the touchpart (doesn't move with the mesh tween)
	self.gui.Adornee = instance.Entity
	self.gui.Enabled = true
end

function EntityPromptModule:disablePrompt()
	if not self.gui.Enabled then
		return
	end
	
	self.cachedHealth = nil
	self.cachedEntityHealth = nil
	if self.cachedHealthListener then
		self.cachedHealthListener:Disconnect()
	end
	if self.cachedHealthBarTween ~= nil and 
		self.cachedHealthBarTween.PlaybackState == Enum.PlaybackState.Playing then
		self.cachedHealthBarTween:Cancel()
	end
	if self.cachedSlideBarTween ~= nil and
		self.cachedSlideBarTween.PlaybackState == Enum.PlaybackState.Playing then
		self.cachedSlideBarTween:Cancel()
	end
	self.gui.Enabled = false
end

--[[
	In addition, also updates the name on the prompt
]]
function EntityPromptModule:updateEntityLuck(entityId, luck)
	local ContainerFrame = self.gui.ContainerFrame

	ContainerFrame.TitleFrame.EntityName.Text = entityId
	local InfoFrame = ContainerFrame.InfoFrame
	local Rarities = InfoFrame.Rarities
	local values = Entities.calculateLuck(entityId, luck)
	
	for rarity, value in pairs(values) do
		local child = Rarities:FindFirstChild(rarity)
		if child then
			local format
			if value  >= 10 then
				if value > 99.9 then
					value = 99.9
					format = Constants.PERCENT_STRING_FORMAT_MAXIUMUM
				else
					format = Constants.PERCENT_STRING_FORMAT_1DECIMAL
				end
			else
				if value < 0.01 then
					value = 0.01
					format = Constants.PERCENT_STRING_FORMAT_MINIMUM
				else
					format = Constants.PERCENT_STRING_FORMAT_2DECIMAL
				end
			end
			child.RarityValue.Text = string.format(format, value)
		end
	end
	
	--[[
		for _, child in Rarities:GetChildren() do
		if child.ClassName == "Frame" then
			local value = values[child.Name]
			local format
			if value  >= 10 then
				if value > 99.9 then
					value = 99.9
					format = Constants.PERCENT_STRING_FORMAT_MAXIUMUM
				else
					format = Constants.PERCENT_STRING_FORMAT_1DECIMAL
				end
			else
				if value < 0.01 then
					value = 0.01
					format = Constants.PERCENT_STRING_FORMAT_MINIMUM
				else
					format = Constants.PERCENT_STRING_FORMAT_2DECIMAL
				end
			end
			child.RarityValue.Text = string.format(format, value)
		end
	end
	]]
	
	-- Update the size/visibility based on if an "Eternal" rarity was set
	local eternalLabel = Rarities:FindFirstChild("Eternal")
	if eternalLabel then
		if values["Eternal"] then
			eternalLabel.Visible = true
			InfoFrame.Size = Constants.PROMPT_SIZE_WITH_ETERNAL
		else
			eternalLabel.Visible = false
			InfoFrame.Size = Constants.PROMPT_SIZE_NO_ETERNAL
		end
	end
end

--[[
	Tweens occur only if the following condition is satisfied:
	1) self.cachedHealth ~= nil and self.cachedHealth ~= 0, both of which indicate a resetting event
]]
function EntityPromptModule:updateEntityHealth(health)
	local ContainerFrame = self.gui.ContainerFrame
	local HealthFrame = ContainerFrame.InfoFrame.HealthFrame
	local HealthBar = HealthFrame.Bars.HealthBar
	local SlideBar = HealthFrame.Bars.SlideBar
	local Health = HealthFrame.Health
	local size = UDim2.new(health / self.cachedEntityHealth, 0, 1, 0)
	
	if self.cachedHealth ~= nil and self.cachedHealth ~= 0 then
		local tweenInfo = TweenInfo.new(self.cachedSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		self.cachedHealthBarTween = TweenService:Create(HealthBar, tweenInfo, { BackgroundColor3 = Constants.GREEN_COLOR })
		self.cachedSlideBarTween = TweenService:Create(SlideBar, tweenInfo, { Size = size })
		
		HealthBar.BackgroundColor3 = Constants.RED_COLOR
		HealthBar.Size = size
		
		self.cachedHealthBarTween:Play()
		self.cachedSlideBarTween:Play()
	else
		-- reset the color for the healthbar, then adjust the sizes with respect to the
		-- entities health
		HealthBar.BackgroundColor3 = Constants.GREEN_COLOR
		HealthBar.Size = size
		SlideBar.Size = size
	end
	
	Health.Text = string.format(Constants.STRING_RATIO_STRING_FORMAT, ConvertToNumAbbr(health), ConvertToNumAbbr(self.cachedEntityHealth))
	self.cachedHealth = health
end

function EntityPromptModule:onResize(scale)	
	local xScaled = 200 * scale
	local yScaled = 146 * scale
	self.gui.Size = UDim2.new(0, xScaled, 0, yScaled)
	self.scale.Scale = scale
end

--[[
	Determines how fast the health bar tweens should play
]]
function EntityPromptModule:updateEntitySpeed(speed)
	self.cachedSpeed = speed
end

return EntityPromptModule