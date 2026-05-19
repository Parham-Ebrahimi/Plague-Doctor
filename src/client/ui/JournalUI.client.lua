local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteEvents = require(Shared.core.RemoteEvents)
local SymptomData = require(Shared.data.SymptomData)
local ItemData = require(Shared.data.ItemData)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local clientFolder = localPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")

-- Other UI scripts toggle the journal by firing this BindableEvent.
local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "JournalToggle"
toggleEvent.Parent = script

local cameraControllerScript = clientFolder:WaitForChild("hud"):WaitForChild("CameraController", 10)
-- WaitForChild is required here because CameraController creates SetGuiOpen
-- inside its own script body, which may run after this script starts.
local setGuiOpen = cameraControllerScript and cameraControllerScript:WaitForChild("SetGuiOpen", 10)
if not setGuiOpen then
	warn("[JournalUI] SetGuiOpen BindableEvent missing; mouse cursor will stay locked while journal is open.")
end

local function notifyGuiOpen(open)
	if setGuiOpen then
		setGuiOpen:Fire(open)
	end
end

local SECTIONS = {
	{ id = "Remedies", label = "Remedies" },
	{ id = "Ingredients", label = "Ingredients" },
	{ id = "Findings", label = "Findings" },
}

local COLORS = {
	background = Color3.fromRGB(28, 26, 22),
	stroke = Color3.fromRGB(80, 70, 50),
	tabIdle = Color3.fromRGB(50, 46, 36),
	tabActive = Color3.fromRGB(120, 100, 60),
	textBright = Color3.fromRGB(230, 215, 170),
	textNormal = Color3.fromRGB(220, 220, 220),
	textDim = Color3.fromRGB(180, 180, 180),
	entryBackground = Color3.fromRGB(40, 36, 30),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JournalInterface"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 5
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "JournalPanel"
panel.Size = UDim2.new(0.45, 0, 1, 0)
panel.Position = UDim2.new(0, 0, 0, 0)
panel.BackgroundColor3 = COLORS.background
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.stroke
stroke.Thickness = 2
stroke.Parent = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -80, 0, 40)
titleLabel.Position = UDim2.fromOffset(20, 20)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = COLORS.textBright
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "Journal"
titleLabel.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.fromOffset(40, 40)
closeButton.Position = UDim2.new(1, -60, 0, 20)
closeButton.BackgroundColor3 = COLORS.tabIdle
closeButton.BorderSizePixel = 0
closeButton.TextColor3 = COLORS.textNormal
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.Text = "X"
closeButton.Parent = panel

local tabsFrame = Instance.new("Frame")
tabsFrame.Name = "Tabs"
tabsFrame.Size = UDim2.new(1, -40, 0, 36)
tabsFrame.Position = UDim2.fromOffset(20, 70)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = panel

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 6)
tabsLayout.Parent = tabsFrame

local entryArea = Instance.new("ScrollingFrame")
entryArea.Name = "Entries"
entryArea.Size = UDim2.new(1, -40, 1, -140)
entryArea.Position = UDim2.fromOffset(20, 120)
entryArea.BackgroundColor3 = Color3.fromRGB(20, 18, 14)
entryArea.BackgroundTransparency = 0.2
entryArea.BorderSizePixel = 0
entryArea.CanvasSize = UDim2.new(0, 0, 0, 0)
entryArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
entryArea.ScrollBarThickness = 6
entryArea.Parent = panel

local entryLayout = Instance.new("UIListLayout")
entryLayout.FillDirection = Enum.FillDirection.Vertical
entryLayout.Padding = UDim.new(0, 6)
entryLayout.SortOrder = Enum.SortOrder.LayoutOrder
entryLayout.Parent = entryArea

local entryPadding = Instance.new("UIPadding")
entryPadding.PaddingTop = UDim.new(0, 6)
entryPadding.PaddingBottom = UDim.new(0, 6)
entryPadding.PaddingLeft = UDim.new(0, 8)
entryPadding.PaddingRight = UDim.new(0, 8)
entryPadding.Parent = entryArea

local activeSection = "Remedies"
local tabButtons = {}

local function clearEntries()
	for _, child in entryArea:GetChildren() do
		if not (child:IsA("UILayout") or child:IsA("UIPadding")) then
			child:Destroy()
		end
	end
end

local function setActiveTab(sectionId)
	activeSection = sectionId
	for id, button in tabButtons do
		if id == sectionId then
			button.BackgroundColor3 = COLORS.tabActive
			button.TextColor3 = COLORS.textBright
		else
			button.BackgroundColor3 = COLORS.tabIdle
			button.TextColor3 = COLORS.textNormal
		end
	end
end

local function symptomLabels(symptoms)
	if type(symptoms) ~= "table" then
		return "()"
	end

	local pieces = {}
	for _, key in symptoms do
		local def = SymptomData[key]
		table.insert(pieces, def and def.label or tostring(key))
	end

	if #pieces == 0 then
		return "()"
	end

	return table.concat(pieces, ", ")
end

local function itemLabel(itemName)
	if not itemName then
		return nil
	end
	local def = ItemData[itemName]
	return def and def.displayName or tostring(itemName)
end

local function itemListLabels(items)
	if type(items) ~= "table" then
		return nil
	end

	local labels = {}
	for _, itemName in items do
		table.insert(labels, itemLabel(itemName) or tostring(itemName))
	end

	return table.concat(labels, " + ")
end

