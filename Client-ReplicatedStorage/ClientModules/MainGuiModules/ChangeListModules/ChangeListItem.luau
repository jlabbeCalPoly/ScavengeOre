-- Services
local TweenService = game:GetService("TweenService")

-- Objects
local Frame = script.Frame

local ChangeListItem = {}
ChangeListItem.__index = ChangeListItem

function ChangeListItem.new(
	parent,
	name,
	image,EasingDirection,
	quantity,
	color,
	particleColor
)
	local frame = Frame:Clone()
	local scale = frame.UIScale
	
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(scale, tweenInfo, { Scale = 0 })
	local tweenIn = TweenService:Create(scale, tweenInfo, { Scale = 1 })
	
	frame.ItemLabel.Text = name
	frame.ItemLabel.TextColor3 = color
	frame.ImageLabel.Image = image
	frame.QuantityLabel.Text = quantity
	frame.QuantityLabel.TextColor3 = color
	
	if particleColor then
		local particles = frame.Particles
		for _, particle in particles:GetChildren() do
			if particle.Name == "Particle" then
				particle.ImageColor3 = particleColor
			end
		end
		particles.Visible = true
	end
	
	local self = {
		frame = frame,
		tween = tween,
		tweenIn = tweenIn
	}
	setmetatable(self, ChangeListItem)
	
	frame.Parent = parent
	self:initialize()
	
	return self
end

-- set the callback and task.delay for the tween
function ChangeListItem:initialize()
	self.tweenIn:Play()
	
	self.tween.Completed:Once(function()
		self.frame:Destroy()
		table.clear(self)
	end)
	
	task.delay(5, function()
		self.tween:Play()
	end)
end

return ChangeListItem