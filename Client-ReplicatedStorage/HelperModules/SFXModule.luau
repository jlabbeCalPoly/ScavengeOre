-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local Sounds = ReplicatedStorage.Sounds

-- Modules
local Rarities = require(SharedUtility.Rarities)

-- Objects
local self = nil

local SFXModule = {}

function SFXModule.setup(settings)
	self = {
		indexedFolders = {
			["Craft"] = Sounds.Craft,
			["Rarities"] = Sounds.Rarities,
			["Wood"] = Sounds.Wood,
			["Rock"] = Sounds.Rock
		},
		settings = settings
	}
end

function SFXModule:stopMusic()
	local SFX = Sounds:FindFirstChild("Music")
	if SFX then
		SFX:Stop()
	end
end

function SFXModule.playMusic()
	if self == nil or self.settings[3][2] then
		local SFX = Sounds:FindFirstChild("Music")
		if SFX then
			SFX:Play()
		end
	end
end

function SFXModule.playRaritySFX(rarity: number)
	-- Determine if the player has sound effects on or off
	if self == nil or self.settings[3][2] then
		local soundFolder = self.indexedFolders["Rarities"]
		local SFX = soundFolder:FindFirstChild(Rarities.getRarity(rarity))
		if SFX then
			if SFX.isPlaying then
				SFX:Stop()
			end
			SFX:Play()
		end
	end
end

function SFXModule.playDamageSFX(instance, soundType: string)
	-- Determine if the player has sound effects on or off
	if self == nil or self.settings[3][2] then
		local soundFolder = self.indexedFolders[soundType]:GetChildren()
		if #soundFolder > 0 then
			local SFX = soundFolder[math.random(1, #soundFolder)]:Clone()
			SFX.Parent = instance.PrimaryPart

			SFX.Ended:Once(function()
				SFX:Destroy()
			end)

			SFX:Play()
		end
	end
end

function SFXModule.playCraftSound()
	if self == nil or self.settings[3][2] then
		local SFX = Sounds:FindFirstChild("Craft")
		if SFX then
			for index = 1, 3 do
				local sfx = SFX:Clone()
				sfx.Parent = workspace
				
				sfx.Ended:Once(function()
					sfx:Destroy()
				end)
				
				sfx:Play()
				
				task.wait(0.2)
			end
		end
	end
end

function SFXModule.playSound(id: string)
	if self == nil or self.settings[3][2] then
		local SFX = Sounds:FindFirstChild(id)
		if SFX then
			if SFX.isPlaying then
				SFX:Stop()
			end
			SFX:Play()
		end
	end
end

return SFXModule