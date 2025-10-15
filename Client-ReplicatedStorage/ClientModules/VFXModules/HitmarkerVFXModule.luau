-- Services
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local Utility = HelperModules.Utility

-- Modules
local ConvertToNumAbbr = require(Utility.ConvertToNumAbbr)

-- Objects
local HitmarkerGuiTemplate = script.HitmarkerGui

local HitmarkerVFXModule = {}
HitmarkerVFXModule.__index = HitmarkerVFXModule

function HitmarkerVFXModule.new(scale)

	local quadFastInfo = TweenInfo.new(0.5,
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out)
	local quadSlowInfo = TweenInfo.new(0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	)
	local backInfo = TweenInfo.new(1,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.In
	)
	
	local self = {
		scale = scale,
		quadFastInfo = quadFastInfo,
		quadSlowInfo = quadSlowInfo,
		backInfo = backInfo
	}
	setmetatable(self, HitmarkerVFXModule)
	
	return self
end

function HitmarkerVFXModule:play(instance, power)
	local hitmarkerGui = HitmarkerGuiTemplate:Clone()
	
	local UIScale = hitmarkerGui.UIScale
	hitmarkerGui.Size = UDim2.new(0, 300 * self.scale, 0, 200 * self.scale)
	UIScale.Scale = self.scale
	local TextLabel = hitmarkerGui.TextLabel
	
	TextLabel.Text = tostring("-"..ConvertToNumAbbr(power))
	
	local position, rotation
	if math.random() < 0.5 then
		position = Vector3.new(1,0,0)
		rotation = -10
	else
		position = Vector3.new(-1,0,0)
		rotation = 10
	end
	
	local textTween = TweenService:Create(
		TextLabel,
		self.quadFastInfo, 
		{ Position = UDim2.new(0.5, 0, 0, 100), Rotation = rotation }
	)
	local guiPositionTween = TweenService:Create(
		hitmarkerGui,
		self.quadFastInfo,
		{ ExtentsOffset = position }
	)
	local scaleTween = TweenService:Create(
		UIScale,
		self.backInfo,
		{ Scale =0 }
	)

	scaleTween.Completed:Once(function()
		textTween:Destroy()
		guiPositionTween:Destroy()
		scaleTween:Destroy()
		
		hitmarkerGui:Destroy()
	end)

	hitmarkerGui.Parent = instance.PrimaryPart
	
	textTween:Play()
	guiPositionTween:Play()
	scaleTween:Play()
end

function HitmarkerVFXModule:onResize(scale)
	self.scale = scale
end

return HitmarkerVFXModule