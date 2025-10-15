-- Services
local TweenService = game:GetService("TweenService")

local MeshVFXModule = {}
MeshVFXModule.__index = MeshVFXModule

function MeshVFXModule.new()
	local self = {
		cachedMeshTween = nil
	}
	setmetatable(self, MeshVFXModule)
	
	return self
end

-- Create the cached tween when the LOCAL player swings on an instance
function MeshVFXModule:createTween(instance, speed)
	local meshTweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, true, 0)
	local mesh = instance.Mesh

	self.cachedMeshTween = TweenService:Create(mesh, meshTweenInfo, { CFrame = mesh.CFrame - Vector3.new(0,1,0)})
end

-- Plays the cached mesh tween. However, slightly different from other play functions in 
-- other VFX modules as it also resets the instance's attribute when .Completed is fired
function MeshVFXModule:play(instance)
	-- unlock the instance to be tweened again
	self.cachedMeshTween.Completed:Once(function()
		instance:SetAttribute("VFX", false)
	end)

	self.cachedMeshTween:Play()
end

-- Create a non-cached tween for replicated VFX events
function MeshVFXModule:playReplicatedTween(instance, speed)
	local mesh = instance.Mesh
	local meshTweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, true, 0)
	local meshTween = TweenService:Create(mesh, meshTweenInfo, { CFrame = mesh.CFrame - Vector3.new(0,1,0)})
	
	-- unlock the instance to be tweened again
	meshTween.Completed:Once(function()
		instance:SetAttribute("VFX", false)
	end)

	meshTween:Play()
end

return MeshVFXModule