-- Folders
local SharedUtility = script.Parent.SharedUtility

-- Modules
local Constants = require(SharedUtility.Constants)

local Bonus = {}

--[[
	calculateBonus returns the “bonus” (number) and which bonus spot (specified by “index”) to delay, if any
]]
function Bonus.calculateBonus(elapsed, bonusPosition)
	-- default values for the bonus and position
	local bonus = 0
	local index = nil
	
	-- calculate the position of the click (between 0 - 400px)
	local position
	local relativeElapsed = elapsed % (Constants.BONUS_CURSOR_SPEED * 2)
	local moveSpeed = 400 / Constants.BONUS_CURSOR_SPEED
	-- check if the cursor is moving to the left
	if relativeElapsed > Constants.BONUS_CURSOR_SPEED then
		position = 400 - math.round((relativeElapsed % Constants.BONUS_CURSOR_SPEED) * moveSpeed)
	else
		position = math.round(relativeElapsed * moveSpeed)
	end

	local bonusEndPosition = bonusPosition + Constants.BONUS_FRAME_SIZE
		-- left most small bonus box, 0.25 extra
	if position >= bonusPosition 
		and position <= bonusPosition + Constants.BONUS_SMALL_OFFSET then
		bonus = 0.25
		index = "1"
	-- right most small bonus box, 0.25 extra
	elseif position >= bonusEndPosition - Constants.BONUS_SMALL_OFFSET 
		and position <= bonusEndPosition then
		bonus = 0.25
		index = "3"
	-- center large bonus box, 0.5 extra
	elseif position >= bonusPosition + Constants.BONUS_LARGE_OFFSET 
		and position <= bonusEndPosition - Constants.BONUS_LARGE_OFFSET then
		bonus = 0.5
		index = "2"
	end
	
	return bonus, index
end

return Bonus