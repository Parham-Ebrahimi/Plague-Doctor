local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteEvents = require(Shared.core.RemoteEvents)
local Humours = require(Shared.core.Humours)

local localPlayer = Players.LocalPlayer
local clientFolder = localPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local proximityScript = clientFolder:WaitForChild("world"):WaitForChild("ProximityDetector")
local NPCInRange = proximityScript:WaitForChild("NPCInRange")
local NPCOutOfRange = proximityScript:WaitForChild("NPCOutOfRange")
local examinationStateScript = clientFolder:WaitForChild("world"):WaitForChild("ExaminationState")
local ExaminationState = require(examinationStateScript)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TreatmentInterface"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local promptFrame = Instance.new("Frame")
promptFrame.Name = "InteractPrompt"
promptFrame.Size = UDim2.fromOffset(180, 40)
promptFrame.Position = UDim2.new(0.5, -90, 1, -120)
promptFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
promptFrame.BackgroundTransparency = 0.2
promptFrame.BorderSizePixel = 0
promptFrame.Visible = false
promptFrame.Parent = screenGui

local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.fromScale(1, 1)
promptLabel.BackgroundTransparency = 1
promptLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
promptLabel.Font = Enum.Font.GothamBold
promptLabel.TextSize = 18
promptLabel.Text = "[E] Examine"
promptLabel.Parent = promptFrame

local panel = Instance.new("Frame")
panel.Name = "TreatmentPanel"
panel.Size = UDim2.new(0.45, 0, 1, 0)
panel.Position = UDim2.new(0.55, 0, 0, 0)
panel.BackgroundColor3 = Color3.fromRGB(28, 26, 22)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 70, 50)
stroke.Thickness = 2
stroke.Parent = panel

-- ---------------------------------------------------------------------------
-- Panel contents
--
-- Layout-only structure for the four-humours examination. NPC fields are
-- hardcoded for now; humour values start as "—" and are designed to be filled
-- in later by body-region clicking (see humourValueLabels / the SetHumour
-- BindableEvent below). The Leave button is pinned to the panel bottom and is
-- the only interactive element for now.
-- ---------------------------------------------------------------------------

-- Stacked content area. Leaves ~72px at the bottom of the panel for Leave.
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, 0, 1, -72)
contentFrame.Position = UDim2.fromOffset(0, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.Parent = panel

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingLeft = UDim.new(0, 20)
contentPadding.PaddingRight = UDim.new(0, 20)
contentPadding.PaddingTop = UDim.new(0, 20)
contentPadding.Parent = contentFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 8)
contentLayout.Parent = contentFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NPCName"
nameLabel.Size = UDim2.new(1, 0, 0, 34)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(230, 215, 170)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 22
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Text = "Leofwine Brewstere"
nameLabel.LayoutOrder = 1
nameLabel.Parent = contentFrame

local occupationLabel = Instance.new("TextLabel")
occupationLabel.Name = "NPCOccupation"
occupationLabel.Size = UDim2.new(1, 0, 0, 22)
occupationLabel.BackgroundTransparency = 1
occupationLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
occupationLabel.Font = Enum.Font.Gotham
occupationLabel.TextSize = 16
occupationLabel.TextXAlignment = Enum.TextXAlignment.Left
occupationLabel.Text = "Occupation: Weaver"
occupationLabel.LayoutOrder = 2
occupationLabel.Parent = contentFrame

local ageLabel = Instance.new("TextLabel")
ageLabel.Name = "NPCAge"
ageLabel.Size = UDim2.new(1, 0, 0, 22)
ageLabel.BackgroundTransparency = 1
ageLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
ageLabel.Font = Enum.Font.Gotham
ageLabel.TextSize = 16
ageLabel.TextXAlignment = Enum.TextXAlignment.Left
ageLabel.Text = "Age: 37"
ageLabel.LayoutOrder = 3
ageLabel.Parent = contentFrame

