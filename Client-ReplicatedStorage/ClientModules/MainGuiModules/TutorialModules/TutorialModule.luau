-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Folders
local Remotes = ReplicatedStorage.Remotes
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local GuiComponents = HelperModules.GuiComponents
local Buttons = GuiComponents.Buttons

-- Modules
local SFXModule = require(HelperModules.SFXModule)
local NotificationPrompt = require(HelperModules.NotificationPrompt)
local DisconnectAndDestroy = require(HelperModules.DisconnectAndDestroy)
local ConfirmationPrompt = require(HelperModules.ConfirmationPrompt)
local Constants = require(SharedUtility.Constants)
local ChecklistCard = require(GuiComponents.ChecklistCard)
local CustomizableButton = require(Buttons.CustomizableButton)
local BeamModule = require(script.BeamModule)

-- Remotes
local Material = Remotes.Material
local Relic = Remotes.Relic
local Equip = Remotes.Equip
local Sell = Remotes.Sell
local Upgrade = Remotes.Upgrade
local Tutorial = Remotes.Tutorial
local OnPress = Remotes.OnPress
local OnRecipe = Remotes.OnRecipe
local Claim = Remotes.Claim

-- Objects
local Frame = script.Frame

local TutorialModule = {}
TutorialModule.__index = TutorialModule

function TutorialModule.new(
	parent,
	playerData,
	step
)
	local frame = Frame:Clone()
	frame.Parent = parent
	
	local UIScale = frame.UIScale
	
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, true)
	local onStepChangeTween = TweenService:Create(UIScale, tweenInfo, { Scale = 0 })
	
	local self = {
		destroyed = false,
		frame = frame,
		step = step,
		UIScale = UIScale,
		onStepChangeTween = onStepChangeTween,
		tutorialData = playerData["Tutorial"],
		connections = {}
	}
	setmetatable(self, TutorialModule)
	
	self:initialize(playerData)
	
	return self
end

function TutorialModule:endButtonCallback()
	ConfirmationPrompt.enable("Would you like to end the tutorial? (cannot be undone)", function()
		Tutorial:FireServer(true)
	end)
end

function TutorialModule:playTween()
	if self.onStepChangeTween.PlaybackState == Enum.PlaybackState.Playing then
		self.onStepChangeTween:Cancel()
		self.UIScale.Scale = 1
	end
	self.onStepChangeTween:Play()
	
	SFXModule.playSound("Success")
end

function TutorialModule:onStepChange(remoteParser, stringParser, details, satisfiedCallback)
	local height = self.checklistCard:enable(remoteParser, stringParser, details, satisfiedCallback)
	self.frame.Size = UDim2.new(0, 425, 0, 70 + height)
end

