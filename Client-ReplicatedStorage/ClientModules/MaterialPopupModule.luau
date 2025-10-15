-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Folders
local HelperModules = ReplicatedStorage.HelperModules
local SharedUtility = HelperModules.SharedUtility
local Utility = HelperModules.Utility
local GuiParticles = HelperModules.GuiComponents.GuiParticles

-- Modules
local Colors = require(HelperModules.Colors)
local Constants = require(SharedUtility.Constants)
local Rarities = require(SharedUtility.Rarities)
local LoadImage = require(Utility.LoadImage)
local GlowGuiParticles = require(GuiParticles.GlowGuiParticles)

-- Objects
local ScreenGui = script.ScreenGui
local MaterialPopupTemplate = script.PopupTemplate

-- Layout information, based on the number of materials received
local Layouts = {
	{
		["Size"] = UDim2.new(0.65, 0, 0.65, 0),
		["Positions"] = {
			UDim2.new(0.5, 0, 0.45, 0)
		}
	},
	{
		["Size"] = UDim2.new(0.49, 0, 0.49, 0),
		["Positions"] = {
			UDim2.new(0.25, 0, 0.5, 0),
			UDim2.new(0.75, 0, 0.5, 0)
		}
	},
	{
		["Size"] = UDim2.new(0.32, 0, 0.45, 0),
		["Positions"] = {
			UDim2.new(0.5, 0, 0.2, 0),
			UDim2.new(0.17, 0, 0.5, 0),
			UDim2.new(0.83, 0, 0.5, 0)
		}
	},
}

local MaterialPopupModule = {}
MaterialPopupModule.__index = MaterialPopupModule

