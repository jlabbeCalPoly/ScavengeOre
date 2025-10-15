-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Particles = ReplicatedStorage.Particles
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility

-- Modules
local Colors = require(HelperModules.Colors)
local Rarities = require(SharedUtility.Rarities)

local ParticleVFXModule = {}

-- Emit particles
local function emitParticlesRecursive(obj)
	-- If the type of the part is a particle emitter, then emit particles
	if obj.ClassName == "ParticleEmitter" then
		obj:Emit(obj:GetAttribute("emitCount"))
	end
	for _, child in pairs(obj:GetChildren()) do
		emitParticlesRecursive(child)
	end
end

function ParticleVFXModule.play(instance, particles)
	local particleEffect = Particles:FindFirstChild(particles)
	if particleEffect then
		particleEffect = particleEffect:Clone()
		particleEffect.CFrame = instance.PrimaryPart.CFrame
		particleEffect.Parent = workspace
		
		emitParticlesRecursive(particleEffect)
		local destructionDelay = particleEffect:GetAttribute("Delay")
		-- If there is a destructionDelay, then delay the destruction of the
		-- particleEffect by that amount of time. Otherwise, immediately destroy
		if destructionDelay then
			task.delay(destructionDelay, function()
				particleEffect:Destroy()
			end)
		else
			particleEffect:Destroy()
		end
	end
end

-- Specific particles to be emitted based on the rarity of the material
function ParticleVFXModule.playRarity(instance, rarity)
	local rarityEffect = Particles:FindFirstChild("Rarity")
	if rarityEffect then
		rarityEffect = rarityEffect:Clone()
		
		local rarityString = Rarities.getRarity(rarity)
		local color = Colors.getRarityColor(rarityString).Static
		
		local particleEmitter = rarityEffect:FindFirstChild("Smoke")
		if not particleEmitter then
			return
		end
		
		particleEmitter.Color = ColorSequence.new(color)
		rarityEffect.Parent = workspace
		rarityEffect.CFrame = instance.PrimaryPart.CFrame
		
		local counter = 0
		local emitCount = particleEmitter:GetAttribute("emitCount")
		while counter < 5 do
			particleEmitter:Emit(emitCount)
			counter += 1
			task.wait(0.2)
		end
		task.wait(1)
		rarityEffect:Destroy()
	end
end

return ParticleVFXModule