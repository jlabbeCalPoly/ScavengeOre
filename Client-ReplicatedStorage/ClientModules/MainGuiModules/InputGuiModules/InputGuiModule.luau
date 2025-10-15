-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules

-- Modules
local InputCategorizer = require(HelperModules.InputCategorizer)
local TouchGuiModule = require(script.TouchGuiModule)
local KeyboardGuiModule = require(script.KeyboardGuiModule)

local InputGuiModule = {}
InputGuiModule.__index = InputGuiModule

function InputGuiModule.new(
	parent
)
	local KeyboardGuiModule = KeyboardGuiModule.new(parent)
	local TouchGuiModule = TouchGuiModule.new(parent)
	
	local self = {
		KeyboardGuiModule = KeyboardGuiModule,
		TouchGuiModule = TouchGuiModule,
		lastInputCategory = nil
	}
	setmetatable(self, InputGuiModule)
	
	self:initialize()
	
	return self
end

function InputGuiModule:lastInputCategoryChanged(inputCategory)
	if inputCategory == self.lastInputCategory then
		return
	end
	self.lastInputCategory = inputCategory

	if inputCategory == InputCategorizer.inputCategory.Touch then
		self.KeyboardGuiModule:disable()
		self.TouchGuiModule:enable()	
	else
		self.TouchGuiModule:disable()
		self.KeyboardGuiModule:enable()
	end
end

function InputGuiModule:initialize()
	InputCategorizer.lastInputCategory.Changed:Connect(function()
		self:lastInputCategoryChanged(InputCategorizer.lastInputCategory.Value)
	end)
	self:lastInputCategoryChanged(InputCategorizer.lastInputCategory.Value)
end

function InputGuiModule:setSwingButtonCallback(callback)
	self.TouchGuiModule:setSwingButtonCallback(callback)
end

return InputGuiModule