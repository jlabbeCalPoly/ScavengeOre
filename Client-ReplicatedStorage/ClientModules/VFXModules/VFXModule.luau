-- Modules
local HighlightVFXModule = require(script.HighlightVFXModule)
local MeshVFXModule = require(script.MeshVFXModule)
local MaterialVFXModule = require(script.MaterialVFXModule)
local ParticleVFXModule = require(script.ParticleVFXModule)
local HitmarkerVFXModule = require(script.HitmarkerVFXModule)

local VFXModule = {}
VFXModule.__index = VFXModule

-- VFXModule handles the visual effects generated from swinging
function VFXModule.new()
	local HighlightVFXModule = HighlightVFXModule.new()
	local MeshVFXModule = MeshVFXModule.new()
	local MaterialVFXModule = MaterialVFXModule.new()
	local HitmarkerVFXModule = HitmarkerVFXModule.new()
	
	local self = {
		HighlightVFXModule = HighlightVFXModule,
		MeshVFXModule = MeshVFXModule,
		MaterialVFXModule = MaterialVFXModule,
		HitmarkerVFXModule = HitmarkerVFXModule,
		
		-- Cache the last instance to avoid creating a new tween/doing redundant logic each time
		cachedInstance = nil,
		cachedSpeed = nil,
	}
	setmetatable(self, VFXModule)
	
	return self
end

-- Specific function for smoke particles that occur after breaking an entity
function VFXModule:playRarityVFX(instance, rarity)
	ParticleVFXModule.playRarity(instance, rarity)
end

function VFXModule:playParticleVFX(instance, particles)
	ParticleVFXModule.play(instance, particles)
end

function VFXModule:playMaterialVFX(instance, material)
	self.MaterialVFXModule:play(instance, material)
end

function VFXModule:playHitmarkerVFX(instance, power)
	self.HitmarkerVFXModule:play(instance, power)
end

-- Initally called when the client swings on an interactable, checks if tweens need to be updated or not
-- Directly handles the corresponding VFX (highlight, mesh, particles)
function VFXModule:VFX(instance, speed, particles)
	-- Make sure the instance isn't currently being VFX'ed for highlight/mesh
	if not instance:GetAttribute("VFX") then
		instance:SetAttribute("VFX", true)
		-- Create/play the tweens regarding the position/color of the interactable mesh
		if instance ~= self.cachedInstance or speed ~= self.cachedSpeed then
			self.cachedInstance = instance
			self.cachedSpeed = speed
			
			self.HighlightVFXModule:createTween(instance, speed * 2)
			self.MeshVFXModule:createTween(instance, speed)
		end
		
		self.HighlightVFXModule:play()
		self.MeshVFXModule:play(instance)
	end
	
	-- Always do particle VFX
	ParticleVFXModule.play(instance, particles)
end

-- Called when the player recieves a replication event from the server
-- Only want to create a VFX if:
-- 1) Model is streamed into the workspace
-- 2) The instance isn't currently in the middle of its own animation
function VFXModule:ReplicatedVFX(instance, speed, particles)
	local instanceVerified = workspace.Entities:FindFirstChild(instance.Name)
	if instanceVerified ~= nil and not instanceVerified:GetAttribute("VFX") then
		instanceVerified:SetAttribute("VFX", true)
		self.HighlightVFXModule:playReplicatedTween(instanceVerified, speed)
		self.MeshVFXModule:playReplicatedTween(instanceVerified, speed)
		ParticleVFXModule.play(instanceVerified, particles)
	end
end

function VFXModule:onResize(scale)
	self.HitmarkerVFXModule:onResize(scale)
end

return VFXModule