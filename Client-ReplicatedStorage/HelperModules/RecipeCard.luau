-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage.Remotes
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local GuiComponents = HelperModules.GuiComponents
local Buttons = GuiComponents.Buttons

-- Modules
local ConfirmationPrompt = require(HelperModules.ConfirmationPrompt)
local NotificationPrompt = require(HelperModules.NotificationPrompt)
local Constants = require(SharedUtility.Constants)
local ChecklistCard = require(GuiComponents.ChecklistCard)
local CustomizableButton = require(Buttons.CustomizableButton)

-- Remotes
local Material = Remotes.Material
local OnRecipe = Remotes.OnRecipe

-- Objects
local Frame = script.Frame
local self = nil

local RecipeCard = {}

function RecipeCard.setup(
	parent,
	playerData
)
	local frame = Frame:Clone()
	frame.Parent = parent
	
	local checklistCard = ChecklistCard.new(frame, playerData, 60)
	
	local button = CustomizableButton.new(
		frame,
		Vector2.new(1,0),
		UDim2.new(1,0,0,2),
		UDim2.new(0,25,0,25),
		false,
		Constants.RED_COLOR,
		Constants.DARK_RED_COLOR,
		"x",
		"Text",
		{"Rotating", "Enlarging"}
	)
	
	self = {
		enabled = false,
		transitioning = false,
		playerData = playerData,
		frame = frame,
		checklistCard = checklistCard,
		button = button,
		name = nil
	}
end

function RecipeCard.enable(name, details)
	if not self.playerData["Tutorial"][1] then
		if self.playerData["Tutorial"][2] >= 15 then
			OnRecipe:Fire()
		else
			NotificationPrompt.enable("You must reach step 15 in the tutorial to access this feature", false)
			return
		end
	end
	
	if self.name == name or self.transitioning then
		return
	end
	self.transitioning = true
	
	if self.enabled then
		RecipeCard.disable()
	end
	self.enabled = true
	
	self.frame.GuiTitle.Text = string.format('"%s" recipe:', name)
	
	local parsedDetails = {}
	for _, detail in pairs(details) do
		table.insert(
			parsedDetails,
			{
				detail[1], 
				string.format('x%d "%s"', detail[2], detail[1]),
				detail[2]
			}
		)
	end
	
	local checklistHeight = self.checklistCard:enable(nil, "MaterialsAndUpgrade", parsedDetails, nil)
	self.button:enable(function()
		ConfirmationPrompt.enable("Would you like to close the recipe display?", function()
			RecipeCard.disable()
		end)
	end)
	self.frame.Size = UDim2.new(0,425,0,checklistHeight + 35)
	
	self.frame.Visible = true
	
	self.transitioning = false
end

function RecipeCard.disable()
	if not self.enabled then
		return
	end
	self.enabled = false
	
	self.frame.Visible = false
	
	self.checklistCard:reset()
	self.button:disable()
end

return RecipeCard