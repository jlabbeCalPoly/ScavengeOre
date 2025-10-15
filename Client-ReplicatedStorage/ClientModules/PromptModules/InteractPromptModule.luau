-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules

-- Modules
local DisconnectAndDestroy = require(HelperModules.DisconnectAndDestroy)

local InteractPromptModule = {}
InteractPromptModule.__index = InteractPromptModule

function InteractPromptModule.new()
	local proxPrompt = Instance.new("ProximityPrompt")
	proxPrompt.Name = "InteractProxPrompt"
	proxPrompt.RequiresLineOfSight = false
	proxPrompt.HoldDuration = 0.2

	local self = {
		proxPrompt = proxPrompt,
		connections = {},
		scale = 1
	}
	setmetatable(self, InteractPromptModule)

	return self
end

function InteractPromptModule:initializePrompt(instance)
	self.proxPrompt.Enabled = false
	
	self.proxPrompt.ActionText = instance:GetAttribute("Key")
	self.proxPrompt.ObjectText = instance:GetAttribute("Description")
end

--[[
	Enable the prompt if checks in PromptModule pass
]]
function InteractPromptModule:enablePrompt(instance)	
	table.insert(
		self.connections,
		self.proxPrompt.Triggered:Connect(function()
			if self.callback then
				self.callback(
					instance:GetAttribute("Key"),
					instance:GetAttribute("Specification")
				)
			end
		end)
	)

	self.proxPrompt.Parent = workspace
	self.proxPrompt.Parent = instance.Interact
	self.proxPrompt.Enabled = true
end

function InteractPromptModule:disablePrompt()
	if not self.proxPrompt.Enabled then
		return
	end
	self.proxPrompt.Enabled = false
	self.proxPrompt.Parent = nil
	
	DisconnectAndDestroy(self.connections)
end

function InteractPromptModule:setEnableGuiCallback(callback)
	self.callback = callback
end

function InteractPromptModule:onResize(scale)	
		self.scale = scale
	end

return InteractPromptModule