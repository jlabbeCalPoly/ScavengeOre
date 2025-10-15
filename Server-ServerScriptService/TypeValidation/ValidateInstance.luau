function ValidateInstance(param, instance: string)
	if typeof(param) ~= "Instance" then
		return false
	end

	return param:IsA(instance)
end

return ValidateInstance