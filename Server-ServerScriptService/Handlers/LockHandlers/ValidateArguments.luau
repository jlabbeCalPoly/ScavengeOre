function ValidateArguments(timeStamp: number,
						   material: string,
						   action: string,
						   materialsInventory)
	-- validate timestamp
	local now = workspace:GetServerTimeNow()
	if timeStamp > now then
		return false
	end
	if timeStamp < now - 1 then
		return false
	end
	
	-- validate material
	local materialInfo = materialsInventory[material]
	if materialInfo == nil then
		return false
	end
	
	if material.Quantity == 0 then
		return false
	end
	
	-- validate action
	if action == "Lock" then
		if not materialInfo["Lock"] then
			materialInfo["Lock"] = true
			return true, true
		end
	elseif action == "Unlock" then
		if materialInfo["Lock"] then
			materialInfo["Lock"] = nil
			return true, nil
		end
	end
	
	return false
end

return ValidateArguments