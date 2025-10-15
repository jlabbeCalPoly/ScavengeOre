function ValidateWeeklyArguments(playerData, timeStamp)
	local weeklyData = playerData["WeeklyData"]
	local claimTime = weeklyData["ClaimTime"]
	local day = weeklyData["Day"]
	
	-- Validate that the player has either 1) completed the tutorial or at least reached step 
	local tutorialData = playerData["Tutorial"]
	if not tutorialData[1] and tutorialData[2] < 12 then
		return false, "Reach stage 12 in the tutorial to claim!"
	end
	
	-- validate claimTime 
	if claimTime then
		-- If the claim happens before the 24 hours pass, return false
		if claimTime - timeStamp > 0 then
			return false
		end
	end
	weeklyData["ClaimTime"] = timeStamp + 86400

	return true
end

return ValidateWeeklyArguments