--[[
	Create the additional objects needed (Checklist) and store the step data
]]
function TutorialModule:initialize(playerData)
	--self.button = CustomizableButton.new(
	--	self.frame,
	--	Vector2.new(1,0),
	--	UDim2.new(1,0,0,2),
	--	UDim2.new(0,25,0,25),
	--	false,
	--	Constants.RED_COLOR,
	--	Constants.DARK_RED_COLOR,
	--	"x",
	--	"Text",
	--	{"Rotating", "Enlarging"}
	--)
	
	self.checklistCard = ChecklistCard.new(
		self.frame,
		playerData,
		60
	)
	
	self.beam = BeamModule.new()
	
	self.stepData = {
		-- Step 1
		{
			["Initialize"] = function()
				local step = 1
				self.step = step
				self.tutorialData[2] = step
				
				self.frame.StepDescription.Text = 'Mine the "Basic Crate" until you have the listed materials:'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)
				
				local details = {
					{"Mossrock Ore", '1x "Mossrock Ore"', 1},
					{"Hollow Gem", '1x "Hollow Gem"', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end
				
				self.beam:enable()
				self:onStepChange(nil, "Material", details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
				self.beam:disable()
			end
		},
		-- Step 2
		{
			["Initialize"] = function()
				local step = 2
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Go to the Relic Crafter and craft the "Ancient Idol" with the materials!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"Ancient Idol", 'Craft 1x "Ancient Idol"', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self.beam:setTarget(CFrame.new(-13.476, 6.489, -69.037) * CFrame.Angles(0, 45, 0))
				self.beam:enable()
				self:playTween()
				self:onStepChange(Relic, nil, details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
				self.beam:disable()
			end
		},
		-- Step 3
		{
			["Initialize"] = function()
				local step = 3
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Press the "Inventories" button, select "Relics", and equip the "Ancient Idol"!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"Ancient Idol", 'Equip the "Ancient Idol"', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end
				
				self:playTween()
				self:onStepChange(Equip, nil, details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
			end
		},
		-- Step 4
		{
			["Initialize"] = function()
				local step = 4
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Now you deal more damage! Go back to the "Basic Crate" and mine until you get any material!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"nil", 'Mine x1 material"', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self.beam:setTarget(CFrame.new(-13.476, 2.489, -19.525) * CFrame.Angles(0, 45, 0))
				self.beam:enable()
				self:playTween()
				self:onStepChange(nil, "Material", details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
				self.beam:disable()
			end
		},
		-- Step 5
		{
			["Initialize"] = function()
				local step = 5
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Press the "Inventories" button, select "Materials", and sell the material!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"nil", 'Sell x1 material', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self:playTween()
				self:onStepChange(nil, "SellAndSellAll", details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
			end
		},
		-- Step 6
		{
			["Initialize"] = function()
				local step = 6
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Nice! Now, mine and sell materials until you have a cash balance of at least $25!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"Cash", '$25 cash balance', 25}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self:playTween()
				self:onStepChange(nil, "SellAndSellAll", details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
			end
		},
		-- Step 7
		{
			["Initialize"] = function()
				local step = 7
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Press the "Upgrades" button, select "Upgrade Storage", and upgrade to level 2!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"Storage", 'Upgrade storage to level 2', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self:playTween()
				self:onStepChange(Upgrade, nil, details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
			end
		},
		-- Step 8
		{
			["Initialize"] = function()
				local step = 8
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Nice, now you can hold more materials! To move onto the next step, press the "Discoveries" button!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"Discoveries", 'Open the "Discoveries" menu', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self:playTween()
				self:onStepChange(OnPress, nil, details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
			end
		},
		-- Step 9
		{
			["Initialize"] = function()
				local step = 9
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Great! To move onto the next step, press the "Upgrades" button, then select "Upgrade Tool"'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"Upgrade Tool", 'Open the "Upgrade Tool" menu', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self:playTween()
				self:onStepChange(OnPress, nil, details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
			end
		},
		-- Step 10
		{
			["Initialize"] = function()
				local step = 10
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Upgrading your tool requires materials! To move onto the next step, mine x3 of any material!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"nil", 'Mine x3 materials', 3}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self:playTween()
				self:onStepChange(nil, "Material", details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
			end
		},
		-- step 11
		{
			["Initialize"] = function()
				local step = 11
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Lets earn materials/items another way! Press the "Rewards" Button, then select "Weekly"!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"Weekly", 'Open the "Weekly" rewards menu', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self:playTween()
				self:onStepChange(OnPress, nil, details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
			end
		},
		-- step 12
		{
			["Initialize"] = function()
				local step = 12
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Earn increasingly-better rewards each day! Claim "Day 1" rewards to move onto the next step!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"Weekly", 'Claim "Day 1" rewards!', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self:playTween()
				self:onStepChange(Claim, nil, details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
			end
		},
		-- step 13
		{
			["Initialize"] = function()
				local step = 13
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'Now lets check out your daily tasks! Press the "Rewards" Button, then select "Daily"!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"Daily", 'Open the "Daily" rewards menu', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self:playTween()
				self:onStepChange(OnPress, nil, details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
			end
		},
		-- Step 14
		{
			["Initialize"] = function()
				local step = 14
				self.step = step
				self.tutorialData[2] = step
												  
				self.frame.StepDescription.Text = 'Tasks reset each day! To move onto the last step, go to the Relic Crafter and open the menu!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"Relic Crafter", 'Open the Relic Crafter menu"', 1}
				}
				local satisfiedCallback = function()
					Tutorial:FireServer(false, step + 1)
					self.stepData[step]["Cleanup"]()
					self.stepData[step + 1]["Initialize"]()
				end

				self.beam:setTarget(CFrame.new(-13.476, 6.489, -69.037) * CFrame.Angles(0, 45, 0))
				self.beam:enable()
				self:playTween()
				self:onStepChange(OnPress, nil, details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
				self.beam:disable()
			end
		},
		-- Step 15
		{
			["Initialize"] = function()
				local step = 15
				self.step = step
				self.tutorialData[2] = step

				self.frame.StepDescription.Text = 'To show the crafting recipe on your screen, scroll and press "Display Recipe" for "Carved Fang"!'
				self.frame.StepNumber.Text = string.format(Constants.STEP_STRING_FORMAT, step, #self.stepData)

				local details = {
					{"nil", 'Display the recipe for "Carved Fang"', 1}
				}
				local satisfiedCallback = function()
					self.stepData[step]["Cleanup"]()
					
					SFXModule.playSound("LevelUp")
					NotificationPrompt.enable('Tutorial completed! Now, try to craft the "Carved Fang"!', true)
					
					Tutorial:FireServer(true)
				end

				self:playTween()
				self:onStepChange(OnRecipe, nil, details, satisfiedCallback)
			end,
			["Cleanup"] = function()
				self.checklistCard:reset()
			end
		}
	}

	table.insert(
		self.connections,
		Tutorial.OnClientEvent:Connect(function()
			self.stepData[self.step]["Cleanup"]()
			self.tutorialData[1] = true
			self:destroy()
		end)
	)
	
	--self.button:enable(function()
	--	self:endButtonCallback()
	--end)
	
	self.stepData[self.step]["Initialize"]()
end

function TutorialModule:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true
	
	DisconnectAndDestroy(self.connections)
	--self.button:destroy()
	self.checklistCard:destroy()
	self.beam:destroy()
	self.frame:Destroy()
	table.clear(self)
end

return TutorialModule