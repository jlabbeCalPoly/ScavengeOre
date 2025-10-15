-- Services
local Players = game:GetService("Players")

-- Objects
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ScreenOrientation = {}

function ScreenOrientation.setOrientation()
	playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
end

return ScreenOrientation