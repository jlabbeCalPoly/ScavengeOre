-- Services
local Players = game:GetService("Players")

-- Objects
local SwingHitbox = script.Swing
local PromptHitbox = script.Prompt

local Hitboxes = {}

-- Clone the hitboxes for the player, return the objects to be stored in StateModule
function Hitboxes.hitboxes()
	local primaryPart = Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	while primaryPart == nil do
		task.wait(0.1)
		primaryPart = Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	end

	local swingHitbox = SwingHitbox:Clone()
	local weld = Instance.new("WeldConstraint")
	swingHitbox.CFrame = primaryPart.CFrame + (primaryPart.CFrame.LookVector * 2)
	swingHitbox.Parent = workspace
	weld.Part0 = primaryPart
	weld.Part1 = swingHitbox
	weld.Parent = swingHitbox
	
	local promptHitbox = PromptHitbox:Clone()
	local weld = Instance.new("WeldConstraint")
	promptHitbox.CFrame = primaryPart.CFrame * CFrame.fromEulerAngles(0, math.pi/2, math.pi/2)
	promptHitbox.Parent = workspace
	weld.Part0 = primaryPart
	weld.Part1 = promptHitbox
	weld.Parent = promptHitbox

	return swingHitbox, promptHitbox
end

return Hitboxes