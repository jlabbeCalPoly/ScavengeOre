-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules

-- Modules
local DisconnectAndDestroy = require(HelperModules.DisconnectAndDestroy)

-- Objects
local BeamObject = script.BeamObject
local player = Players.LocalPlayer

local BeamModule = {}
BeamModule.__index = BeamModule

function BeamModule.new()
	local beamObject = BeamObject:Clone()
	beamObject.Parent = workspace
	
	local playerPrimaryPart = player.Character.PrimaryPart
	while playerPrimaryPart == nil do
		task.wait(0.1)
		playerPrimaryPart = player.Character.PrimaryPart
	end
	
	local playerAttachment = playerPrimaryPart:WaitForChild("RootAttachment")
	beamObject.Beam.Attachment0 = playerAttachment
	
	local touchPart = beamObject.TouchPart
	
	local self = {
		enabled = false,
		beamObject = beamObject,
		playerAttachment = playerAttachment,
		touchPart = touchPart,
		connections = {}
	}
	setmetatable(self, BeamModule)
	
	return self
end

function BeamModule:setTarget(cFrame: CFrame)
	self.beamObject.CFrame = cFrame
end

function BeamModule:enable()
	if self.enabled then
		return
	end
	self.enabled = true
	
	table.insert(
		self.connections,
		self.touchPart.Touched:Connect(function(hit)
			local character = hit.Parent
			local hitPlayer = game.Players:GetPlayerFromCharacter(character)
			if hitPlayer and hitPlayer.UserId == player.UserId then
				self:disable()
			end
		end)
	)
	
	self.beamObject.Beam.Enabled = true
	self.beamObject.Parent = workspace
end

function BeamModule:disable()
	if not self.enabled then
		return
	end
	self.enabled = false
	
	DisconnectAndDestroy(self.connections)

	self.beamObject.Beam.Enabled = false
	self.beamObject.Parent = nil
end

function BeamModule:destroy()
	self:disable()
	self.beamObject:Destroy()
end

return BeamModule