local descriptionLabel = Instance.new("TextLabel")
descriptionLabel.Name = "NPCDescription"
descriptionLabel.Size = UDim2.new(1, 0, 0, 0)
descriptionLabel.AutomaticSize = Enum.AutomaticSize.Y
descriptionLabel.BackgroundTransparency = 1
descriptionLabel.TextColor3 = Color3.fromRGB(220, 220, 200)
descriptionLabel.Font = Enum.Font.Gotham
descriptionLabel.TextSize = 14
descriptionLabel.TextWrapped = true
descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
descriptionLabel.Text =
	"Notes: A widowed weaver who tends to her loom and her late husband's shop. "
	.. "Has seemed more fatigued of late and complains of poor sleep and "
	.. "wandering chills."
descriptionLabel.LayoutOrder = 4
descriptionLabel.Parent = contentFrame

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(1, 0, 0, 2)
divider.BackgroundColor3 = Color3.fromRGB(80, 70, 50)
divider.BorderSizePixel = 0
divider.LayoutOrder = 5
divider.Parent = contentFrame

local humoursHeader = Instance.new("TextLabel")
humoursHeader.Name = "HumoursHeader"
humoursHeader.Size = UDim2.new(1, 0, 0, 28)
humoursHeader.BackgroundTransparency = 1
humoursHeader.TextColor3 = Color3.fromRGB(230, 215, 170)
humoursHeader.Font = Enum.Font.GothamBold
humoursHeader.TextSize = 18
humoursHeader.TextXAlignment = Enum.TextXAlignment.Left
humoursHeader.Text = "The Four Humours"
humoursHeader.LayoutOrder = 6
humoursHeader.Parent = contentFrame

-- Humour value labels, keyed by humour name. Populated below; future
-- body-region clicking updates these (directly or via the SetHumour event).
local humourValueLabels = {}

local HUMOUR_NAMES = Humours.Names
local HUMOUR_EMPTY = "—"

for index, humourName in HUMOUR_NAMES do
	local row = Instance.new("Frame")
	row.Name = "Humour_" .. humourName:gsub(" ", "")
	row.Size = UDim2.new(1, 0, 0, 26)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.LayoutOrder = 6 + index
	row.Parent = contentFrame

	local rowName = Instance.new("TextLabel")
	rowName.Name = "Name"
	rowName.Size = UDim2.new(0.6, 0, 1, 0)
	rowName.Position = UDim2.fromScale(0, 0)
	rowName.BackgroundTransparency = 1
	rowName.TextColor3 = Color3.fromRGB(220, 220, 200)
	rowName.Font = Enum.Font.Gotham
	rowName.TextSize = 16
	rowName.TextXAlignment = Enum.TextXAlignment.Left
	rowName.Text = humourName
	rowName.Parent = row

	local rowValue = Instance.new("TextLabel")
	rowValue.Name = "Value"
	rowValue.Size = UDim2.new(0.4, 0, 1, 0)
	rowValue.Position = UDim2.fromScale(0.6, 0)
	rowValue.BackgroundTransparency = 1
	rowValue.TextColor3 = Color3.fromRGB(230, 215, 170)
	rowValue.Font = Enum.Font.GothamBold
	rowValue.TextSize = 16
	rowValue.TextXAlignment = Enum.TextXAlignment.Right
	rowValue.Text = HUMOUR_EMPTY
	rowValue.Parent = row

	humourValueLabels[humourName] = rowValue
end

local function resetHumourValues()
	for _, valueLabel in humourValueLabels do
		valueLabel.Text = HUMOUR_EMPTY
	end
end

-- Other scripts (future body-region clicking) fire this to set a humour value:
-- SetHumour:Fire("Blood", "Sanguine") etc. An unknown humour name is ignored.
local setHumour = Instance.new("BindableEvent")
setHumour.Name = "SetHumour"
setHumour.Parent = script

setHumour.Event:Connect(function(humourName, value)
	local valueLabel = humourValueLabels[humourName]
	if valueLabel then
		valueLabel.Text = value == nil and HUMOUR_EMPTY or tostring(value)
	end
end)

