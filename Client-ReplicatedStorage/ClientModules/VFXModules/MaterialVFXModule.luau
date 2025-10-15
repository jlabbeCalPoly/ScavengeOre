-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Folders
local Materials = ReplicatedStorage.Materials

local MaterialVFXModule = {}
MaterialVFXModule.__index = MaterialVFXModule

function MaterialVFXModule.new()
	local animatedModel = script.AnimatedModel
	animatedModel.Parent = workspace
	
	-- animations
	local animationFolder = animatedModel.Animations
	local animator = animatedModel.AnimationController.Animator

	local animationTracks = {}
	for _, animation in animationFolder:GetChildren() do
		local animationTrack = animator:LoadAnimation(animation)
		animationTracks[animation.Name] = animationTrack
	end
	
	local materialPart = animatedModel.MaterialPart
	
	local self = {
		animatedModel = animatedModel,
		animationTracks = animationTracks,
		-- Transparency tween for the material
		cachedTransparencyTween = nil
	}
	setmetatable(self, MaterialVFXModule)
	
	return self
end

function MaterialVFXModule:reset()
	if self.cachedTransparencyTween and 
		self.cachedTransparencyTween.PlaybackState == Enum.PlaybackState.Playing then
		self.cachedTransparencyTween:Cancel()
	end

	local materialWeldConstraint = self.animatedModel.MaterialPart.WeldConstraint
	if materialWeldConstraint.Part0 ~= nil then
		local material = materialWeldConstraint.Part0
		materialWeldConstraint.Part0 = nil
		
		material.Transparency = 0
		material.Parent = Materials
	end
	
	self.animatedModel.Parent = script
	self.animationTracks.Animation:Stop(0)
end

--[[
	creates/plays the material tween, with params:
	1) instance: Instance in workspace, for positioning
	2) material: String value to represent the material
]]
function MaterialVFXModule:play(instance, material)
	self:reset()
	
	self.animatedModel.Parent = workspace
	local material = Materials:FindFirstChild(material)
	local materialPart = self.animatedModel.MaterialPart
	material.CFrame = materialPart.CFrame
	material.Parent = materialPart
	materialPart.WeldConstraint.Part0 = material
	
	-- Determine the target direction for the animation
	-- (0, 200) to account for 2pi radians in a circle
	local angleInRad = math.pi * math.random(0,200) * 0.01
	local direction = CFrame.fromEulerAngles(0, angleInRad, 0)
	
	local primaryPart = instance.PrimaryPart
	local animatedPart = self.animatedModel.AnimatedPart
	animatedPart.CFrame = primaryPart.CFrame * direction
	animatedPart.WeldConstraint.Part0 = primaryPart
	
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	self.cachedTransparencyTween = TweenService:Create(
		material,
		tweenInfo,
		{ Transparency = 1 }
	)
	
	-- Listener to reset values
	self.cachedTransparencyTween.Completed:Once(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Cancelled then
			self:reset()
		end
	end)
	
	local speed = self.animationTracks.Animation.length / 1.5
	material.Transparency = 0
	self.cachedTransparencyTween:Play()
	self.animationTracks.Animation:Play(0, 1, speed)
end

return MaterialVFXModule