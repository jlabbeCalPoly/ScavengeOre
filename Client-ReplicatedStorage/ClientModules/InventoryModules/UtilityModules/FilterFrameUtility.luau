-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local Buttons = HelperModules.GuiComponents.Buttons

-- Modules
local ScalableButton = require(Buttons.ScalableButton)

local FilterFrameUtility = {}

--[[
	Create a scalable button for each filter, then initialize the corresponding connection
]]
function FilterFrameUtility.initializeButtons(filters: { string }, filterFrame, connections, callback)
	local buttonList = {}
	local totalButtonSize = 0
	
	--[[
		For each filter, create a new scalable button and add its width to the total size
	    Then, add the corresponding connection to the connections list
	]]
	for _, filter in pairs(filters) do
		local obj, buttonSize = ScalableButton.new(filter, filterFrame)
		totalButtonSize += buttonSize
		
		-- Insert the Activated event into the connections table
		table.insert(
			connections,
			obj.button.Activated:Connect(function()
				callback(filter)
			end)
		)
		
		-- Insert the object into the buttonList table
		table.insert(
			buttonList,
			obj
		)
	end
	
	return buttonList, totalButtonSize
end

--[[
	Calculate the size of the filter frame
]]
function FilterFrameUtility.calculateFilterFrameSize(buttonCount: number, totalButtonSize: number)
	-- Account for padding
	totalButtonSize += ((buttonCount - 1) * 5)
	
	if totalButtonSize < 230 then
		totalButtonSize = 230
	end
	
	return UDim2.new(0, totalButtonSize, 0, 0)
end

return FilterFrameUtility