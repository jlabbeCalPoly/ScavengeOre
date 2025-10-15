local Conditions = {}

function Conditions.setNumberCondition(conditionValue)
	return function(value)
		return value < conditionValue
	end
end

function Conditions.setBooleanCondition()
	return function(value)
		return value
	end
end

function Conditions.setCondition(conditionType, conditionValue)
	if conditionType == "NumberCondition" then
		return Conditions.setNumberCondition(conditionValue)
	elseif conditionType == "BooleanCondition" then
		return Conditions.setBooleanCondition()
	end
end

return Conditions