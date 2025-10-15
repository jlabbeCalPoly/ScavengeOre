-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules

-- Modules
local EntityPromptModule = require(script.EntityPromptModule)
local InteractPromptModule = require(script.InteractPromptModule)

local PromptModule = {}
PromptModule.__index = PromptModule

-- VFXModule handles the visual effects generated from swinging
function PromptModule.new()
	local EntityPromptModule = EntityPromptModule.new()
	local InteractPromptModule = InteractPromptModule.new()
	
	local self = {
		-- Store the modules in a key-value table to reference the correct functions
		EntityPromptModule = EntityPromptModule,
		InteractPromptModule = InteractPromptModule,
		modules = {
			["Entity"] = EntityPromptModule,
			["Interact"] = InteractPromptModule
		},
		-- In order to avoid overlap with enabling/resetting the guis, use:
		-- 1) transitioning variable: enabling/resetting will not occur at the same time
		transitioning = false,
		-- Cache the last detector (touch part in the model)
		cachedTouchDetector = nil,
		-- Cache the instances that are currently in range (within the player's promptHitbox)
		inRange = {}
	}
	setmetatable(self, PromptModule)
	
	return self
end


function PromptModule:findNearestPrompt(luck, speed)
	-- determine which instance is closest to the player (horizontal components only)
	-- nocheck for if the model gets streamed out, may need to implement hierarchical change connection after
	local position = Players.LocalPlayer.Character.PrimaryPart.CFrame.Position
	local closest = math.huge
	local touchDetector
	for child, _ in pairs(self.inRange) do
		local childPosition = child.CFrame.Position
		local distance = math.sqrt(
			math.pow(position.X - childPosition.X, 2) +
			math.pow(position.Z - childPosition.Z, 2)
		)
		if distance <= closest then
			closest = distance
			touchDetector = child
		end
	end
	
	if self.cachedTouchDetector ~= touchDetector then		
		self.cachedTouchDetector = touchDetector
		local instance = touchDetector.Parent
		local moduleKey = touchDetector.Name
		
		-- First, disable any prompt that was currently enabled (if any)
		self.modules[moduleKey]:disablePrompt()
		self.modules[moduleKey]:initializePrompt(instance, luck, speed)

		-- Make sure our cachedInstance state hasn't changed since entering the function
		-- If no change, then it's safe to enable the gui
		if self.cachedTouchDetector == touchDetector then
			self.modules[moduleKey]:enablePrompt(instance)
		end
	end
	self.transitioning = false
end

function PromptModule:onResize(scale)
	self.EntityPromptModule:onResize(scale)
	self.InteractPromptModule:onResize(scale)
end

function PromptModule:setEnableGuiCallback(callback)
	self.InteractPromptModule:setEnableGuiCallback(callback)
end

--[[
	The following two functions are called when the .touched and .touchEnded events
	are fired by the promptHitbox
]]
	function PromptModule:addPrompt(touchDetector, luck, speed)
		self.inRange[touchDetector] = true
		if self.transitioning then
			return
		end
		self.transitioning = true
		
		self:findNearestPrompt(luck, speed)
	end

	function PromptModule:removePrompt(touchDetector, luck, speed)
		-- Remove the touchDetector from inRange
		self.inRange[touchDetector] = nil
		
		if self.transitioning then
			return
		end
		self.transitioning = true
		
		-- Reset the cachedInstances in the event the instance being removed IS the cachedInstance
		if self.cachedTouchDetector == touchDetector then
			self.cachedTouchDetector = nil
			
			local instance = touchDetector.Parent
			local moduleKey = touchDetector.Name
			
			self.modules[moduleKey]:disablePrompt()
		end

		self:findNearestPrompt(luck, speed)
	end

return PromptModule