local function buildEntryText(section, entry)
	local dayText = entry.day and ("Day " .. tostring(entry.day)) or "Day ?"
	local lines = { dayText }

	if section == "Remedies" then
		local itemName = entry.item or entry.itemUsed or entry.resultItem
		local item = itemLabel(itemName)
		if item then
			table.insert(lines, item)
		end
		if entry.ingredients then
			table.insert(lines, "Recipe: " .. itemListLabels(entry.ingredients))
			if entry.symptomCategories and #entry.symptomCategories > 0 then
				table.insert(lines, "Treats: " .. table.concat(entry.symptomCategories, ", "))
			elseif entry.category then
				table.insert(lines, "Treats: " .. tostring(entry.category))
			end
		elseif entry.improved and #entry.improved > 0 then
			table.insert(lines, "Improved: " .. table.concat(entry.improved, ", "))
			table.insert(lines, "Works on: " .. symptomLabels(entry.symptoms or entry.symptomSet))
		elseif entry.symptoms or entry.symptomSet then
			table.insert(lines, "Works on: " .. symptomLabels(entry.symptoms or entry.symptomSet))
		end
	elseif section == "Ingredients" then
		local item = itemLabel(entry.item or entry.itemUsed)
		if item then
			table.insert(lines, item)
		elseif entry.combination then
			table.insert(lines, "Mixture: " .. itemListLabels(entry.combination))
		end
		if entry.content or entry.note then
			table.insert(lines, entry.content or entry.note)
		end
		if entry.hint and entry.hint ~= "" then
			table.insert(lines, "Hint: " .. entry.hint)
		end
		if entry.status then
			table.insert(lines, "Result: " .. tostring(entry.status))
		end
	elseif section == "Findings" then
		if entry.source then
			table.insert(lines, tostring(entry.source))
		end
		if entry.content or entry.note then
			table.insert(lines, entry.content or entry.note)
		end
		if entry.district then
			table.insert(lines, "District: " .. tostring(entry.district))
		end
		if entry.status then
			table.insert(lines, "Status: " .. tostring(entry.status))
		end
	else
		if entry.content or entry.note then
			table.insert(lines, entry.content or entry.note)
		end
	end

	return table.concat(lines, "\n")
end

local function renderEntries(section, entries)
	clearEntries()

	if not entries or #entries == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -16, 0, 60)
		empty.BackgroundTransparency = 1
		empty.TextColor3 = COLORS.textDim
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 14
		empty.TextWrapped = true
		empty.TextXAlignment = Enum.TextXAlignment.Left
		empty.TextYAlignment = Enum.TextYAlignment.Top
		empty.Text = "No entries yet."
		empty.Parent = entryArea
		return
	end

	for index, entry in entries do
		local container = Instance.new("Frame")
		container.Name = "Entry_" .. tostring(index)
		container.Size = UDim2.new(1, -16, 0, 0)
		container.AutomaticSize = Enum.AutomaticSize.Y
		container.BackgroundColor3 = COLORS.entryBackground
		container.BorderSizePixel = 0
		container.LayoutOrder = index
		container.Parent = entryArea

		local containerPadding = Instance.new("UIPadding")
		containerPadding.PaddingTop = UDim.new(0, 6)
		containerPadding.PaddingBottom = UDim.new(0, 6)
		containerPadding.PaddingLeft = UDim.new(0, 8)
		containerPadding.PaddingRight = UDim.new(0, 8)
		containerPadding.Parent = container

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 0, 0)
		text.AutomaticSize = Enum.AutomaticSize.Y
		text.BackgroundTransparency = 1
		text.TextColor3 = COLORS.textNormal
		text.Font = Enum.Font.Gotham
		text.TextSize = 14
		text.TextWrapped = true
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.TextYAlignment = Enum.TextYAlignment.Top
		text.Text = buildEntryText(section, entry)
		text.Parent = container
	end
end

local function requestSection(sectionId)
	clearEntries()

	local loadingLabel = Instance.new("TextLabel")
	loadingLabel.Size = UDim2.new(1, -16, 0, 40)
	loadingLabel.BackgroundTransparency = 1
	loadingLabel.TextColor3 = COLORS.textDim
	loadingLabel.Font = Enum.Font.Gotham
	loadingLabel.TextSize = 14
	loadingLabel.TextXAlignment = Enum.TextXAlignment.Left
	loadingLabel.Text = "Loading..."
	loadingLabel.Parent = entryArea

	RemoteEvents.RequestJournalSection:FireServer(sectionId)
end

local function makeTabButton(section)
	local button = Instance.new("TextButton")
	button.Name = "Tab_" .. section.id
	button.Size = UDim2.new(1 / #SECTIONS, -6, 1, 0)
	button.BackgroundColor3 = COLORS.tabIdle
	button.BorderSizePixel = 0
	button.TextColor3 = COLORS.textNormal
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.Text = section.label
	button.Parent = tabsFrame

	button.MouseButton1Click:Connect(function()
		setActiveTab(section.id)
		requestSection(section.id)
	end)

	tabButtons[section.id] = button
end

for _, section in SECTIONS do
	makeTabButton(section)
end

setActiveTab(activeSection)

local function openJournal()
	panel.Visible = true
	notifyGuiOpen(true)
	requestSection(activeSection)
end

local function closeJournal()
	panel.Visible = false
	notifyGuiOpen(false)
end

local function toggleJournal()
	if panel.Visible then
		closeJournal()
	else
		openJournal()
	end
end

closeButton.MouseButton1Click:Connect(closeJournal)

toggleEvent.Event:Connect(toggleJournal)

RemoteEvents.JournalSectionResponse.OnClientEvent:Connect(function(section, entries)
	if section ~= activeSection then
		return
	end

	if not panel.Visible then
		return
	end

	renderEntries(section, entries)
end)
