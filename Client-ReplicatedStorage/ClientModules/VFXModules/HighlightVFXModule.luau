-- Services
local TweenService = game:GetService("TweenService")

local HighlightVFXModule = {}
HighlightVFXModule.__index = HighlightVFXModule

function HighlightVFXModule.new()
	local self = {
		cachedHighlight = nil,
		cachedHighlightTween = nil
	}
	setmetatable(self, HighlightVFXModule)
	
	return self
end

-- Create the cached tween when the LOCAL player swings on an instance
function HighlightVFXModule:createTween(instance, speed)
	local highlightTweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local highlight = instance.Mesh.Highlight
	
	self.cachedHighlight = highlight
	self.cachedHighlightTween = TweenService:Create(highlight, highlightTweenInfo, {FillTransparency = 1})
end

-- Play the cached tween
function HighlightVFXModule:play()
	self.cachedHighlight.FillTransparency =  0.4
	self.cachedHighlightTween:Play()
end

-- Create a non-cached tween for replicated VFX events
function HighlightVFXModule:playReplicatedTween(instance, speed)
	local highlight = instance.Mesh.Highlight
	local highlightTweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local highlightTween = TweenService:Create(highlight, highlightTweenInfo, {FillTransparency = 1})

	highlight.FillTransparency =  0.4
	highlightTween:Play()
end

return HighlightVFXModule