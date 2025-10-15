--[[
	Handles what gui to display using a stack
]]

-- Modules
local BlurEffect = require(script.BlurEffect)

local Stack = {}

-- Table to hold the stacked guis
local stack = {}

-- Blur effect
local blurEffect = BlurEffect.new() 

--[[
	Add a new entry to the stack. If there's other entries already present in the stack, 
	run the :sleep() function on the topmost one and enable the newly-pushed module
	Params:
	1) module:        The module to push to the stack
	2) specification: String describing the specific implementation of that module to enable
]]
function Stack.push(module, specification)
	local previousEntry = nil
	if #stack > 0 then
		previousEntry = stack[#stack]
		-- stack was previously empty, so enable the blur
	else
		blurEffect:enable()
	end

	table.insert(
		stack,
		{module, specification}
	)

	if previousEntry then
		local module = unpack(previousEntry)
		module:sleep()
	end
end

--[[
	Remove the topmost entry, then check if there are any entries left. 
	If so, run the :unsleep() function on the topmost one
]]
function Stack.pop()
	-- remove the last element in the stack, but don't retain it
	local previousEntry = nil
	table.remove(stack)
	
	if #stack > 0 then
		previousEntry = stack[#stack]
	-- stack is empty, so unblur
	else
		blurEffect:disable()
	end
	
	if previousEntry then
		local module = unpack(previousEntry)
		module:unsleep()
	end
end

--[[
	Reset the stack, disabling all modules currently inside, then 
]]
function Stack.resetStack(module, specification, scrollPosition)
	-- debounce if the currently enabled module/specification are already on the top of the stack
	local topModule = nil
	local topSpecification = nil
	if #stack > 0 then
		topModule, topSpecification = unpack(stack[#stack])
	end
	
	if module ~= topModule or specification ~= topSpecification then
		-- Transfer each entity into a temporary table, that way the 
		local tempStack = {}
		for _, entry in pairs(stack) do
			table.insert(
				tempStack,
				entry
			)
		end
		table.clear(stack)

		-- Disable all of the entries inside tempStack
		while #tempStack > 0 do
			local module = unpack(table.remove(tempStack))
			while module:disable() == nil do
				task.wait(0.05)
			end
		end

		-- Attempt to enable the specific module. If the enable passes, it will be added to the stack
		module:enable(specification, scrollPosition)
	end
end

return Stack