local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InfectionStages = require(Shared.core.InfectionStages)
local SymptomData = require(Shared.data.SymptomData)
local ItemData = require(Shared.data.ItemData)
local RemoteEvents = require(Shared.core.RemoteEvents)

local localPlayer = Players.LocalPlayer
local clientFolder = localPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local proximityScript = clientFolder:WaitForChild("world"):WaitForChild("ProximityDetector")
local NPCInRange = proximityScript:WaitForChild("NPCInRange")
local NPCOutOfRange = proximityScript:WaitForChild("NPCOutOfRange")

local STAGE_LABELS = {
	[InfectionStages.Symptomatic] = "Symptomatic",
	[InfectionStages.Critical] = "Critical",
}

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

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -40, 0, 40)
nameLabel.Position = UDim2.fromOffset(20, 20)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(230, 215, 170)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 22
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Text = ""
nameLabel.Parent = panel

local stageLabel = Instance.new("TextLabel")
stageLabel.Size = UDim2.new(1, -40, 0, 24)
stageLabel.Position = UDim2.fromOffset(20, 60)
stageLabel.BackgroundTransparency = 1
stageLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
stageLabel.Font = Enum.Font.Gotham
stageLabel.TextSize = 16
stageLabel.TextXAlignment = Enum.TextXAlignment.Left
stageLabel.Text = ""
stageLabel.Parent = panel

local symptomFrame = Instance.new("Frame")
symptomFrame.Size = UDim2.new(1, -40, 0, 90)
symptomFrame.Position = UDim2.fromOffset(20, 100)
symptomFrame.BackgroundTransparency = 1
symptomFrame.Parent = panel

local symptomLayout = Instance.new("UIListLayout")
symptomLayout.FillDirection = Enum.FillDirection.Horizontal
symptomLayout.Padding = UDim.new(0, 8)
symptomLayout.Parent = symptomFrame

local satchelFrame = Instance.new("Frame")
satchelFrame.Size = UDim2.new(1, -40, 0, 240)
satchelFrame.Position = UDim2.fromOffset(20, 210)
satchelFrame.BackgroundTransparency = 1
satchelFrame.Parent = panel

local satchelLayout = Instance.new("UIGridLayout")
satchelLayout.CellSize = UDim2.fromOffset(80, 80)
satchelLayout.CellPadding = UDim2.fromOffset(8, 8)
satchelLayout.Parent = satchelFrame

local actionsFrame = Instance.new("Frame")
actionsFrame.Size = UDim2.new(1, -40, 0, 50)
actionsFrame.Position = UDim2.new(0, 20, 1, -80)
actionsFrame.BackgroundTransparency = 1
actionsFrame.Parent = panel

local actionsLayout = Instance.new("UIListLayout")
actionsLayout.FillDirection = Enum.FillDirection.Horizontal
actionsLayout.Padding = UDim.new(0, 10)
actionsLayout.Parent = actionsFrame

local function makeButton(name, text)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = UDim2.fromOffset(120, 40)
	b.BackgroundColor3 = Color3.fromRGB(50, 46, 36)
	b.BorderSizePixel = 0
	b.TextColor3 = Color3.fromRGB(220, 220, 220)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.Text = text
	b.Parent = actionsFrame
	return b
end

local applyButton = makeButton("Apply", "Apply")
local quarantineButton = makeButton("Quarantine", "Quarantine")
local journalButton = makeButton("Journal", "Journal")
local leaveButton = makeButton("Leave", "Leave")

local journalScript = clientFolder:WaitForChild("ui"):WaitForChild("JournalUI")
local journalToggle = journalScript:WaitForChild("JournalToggle")

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

journalButton.MouseButton1Click:Connect(function()
	journalToggle:Fire()
end)

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
local selectedItem = nil
local currentIsQuarantined = false
local canUseQuarantine = false

local function clearLayoutChildren(frame)
	for _, child in frame:GetChildren() do
		if not child:IsA("UILayout") then
			child:Destroy()
		end
	end
end

local function renderSymptoms(symptoms)
	clearLayoutChildren(symptomFrame)
	for _, key in symptoms do
		local def = SymptomData[key]
		if def then
			local box = Instance.new("Frame")
			box.Size = UDim2.fromOffset(120, 80)
			box.BackgroundColor3 = Color3.fromRGB(40, 36, 30)
			box.BorderSizePixel = 0
			box.Parent = symptomFrame

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.TextColor3 = Color3.fromRGB(220, 220, 200)
			lbl.Font = Enum.Font.Gotham
			lbl.TextSize = 14
			lbl.TextWrapped = true
			lbl.Text = def.label
			lbl.Parent = box
		end
	end
end

local function selectItem(itemName, slotButton)
	selectedItem = itemName
	for _, child in satchelFrame:GetChildren() do
		if child:IsA("TextButton") then
			local existingStroke = child:FindFirstChildOfClass("UIStroke")
			if existingStroke then
				existingStroke:Destroy()
			end
		end
	end
	if slotButton then
		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(230, 215, 120)
		s.Thickness = 2
		s.Parent = slotButton
	end
end

local function satchelHasItem(satchel, itemName)
	for _, slot in satchel do
		if slot.itemName == itemName and slot.quantity > 0 then
			return true
		end
	end

	return false
