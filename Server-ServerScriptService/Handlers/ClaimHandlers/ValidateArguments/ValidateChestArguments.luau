function ValidateChestArguments(playerData, timeStamp)
	local dailyClaim = playerData["DailyClaim"]
	-- validate dailyClaim 
	if dailyClaim then
		-- If the claim happens before the 12 hours pass, return false
		if dailyClaim - timeStamp > 0 then
			return false
		end
	end
	playerData["DailyClaim"] = timeStamp + 43200

	return true
end

return ValidateChestArguments