-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local Utility = HelperModules.Utility
local GuiComponents = HelperModules.GuiComponents
local InspectPanels = GuiComponents.InspectPanels
local Remotes = ReplicatedStorage.Remotes
local ItemTemplates = script.Parent.Parent.ItemTemplates

-- Modules
local GetHighestPower = require(SharedUtility.GetHighestPower)
local RelicsInspectPanel = require(InspectPanels.RelicsInspectPanel)
local ConfirmationPrompt = require(HelperModules.ConfirmationPrompt)
local NotificationPrompt = require(HelperModules.NotificationPrompt)
local Colors = require(HelperModules.Colors)
local Relics = require(SharedUtility.Relics)
local Constants = require(SharedUtility.Constants)
local ConvertToNumAbbr = require(Utility.ConvertToNumAbbr)
local AutoCenter = require(GuiComponents.AutoCenter)

-- Remotes
local Sell = Remotes.Sell
local Equip = Remotes.Equip

-- Objects
local Single = ItemTemplates.Single
--local Filters = {
--	"Power", "Luck", "Speed", "Value"
--}
local Filters = {
	"Power"
}

local RelicsInventoryModule = {}
RelicsInventoryModule.__index = RelicsInventoryModule

function RelicsInventoryModule.new(
	parent
)	
	local self = {
		highestPower = 1,
		inventory = {},
		
		leftVal = 0,
		rightVal = 0,
	}
	setmetatable(self, RelicsInventoryModule)
	
	self.inspectPanel = RelicsInspectPanel.new(parent, function()
		return self:getCapacityCallback()
	end)
	self.inspectPanel:setSellButtonCallback(function(button, displayed, value, sellValue)
		self:sellButtonCallback(button, displayed, value, sellValue)
	end)
	self.inspectPanel:setEquipButtonCallback(function(button, displayed, name, action)
		self:equipButtonCallback(button, displayed, name, action)
	end)

	return self
end

--[[
	Add a NEW material into the inventory
]]
function RelicsInventoryModule:add(relicId, relicData)
	local item = Single:Clone()
	
	-- relics will be looked-up by the relic id, so set the name of the cloned element to the relic id
	item.Parent = nil
	item.Name = relicId
	
	local Button = item.Button
	local ItemName = Button.ItemName
	
	local relicColor = Colors.getRelicColor(Relics.getRelicsType(relicData.Name))
	ItemName.Text = relicData.Name
	ItemName.UIGradient.Color = relicColor
	
	Button.ItemImage.Image = relicData.Name
	
	local colors = Colors.getBoostColors(relicData.Type)
	
	local autoCenter = AutoCenter.new(
		Button,
		Vector2.new(0.5, 0),
		UDim2.new(0.5, 0, 0, 0),
		UDim2.new(0, 60, 0, 15),
		60,
		15,
		colors.Secondary,
		relicData.Type
	)
	autoCenter:setGradient(colors.Gradient)
	autoCenter:setValue(relicData.TypeValue)
	
	if relicData.Equipped == 1 then
		Button.EquippedIndicator.Visible = true
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
	
	local info = {
		--[[
			The following key represents the image/mesh corresponding to the relicId
		]]
		["Name"] = relicData.Name,
		--[[
			The following 4 keys represent the keys that the user can filter the inventory by
		]]
		["Value"] = relicData.Value,
		["Equipped"] = relicData.Equipped,
		["Type"] = relicData.Type,
		["TypeValue"] = relicData.TypeValue,
		["Amplified"] = relicData.Amplified,
		
		--[[
			The following 2 keys represent the corresponding UI element and whether it's been fully loaded
			"Load" key will be set to nil once the image has been successfully set
		]]
		["Item"] = item,
		["AutoCenter"] = autoCenter,
		["Load"] = true,
		--[[
			The following 2 keys represent effects that play when the UI element is hovered over/clicked
		]]
		["ClickTween"] = clickTween,
		["HoverTween"] = hoverTween,
		--[[
			Quantity
		]]
		["Quantity"] = relicData.Quantity,
	}

	self.inventory[relicId] = info
	return info
end