end

local function renderSatchel(satchel)
	clearLayoutChildren(satchelFrame)
	for _, slot in satchel do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(80, 80)
		btn.BackgroundColor3 = Color3.fromRGB(40, 36, 30)
		btn.AutoButtonColor = true
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.Parent = satchelFrame

		if slot.itemName then
			local item = ItemData[slot.itemName]
			local nameLine = Instance.new("TextLabel")
			nameLine.Size = UDim2.new(1, -8, 0.7, 0)
			nameLine.Position = UDim2.fromOffset(4, 4)
			nameLine.BackgroundTransparency = 1
			nameLine.TextColor3 = Color3.fromRGB(230, 215, 170)
			nameLine.Font = Enum.Font.Gotham
			nameLine.TextSize = 12
			nameLine.TextWrapped = true
			nameLine.Text = item and item.displayName or slot.itemName
			nameLine.Parent = btn

			local qty = Instance.new("TextLabel")
			qty.Size = UDim2.new(1, -8, 0.3, 0)
			qty.Position = UDim2.new(0, 4, 0.7, 0)
			qty.BackgroundTransparency = 1
			qty.TextColor3 = Color3.fromRGB(180, 180, 180)
			qty.Font = Enum.Font.GothamBold
			qty.TextSize = 14
			qty.TextXAlignment = Enum.TextXAlignment.Right
			qty.Text = "x" .. slot.quantity
			qty.Parent = btn

			local capturedItem = slot.itemName
			btn.MouseButton1Click:Connect(function()
				selectItem(capturedItem, btn)
			end)
		end
	end
end

local function openPanel(payload)
	currentTargetNPC = payload.npcRef
	selectedItem = nil
	currentIsQuarantined = payload.quarantined == true
	local satchel = payload.satchel or {}
	local hasQuarantineMarker = satchelHasItem(satchel, "QuarantineMarker")
	canUseQuarantine = currentIsQuarantined or hasQuarantineMarker

	nameLabel.Text = payload.npcName or "Unknown"
	stageLabel.Text = STAGE_LABELS[payload.stage] or ("Stage " .. tostring(payload.stage))
	if payload.treatedByPlayer then
		stageLabel.Text = stageLabel.Text .. "  -  treated earlier"
	end
	

	renderSymptoms(payload.symptoms or {})
	renderSatchel(satchel)

	quarantineButton.Text = currentIsQuarantined and "Unquarantine" or "Quarantine"
	quarantineButton.AutoButtonColor = canUseQuarantine
	if canUseQuarantine then
		quarantineButton.BackgroundColor3 = Color3.fromRGB(50, 46, 36)
		quarantineButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	else
		quarantineButton.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
		quarantineButton.TextColor3 = Color3.fromRGB(90, 90, 90)
	end

	panel.Visible = true
	promptFrame.Visible = false
	notifyGuiOpen(true)
	notifyExamining(true, currentTargetNPC)
end

local function closePanel(notifyServer)
	local npcToClose = currentTargetNPC

	panel.Visible = false
	currentTargetNPC = nil
	selectedItem = nil
	currentIsQuarantined = false
	canUseQuarantine = false

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

applyButton.MouseButton1Click:Connect(function()
	if not selectedItem or not currentTargetNPC then
		return
	end
	RemoteEvents.AttemptTreatment:FireServer(currentTargetNPC, selectedItem)
end)

quarantineButton.MouseButton1Click:Connect(function()
	if not currentTargetNPC then
		return
	end
	if not canUseQuarantine then
		toast("No quarantine marker available.")
		return
	end

	if currentIsQuarantined then
		RemoteEvents.AttemptUnquarantine:FireServer(currentTargetNPC)
	else
		RemoteEvents.AttemptQuarantine:FireServer(currentTargetNPC)
	end
end)

leaveButton.MouseButton1Click:Connect(function()
	closePanel(true)
end)

RemoteEvents.ExaminationApproved.OnClientEvent:Connect(function(payload)
	openPanel(payload)
end)

RemoteEvents.TreatmentResult.OnClientEvent:Connect(function(outcome)
	if outcome == "success" or outcome == "failure" then
		-- Spec: the player does not learn immediately whether the wrong remedy worked.
		toast("Treatment administered.")
	elseif outcome == "broad_spectrum" then
		toast("Broad remedy applied. Slowing progression.")
	elseif outcome == "no_item" then
		toast("Item not in satchel.")
	elseif outcome == "no_target" then
		toast("Target lost.")
	elseif outcome == "invalid_item" then
		toast("That cannot be applied.")
	end
	closePanel(false)
end)

RemoteEvents.QuarantineResult.OnClientEvent:Connect(function(outcome)
	if outcome == "success" then
		toast("Quarantine placed.")
	elseif outcome == "unquarantine_success" then
		toast("Quarantine lifted.")
	elseif outcome == "no_marker" then
		toast("No quarantine marker available.")
	elseif outcome == "already_quarantined" then
		toast("Already under quarantine.")
	elseif outcome == "not_quarantined" then
		toast("This patient is not quarantined.")
	end
	closePanel(false)
end)