--[[
	Create a new MaterialPopup, organizes materials recieved into different layouts for display
]]
function MaterialPopupModule.new(settings)
	local gui = ScreenGui:Clone()
	gui.Parent = Players.LocalPlayer.PlayerGui
	
	local scale = gui.UIScale
	local Frame = gui.Frame
	local tweenInfo = TweenInfo.new(Constants.CAMERA_SPEED_SLOW, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenIn = TweenService:Create(Frame, tweenInfo, { Size = Constants.MATERIAL_POPUP_FRAME_LARGE })
	local tweenOut = TweenService:Create(Frame, tweenInfo, { Size = Constants.MATERIAL_POPUP_FRAME_SMALL })
	
	local AdditionalMaterials = Frame.AdditionalMaterials
	
	local self = {
		gui = gui,
		scale = scale,
		tweenIn = tweenIn,
		tweenOut = tweenOut,
		settings = settings,
		additionalMaterials = AdditionalMaterials,
		popups = {},
		resetTasks = {}
	}
	-- Clone material popups, attaching a GlowGuiParticle module to each
	-- Store the popup and the corresponding GlowGuiParticle into the popups table for later use
	local index = 1
	while index <= 3 do
		local materialPopup = MaterialPopupTemplate:Clone()
		materialPopup.Parent = gui.Frame
		
		local glowGuiParticles = GlowGuiParticles.new(materialPopup.ParticleSpot, 10)
		table.insert(
			self.popups,
			{
				["MaterialPopup"] = materialPopup, 
				["GuiParticles"] = glowGuiParticles
			}
		)
		index += 1
	end
	setmetatable(self, MaterialPopupModule)
	
	return self
end

--[[
	Display up to 3 materials in the popup
	params:
		relicList: {Relic: string, Rarity: string, Quantity: number}
		materialList: {Material: string, Rarity: string, Quantity: number}
]]
function MaterialPopupModule:enable(relicList, materialList)
	-- Determine if the player has the material popup enabled or disabled
	if not self.settings[6][2] or (not relicList and not materialList) then
		return
	end
	
	-- disable any reset tasks that may be in the resetTasks folder
	self.gui.Enabled = false 
	
	for _, resetTask in pairs(self.resetTasks) do
		task.cancel(resetTask)
	end
	table.clear(self.resetTasks)
	
	-- cancel the tweenIn/tweenOut if it's currently playing, then set the size of 
	-- the frame to a slightly smaller size to give the "Pop in" effect
	if self.tweenIn.PlaybackState == Enum.PlaybackState.Playing then
		self.tweenIn:Cancel()
	end
	if self.tweenOut.PlaybackState == Enum.PlaybackState.Playing then
		self.tweenOut:Cancel()
	end
	
	self.gui.Frame.Size = Constants.MATERIAL_POPUP_FRAME_SMALL
	
	-- determine the specific layout to use based on the number of materials in the list 
	local layout
	local relicCount = 0
	local materialCount = 0
	if relicList then
		relicCount = #relicList
	end
	if materialList then
		materialCount = #materialList
	end
	
	local count = relicCount + materialCount
	if count >= 3 then
		layout = Layouts[3]
	else
		layout = Layouts[count]
	end
	
	local function setPopupDetails(
		index,
		popup,
		guiParticles,
		name,
		quantity,
		rarityText,
		rarity,
		isNew
	)
		guiParticles:setColor(rarity)
		guiParticles:enable()
		
		-- Set the content of the popup
		local color = Colors.getRarityColor(rarity).Gradient
		local Rarity = popup.Rarity
		Rarity.Text = rarityText
		Rarity.UIGradient.Color = color
		
		local MaterialImage = popup.MaterialImage
		MaterialImage.Image = LoadImage(name)

		local MaterialName = popup.MaterialName
		MaterialName.Text = name

		local Quantity = popup.Quantity
		Quantity.Text = "+"..quantity
		
		-- Set the physical properties of the popup
		popup.Size = layout.Size
		popup.Position = layout.Positions[index]

		-- If the material has the "New" key present, enable the new text
		if isNew then
			popup.New.Visible = true
		else
			popup.New.Visible = false
		end

		popup.Visible = true
	end
	
	-- Now, update the sizing/positioning/visibility of the specific popups
	local index = 1
	while index <= 3 do
		local popup = self.popups[index].MaterialPopup
		local guiParticles = self.popups[index].GuiParticles
		
		local info
		local rarityText
		local rarity
		if relicList and index <= relicCount then
			info = relicList[index]
			-- Relic guiParticles color defaults to legendary
			rarityText = "Special"
			rarity = Rarities.getRarity(5)
		elseif materialList and index - relicCount <= materialCount then
			info = materialList[index - relicCount]
			rarityText = Rarities.getRarity(info.Rarity)
			rarity = rarityText
		end
			
		if info then
			setPopupDetails(
				index,
				popup,
				guiParticles,
				info.Name,
				info.QuantityChanged,
				rarityText,
				rarity,
				info.New
			)
		else
			-- There are no more materials to display, so make the popup not visible
			popup.Visible = false
		end
		
		index += 1
	end
	
	-- Set the quantity label, if needed
	local extraMaterials = count - 3
	if extraMaterials > 0 then
		self.additionalMaterials.Text = string.format(Constants.EXTRA_MATERIALS_STRING_FORMAT, extraMaterials)
	else
		self.additionalMaterials.Text = ""
	end
	
	-- Set up cleanup events to reset the popup if needed
	table.insert(
		self.resetTasks,
		task.delay(4, function()
			-- Wait for the tweenOut to complete, then disable the guiParticles
			self.tweenOut.Completed:Once(function(playbackState)
				if playbackState ~= Enum.PlaybackState.Cancelled then
					local index = 1
					while index <= 3 do
						local popup = self.popups[index].MaterialPopup
						local guiParticles = self.popups[index].GuiParticles

						popup.Visible = false
						guiParticles:disable()
						index += 1
					end

					self.gui.Enabled = false
				end 
			end)	

			self.tweenOut:Play()
		end)
	)
	
	self.tweenIn:Play()
	self.gui.Enabled = true 
end

function MaterialPopupModule:onResize(scale)
	self.scale.Scale = scale
end

return MaterialPopupModule