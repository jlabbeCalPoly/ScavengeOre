-- Objects
local Frame = script.Frame

local KeyboardGuiModule = {}
KeyboardGuiModule.__index = KeyboardGuiModule

function KeyboardGuiModule.new(
	parent
)
	local frame = Frame:Clone()
	frame.Parent = parent
	
	local self = {
		enabled = false,
		frame = frame,
	}
	setmetatable(self, KeyboardGuiModule)

	return self
end

function KeyboardGuiModule:enable()
	if self.enabled then
		return
	end
	self.enabled = true

	self.frame.Visible = true
end

function KeyboardGuiModule:disable()
	if not self.enabled then
		return
	end
	self.enabled = false

	self.frame.Visible = false
end

return KeyboardGuiModule