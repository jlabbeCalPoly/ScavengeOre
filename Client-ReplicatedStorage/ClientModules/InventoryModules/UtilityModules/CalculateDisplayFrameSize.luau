--[[
	Return the correct size for ElementFrame based on the number of elements,
	Currently, the size for each item is 60px and the padding between is 5 px
]]

function CalculateDisplayFrameSize(elements: number)
	local rows = math.ceil(elements / 4)
	-- Each row will be 60px tall, one less "row" of padding between the rows of elements
	local size = ((rows * 60) + ((rows - 1) * 5))
	
	-- Make sure the calculated size isn't smaller than the size of the frame
	if size < 190 then
		size = 190
	end

	return UDim2.new(0,0,0,size)
end

return CalculateDisplayFrameSize