local leaveButton = Instance.new("TextButton")
leaveButton.Name = "Leave"
leaveButton.Size = UDim2.fromOffset(120, 40)
leaveButton.Position = UDim2.new(0, 20, 1, -56)
leaveButton.BackgroundColor3 = Color3.fromRGB(50, 46, 36)
leaveButton.BorderSizePixel = 0
leaveButton.TextColor3 = Color3.fromRGB(220, 220, 220)
leaveButton.Font = Enum.Font.GothamBold
leaveButton.TextSize = 16
leaveButton.Text = "Leave"
leaveButton.Parent = panel

local cameraControllerScript = clientFolder:WaitForChild("hud"):WaitForChild("CameraController", 10)
-- WaitForChild is required here because CameraController creates SetGuiOpen
-- inside its own script body, which may run after this script starts.
local setGuiOpen = cameraControllerScript and cameraControllerScript:WaitForChild("SetGuiOpen", 10)
if not setGuiOpen then
	warn("[TreatmentPanelUI] SetGuiOpen BindableEvent missing; mouse cursor will stay locked while panel is open.")
end

local function notifyGuiOpen(open)
	if setGuiOpen then
		setGuiOpen:Fire(open)
	end
end

local setExamining = cameraControllerScript and cameraControllerScript:WaitForChild("SetExamining", 10)
if not setExamining then
	warn("[TreatmentPanelUI] SetExamining BindableEvent missing; examination camera will not engage.")
end

local function notifyExamining(active, npc)
	if setExamining then
		setExamining:Fire(active, npc)
	end
end

local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.fromOffset(420, 40)
toastLabel.Position = UDim2.new(0.5, -210, 0.85, 0)
toastLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
toastLabel.BackgroundTransparency = 0.3
toastLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
toastLabel.Font = Enum.Font.Gotham
toastLabel.TextSize = 16
toastLabel.Text = ""
toastLabel.Visible = false
toastLabel.Parent = screenGui

local function toast(text)
	toastLabel.Text = text
	toastLabel.Visible = true
	task.delay(3, function()
		if toastLabel.Text == text then
			toastLabel.Visible = false
		end
	end)
end

local inRangeNPC = nil
local currentTargetNPC = nil

local function openPanel(payload)
	currentTargetNPC = payload.npcRef

	resetHumourValues()

	panel.Visible = true
	promptFrame.Visible = false
	notifyGuiOpen(true)
	ExaminationState.SetCurrentNPC(payload.npcRef, payload.humours)
	print("[B playtest open]", ExaminationState.GetCurrentNPC(), game:GetService("HttpService"):JSONEncode(ExaminationState.GetAllHumours()))
	notifyExamining(true, currentTargetNPC)
end

local function closePanel(notifyServer)
	local npcToClose = currentTargetNPC

	panel.Visible = false
	currentTargetNPC = nil
	ExaminationState.ClearCurrentNPC()
	print("[B playtest close]", ExaminationState.GetCurrentNPC(), ExaminationState.GetAllHumours())

	notifyGuiOpen(false)
	notifyExamining(false)

	if notifyServer and npcToClose then
		RemoteEvents.CloseExamination:FireServer(npcToClose)
	end
end

NPCInRange.Event:Connect(function(npc)
	inRangeNPC = npc
	if not panel.Visible then
		promptFrame.Visible = true
	end
end)

NPCOutOfRange.Event:Connect(function(npc, reason)
	if inRangeNPC == npc then
		inRangeNPC = nil
		promptFrame.Visible = false
	end
	if panel.Visible and currentTargetNPC == npc then
		closePanel(true)
		if reason == "comfort_timer" then
			toast("The patient has gone.")
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E and inRangeNPC and not panel.Visible then
		RemoteEvents.RequestExamination:FireServer(inRangeNPC)
	end
end)

leaveButton.MouseButton1Click:Connect(function()
	closePanel(true)
end)

RemoteEvents.ExaminationApproved.OnClientEvent:Connect(function(payload)
	openPanel(payload)
end)
