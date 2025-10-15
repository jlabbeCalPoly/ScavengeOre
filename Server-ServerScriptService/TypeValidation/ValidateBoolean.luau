function ValidateBoolean(param)
	if typeof(param) ~= "boolean" then
		return false
	end
	
	return true
end

return ValidateBoolean