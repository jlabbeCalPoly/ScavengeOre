-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local Utility = HelperModules.Utility
local GuiComponents = HelperModules.GuiComponents
local InspectPanels = GuiComponents.InspectPanels
local Buttons = GuiComponents.Buttons
local Remotes = ReplicatedStorage.Remotes
local ItemTemplates = script.Parent.Parent.ItemTemplates

-- Modules
local MaterialsInspectPanel = require(InspectPanels.MaterialsInspectPanel)
local ConfirmationPrompt = require(HelperModules.ConfirmationPrompt)
local NotificationPrompt = require(HelperModules.NotificationPrompt)
local Colors = require(HelperModules.Colors)
local Materials = require(SharedUtility.Materials)
local Rarities = require(SharedUtility.Rarities)
local Constants = require(SharedUtility.Constants)
local StorageData = require(SharedUtility.StorageData)
local ConvertToNumAbbr = require(Utility.ConvertToNumAbbr)

-- Remotes
local Sell = Remotes.Sell
local Lock = Remotes.Lock

-- Objects
local Stackable = ItemTemplates.Stackable
local Filters = {
	"Rarity", "Quantity", "Value"
}

local MaterialsInventoryModule = {}
MaterialsInventoryModule.__index = MaterialsInventoryModule

function MaterialsInventoryModule.new(
	parent
)	
	local inspectPanel = MaterialsInspectPanel.new(parent)
	
	local self = {
		inventory = {},
		inspectPanel = inspectPanel,
		
		leftVal = 0,
		rightVal = 0,
	}
	setmetatable(self, MaterialsInventoryModule)
	
	inspectPanel:setSellButtonCallback(function(button, displayed, value, sellValue)
		self:sellButtonCallback(button, displayed, value, sellValue)
	end)
	inspectPanel:setLockButtonCallback(function(button, displayed, action)
		self:lockButtonCallback(button, displayed, action)
	end)

	return self
end

function MaterialsInventoryModule:setLockDetails(info, isLocked)
	info["Lock"] = isLocked
	if isLocked then
		info["Item"].Button.LockImage.Visible = true
	else
		info["Item"].Button.LockImage.Visible = false
	end
end

--[[
	Add a new material into the inventory
]]
function MaterialsInventoryModule:add(materialName, materialData)
	local item = Stackable:Clone()
	
	-- elements will be looked-up by the material name, so set the name of the cloned element to the material name
	item.Parent = nil
	item.Name = materialName
	
	local Button = item.Button
	Button.ItemName.Text = materialName
	Button.Quantity.Text = "x"..materialData.Quantity
	
	-- Get the color value to set the color of the glow effect
	local rarityString = Rarities.getRarity(materialData.Rarity)
	local color = Colors.getRarityColor(rarityString).Static
	
	local Particles = Button.Particles
	for _, child in Particles:GetChildren() do
		-- Skip the coloring if the particle color is meant to be white
		if child.Name == "Particle" then
			child.ImageColor3 = color
		end
	end

	-- Create a click tween for the click animation
	local clickTween = TweenService:Create(
		Button, 
		Constants.BUTTON_CLICK_TWEEN_INFO, 
		{ Size = Constants.INVENTORY_ITEM_SMALL }
	)
	
	local hoverTween = TweenService:Create(
		Button,
		Constants.BUTTON_HOVER_TWEEN_INFO,
		{ Size = Constants.INVENTORY_ITEM_LARGE }
	)

	-- get the value of the material
	local value = Materials.getMaterialValue(materialName)
	
	local info = {
		["Name"] = materialName,
		--[[
			The following 3 keys represent the keys that the user can filter the inventory by
		]]
		["Rarity"] = materialData.Rarity,
		["Quantity"] = materialData.Quantity,
		["Value"] = value,
		--[[
			The following 2 keys represent the corresponding UI element and whether it's been fully loaded
			"Load" key will be set to nil once the image has been successfully set
		]]
		["Item"] = item,
		["Load"] = true,
		--[[
			The following 2 keys represent effects that play when the UI element is hovered over/clicked
		]]
		["ClickTween"] = clickTween,
		["HoverTween"] = hoverTween,
	}

	self:setLockDetails(info, materialData.Lock)
	self.inventory[materialName] = info
	return info
end

