-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local SharedUtility = ReplicatedStorage.HelperModules.SharedUtility

-- Modules
local Constants = require(SharedUtility.Constants)

-- Objects
local HumanoidRootPart = Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")

local Movement = {}

-- Enable the player's movement
function Movement.enable()	
	HumanoidRootPart.Anchored = false
end

-- Disable the player's movement
function Movement.disable()	
	HumanoidRootPart.Anchored = true
	HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
end

return Movement