-- Updates the cached highest power and anything in the inventory thatis affected by the change
function RelicsInventoryModule:updateHighestPower(relicList)
	local function updatePower()
		local highestPower, amplifiedList = GetHighestPower(self.inventory)
		self.highestPower = highestPower

		for _, relicId in pairs(amplifiedList) do
			local relicInfo = self.inventory[relicId]
			if relicInfo then
				local typeValue = math.floor(Relics.getRelicsValue(relicInfo.Name) * highestPower)
				relicInfo.TypeValue = typeValue
				relicInfo.AutoCenter:setValue(typeValue)
				
				-- Attempt to enable the inspect panel if the given relic happens to be displayed
				if self.inspectPanel:getDisplayed() == relicId then
					self.inspectPanel:enable(relicId, relicInfo)
				end
			end
		end
	end
	
	-- relic was added to the inventory, check if it happened to be larger than the current highest
	local function onRelicAdd(highestPower)
		if highestPower > self.highestPower then
			updatePower()
		end
	end
	
	local function onRelicRemove(highestPower)
		if highestPower >= self.highestPower then
			updatePower()
		end
	end
	
	local highestPower = 1
	local highestRelicData = nil
	
	for id, relicData in pairs(relicList) do
		if not relicData.Amplified then
			local typeValue = Relics.getRelicsValue(relicData.Name)
			if typeValue >= highestPower then
				highestPower = typeValue
				highestRelicData = relicData 
			end
		end
	end

	-- Determine how to compare the data, based on if the relic is added or removed from the inventory
	if highestRelicData then
		if highestRelicData.Quantity > 0 then
			onRelicAdd(highestPower)
		else
			onRelicRemove(highestPower)
		end
	end
end

function RelicsInventoryModule:applyFilter(filter)
	-- Create a temporary list to then sort from
	local temporaryList = {}
	local filterList = {"Equipped"}

	for key, data in pairs(self.inventory) do
		-- Only search for the filtered type if the filter isn't being deselected
		-- In addition, only add the item to the temporary list if it fits the filter or is equipped
		if filter then
			if filter == "Value" then
				table.insert(
					temporaryList,
					{
						["Key"] = key,
						["Equipped"] = data["Equipped"],
						[filter] = data[filter]
					}
				)
			elseif data["Type"] == filter or data["Equipped"] == 1 then
				table.insert(
					temporaryList,
					{
						["Key"] = key,
						["Equipped"] = data["Equipped"],
						[filter] = data["TypeValue"]
					}
				)
			end
		else
			table.insert(
				temporaryList,
				{
					["Key"] = key,
					["Equipped"] = data["Equipped"]
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
function RelicsInventoryModule:capacityValues(leftVal, rightVal)
	if leftVal then
		self.leftVal = leftVal
	end
	if rightVal then
		self.rightVal = rightVal
	end
	
	local color = Constants.WHITE_COLOR
	if self.leftVal >= self.rightVal then
		color = Constants.RED_COLOR
	end
	
	local updLeftVal = ConvertToNumAbbr(self.leftVal)
	local updRightVal = ConvertToNumAbbr(self.rightVal)
	
	return updLeftVal, updRightVal, color
end

--[[
	Used by RelicsInspectPanel to access the capacity values when needed
]]
function RelicsInventoryModule:getCapacityCallback()
	return self.leftVal, self.rightVal
end

function RelicsInventoryModule:enableInspectPanel(name, info)
	if self.inspectPanel:getDisplayed() ~= name then
		self.inspectPanel:enable(name, info)
	end
end

function RelicsInventoryModule:updatePanel(name, info)
	self.inspectPanel:updatePanel(name, info)
end

function RelicsInventoryModule:disableInspectPanel()
	self.inspectPanel:disable()
end

function RelicsInventoryModule:getInventory()
	return self.inventory
end

function RelicsInventoryModule:getFilters()
	return Filters
end

function RelicsInventoryModule:getDisplayed()
	return self.inspectPanel:getDisplayed()
end

---- CALLBACK FUNCTIONS ----

	--[[
		Sell the selected amount (self.value) or the selected material (self.materialDisplayed) 
	]]
	function RelicsInventoryModule:sellButtonCallback(
		button: TextButton,
		displayed: string?,
		sellValue: number?
	)
		if not button:getAwaiting() and displayed and sellValue then
			ConfirmationPrompt.enable(
				string.format(Constants.CONFIRMATION_SELL_STRING_FORMAT, "x1", self.inventory[displayed].Name, ConvertToNumAbbr(sellValue, "Cash")),
				function()
					local firedTimestamp = workspace:GetServerTimeNow()
					button:enableAwaiting(Sell, firedTimestamp)
					Sell:FireServer(firedTimestamp, displayed, "Relics", 1)
				end
			)
		end
	end
	
	function RelicsInventoryModule:equipButtonCallback(
		button: TextButton,
		displayed: string?,
		name: string?,
		action: string
	)
		if not button:getAwaiting() and displayed and name then
			if action == "Equip" and self.leftVal >= self.rightVal then
				NotificationPrompt.enable("Max relics equipped. Unequip a relic or purchase more slots", false)
			else
				ConfirmationPrompt.enable(
					string.format(Constants.CONFIRMATION_EQUIP_STRING_FORMAT, string.lower(action), name),
					function()
						local firedTimestamp = workspace:GetServerTimeNow()
						button:enableAwaiting(Equip, firedTimestamp)
						Equip:FireServer(firedTimestamp, displayed, action)
					end
				)
			end
		end
	end

--[[
	Cleanup script
]]
function RelicsInventoryModule:destroy()
	table.clear(self.inventory)
	table.clear(self)
end

return RelicsInventoryModule