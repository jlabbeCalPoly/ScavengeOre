-- Services
local TweenService = game:GetService("TweenService")

-- Objects
local Blur = script.Blur

local BlurEffect = {}
BlurEffect.__index = BlurEffect

function BlurEffect.new()
	local blur = Blur:Clone()
	blur.Parent = game.Lighting
	
	local tweenInfo = TweenInfo.new(0.2,Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(blur, tweenInfo, { Size = 24 })
	
	local self = {
		enabled = false,
		tween = tween,
		blur = blur,
	}
	setmetatable(self, BlurEffect)
	
	return self
end

function BlurEffect:enable()
	if self.enabled then
		return
	end
	self.enabled = true
	
	self.tween:Play()
end

function BlurEffect:disable()
	if not self.enabled then
		return
	end
	self.enabled = false
	
	if self.tween.PlaybackState == Enum.PlaybackState.Playing then
		self.tween:Cancel()
	end
	
	self.blur.Size = 0
end

return BlurEffect