-- Services
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local Movement = require(HelperModules.Movement)
local Constants = require(SharedUtility.Constants)

-- Objects
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CameraModule = {}
CameraModule.__index = CameraModule

-- VFXModule handles the visual effects generated from swinging
function CameraModule.new()	
	local self = {
		-- Store the last instance of the cameraTween, so overlap doesn't happen
		cameraTween = nil,
		-- Store the last cFrame of the camera when the player had control
		lastCameraCFrame = nil,
		-- Store the last transition speed so the distance between the camera/camera part
		-- instance doesn't need to be calcualted twice
		lastTransitionSpeed = nil
	}
	setmetatable(self, CameraModule)
	
	return self
end

function CameraModule:checkTweenState()
	if self.cameraTween ~= nil and self.cameraTween.PlaybackState == Enum.PlaybackState.Playing then
		self.cameraTween:Cancel()
	end
end

function CameraModule:checkDistance(pos1, pos2)
	local distance = math.sqrt(
		math.pow((pos1.X - pos2.X), 2) +
		math.pow((pos1.Y - pos2.Y), 2) +
		math.pow((pos1.Z - pos2.Z), 2)
	)
	local speed
	if distance > 10 then
		speed = Constants.CAMERA_SPEED_SLOW
	else
		speed = Constants.CAMERA_SPEED_FAST
	end
	return speed
end

function CameraModule:setCamera(instance)
	Movement.disable()
	Camera.CameraType = Enum.CameraType.Scriptable
	self:checkTweenState()
	
	local targetCFrame = instance.CameraPart.CFrame
	self.lastCameraCFrame = Camera.CFrame
	self.lastTransitionSpeed = self:checkDistance(targetCFrame.Position, self.lastCameraCFrame.Position)

	local tweenInfo = TweenInfo.new(self.lastTransitionSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	self.cameraTween = TweenService:Create(Camera, tweenInfo, { CFrame = targetCFrame })
	
	self.cameraTween:Play()
	self.cameraTween.Completed:Wait()
--	return self.lastTransitionSpeed
end

function CameraModule:resetCamera()
	self:checkTweenState()
	
	local tweenInfo = TweenInfo.new(self.lastTransitionSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	self.cameraTween = TweenService:Create(Camera, tweenInfo, { CFrame = self.lastCameraCFrame })
	
	self.cameraTween.Completed:Once(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Cancelled then
			Camera.CameraType = Enum.CameraType.Custom
		end
	end)
	
	self.cameraTween:Play()
	self.cameraTween.Completed:Wait()
	Movement.enable()
end

return CameraModule