function MaterialsInventoryModule:applyFilter(filter)
	-- Create a temporary list to then sort from
	local temporaryList = {}
	local filterList = {}

	for key, data in pairs(self.inventory) do
		-- Only search for the filtered type if the filter isn't being deselected
		if filter then
			table.insert(
				temporaryList,
				{
					["Key"] = key,
					[filter] = data[filter]
				}
			)
		else
			table.insert(
				temporaryList,
				{
					["Key"] = key
				}
			)
		end
	end
	
	if filter then
		table.insert(
			filterList,
			filter
		)
	end
	
	return temporaryList, filterList
end

--[[
	Set the values of the capacity values if provided, then return the values in their updated format
]]
function MaterialsInventoryModule:capacityValues(leftVal, rightVal)
	if leftVal then
		self.leftVal += leftVal
	end
	if rightVal then
		self.rightVal = StorageData.getData(rightVal).Value
	end
	
	local color = Constants.WHITE_COLOR
	if self.leftVal >= self.rightVal then
		color = Constants.RED_COLOR
	end
	
	local updLeftVal = ConvertToNumAbbr(self.leftVal)
	local updRightVal = ConvertToNumAbbr(self.rightVal)
	
	return updLeftVal, updRightVal, color
end

function MaterialsInventoryModule:enableInspectPanel(name, info)
	if self.inspectPanel:getDisplayed() ~= name then
		self.inspectPanel:enable(name, info)
	end
end

function MaterialsInventoryModule:disableInspectPanel()
	self.inspectPanel:disable()
end

function MaterialsInventoryModule:updatePanel(info)
	self.inspectPanel:setLockDetails(info)
end

function MaterialsInventoryModule:onResize(scale)
	self.inspectPanel:onResize(scale)
end

function MaterialsInventoryModule:setRange(range)
	self.inspectPanel:setRange(range)
end

function MaterialsInventoryModule:setPositionAndSizeRenderStepped()
	self.inspectPanel:setPositionAndSizeRenderStepped()
end

function MaterialsInventoryModule:getInventory()
	return self.inventory
end

function MaterialsInventoryModule:getFilters()
	return Filters
end

function MaterialsInventoryModule:getDisplayed()
	return self.inspectPanel:getDisplayed()
end

--[[
	Returns the value the player will recieve by selling all of their materials,
	disregarding any that are locked
]]
function MaterialsInventoryModule:getSellAllValue()
	local totalValue = 0
	
	for _, materialInfo in pairs(self.inventory) do
		if not materialInfo.Lock then
			totalValue += (materialInfo.Quantity * materialInfo.Value) 
		end
	end
	
	return totalValue
end

---- CALLBACK FUNCTIONS ----

	--[[
		Sell the selected amount (self.value) or the selected material (self.materialDisplayed) 
	]]
	function MaterialsInventoryModule:sellButtonCallback(
		button: TextButton,
		displayed: string?,
		value: number?,
		sellValue: number?
	)
		if not button:getAwaiting() and displayed and value and sellValue then
			local info = self.inventory[displayed]
			-- If the material is locked, notify the player to unlock it
			if info and info.Lock then
				NotificationPrompt.enable("Unlock the material before attempting to sell", false)
			else
				ConfirmationPrompt.enable(
					string.format(Constants.CONFIRMATION_SELL_STRING_FORMAT, "x"..value, displayed, ConvertToNumAbbr(sellValue * value, "Cash")),
					function()
						local firedTimestamp = workspace:GetServerTimeNow()
						button:enableAwaiting(Sell, firedTimestamp)
						Sell:FireServer(firedTimestamp, displayed, "Materials", value)
					end
				)
			end
		end
	end
	
	function MaterialsInventoryModule:lockButtonCallback(
		button: TextButton,
		displayed: string?,
		action: string
	)
		if not button:getAwaiting() and displayed and action then
			ConfirmationPrompt.enable(
				string.format(Constants.CONFIRMATION_EQUIP_STRING_FORMAT, string.lower(action), displayed),
				function()
					local firedTimestamp = workspace:GetServerTimeNow()
					button:enableAwaiting(Lock, firedTimestamp)
					Lock:FireServer(firedTimestamp, displayed, action)
				end
			)
		end
	end

--[[
	Cleanup script
]]
function MaterialsInventoryModule:destroy()
	table.clear(self.inventory)
	table.clear(self)
end

return MaterialsInventoryModule