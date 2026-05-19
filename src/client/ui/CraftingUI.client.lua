local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemData = require(Shared.data.ItemData)
local RemoteEvents = require(Shared.core.RemoteEvents)
local TreatmentRules = require(Shared.rules.TreatmentRules)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local clientFolder = localPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")

local cameraControllerScript = clientFolder:WaitForChild("hud"):WaitForChild("CameraController", 10)
local setGuiOpen = cameraControllerScript and cameraControllerScript:WaitForChild("SetGuiOpen", 10)
if not setGuiOpen then
	warn("[CraftingUI] SetGuiOpen BindableEvent missing; mouse cursor will stay locked while crafting is open.")
end

local function notifyGuiOpen(open)
	if setGuiOpen then
		setGuiOpen:Fire(open)
	end
end

local COLORS = {
	background = Color3.fromRGB(26, 24, 21),
	panel = Color3.fromRGB(35, 32, 27),
	panelDark = Color3.fromRGB(21, 19, 16),
	stroke = Color3.fromRGB(91, 78, 54),
	textBright = Color3.fromRGB(236, 219, 173),
	textNormal = Color3.fromRGB(221, 216, 204),
	textDim = Color3.fromRGB(153, 146, 132),
	button = Color3.fromRGB(72, 62, 42),
	buttonDisabled = Color3.fromRGB(34, 32, 29),
	amber = Color3.fromRGB(214, 157, 67),
	red = Color3.fromRGB(156, 73, 66),
	grey = Color3.fromRGB(136, 132, 122),
	green = Color3.fromRGB(95, 145, 91),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CraftingInterface"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 6
screenGui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.Visible = false
overlay.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "WorkbenchPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Size = UDim2.new(0.82, 0, 0.78, 0)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = COLORS.background
panel.BorderSizePixel = 0
panel.Parent = overlay

local panelSize = Instance.new("UISizeConstraint")
panelSize.MinSize = Vector2.new(780, 460)
panelSize.MaxSize = Vector2.new(1180, 720)
panelSize.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = COLORS.stroke
panelStroke.Thickness = 2
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -90, 0, 46)
title.Position = UDim2.fromOffset(24, 16)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Workbench"
title.TextColor3 = COLORS.textBright
title.TextSize = 26
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.fromOffset(42, 42)
closeButton.Position = UDim2.new(1, -62, 0, 18)
closeButton.BackgroundColor3 = COLORS.button
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.textNormal
closeButton.TextSize = 18
closeButton.Parent = panel

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -48, 1, -92)
content.Position = UDim2.fromOffset(24, 74)
content.BackgroundTransparency = 1
content.Parent = panel

local columns = Instance.new("UIListLayout")
columns.FillDirection = Enum.FillDirection.Horizontal
columns.Padding = UDim.new(0, 16)
columns.SortOrder = Enum.SortOrder.LayoutOrder
columns.Parent = content

local function makeColumn(name, widthScale)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(widthScale, -11, 1, 0)
	frame.BackgroundColor3 = COLORS.panel
	frame.BorderSizePixel = 0
	frame.Parent = content

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.stroke
	stroke.Thickness = 1
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = frame

	return frame
end

local leftColumn = makeColumn("Satchel", 0.31)
local centerColumn = makeColumn("Mixture", 0.34)
local rightColumn = makeColumn("RecipeBook", 0.35)

local function makeHeader(parent, text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 24)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = COLORS.textBright
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

makeHeader(leftColumn, "Satchel Ingredients")
makeHeader(centerColumn, "Mixture")
makeHeader(rightColumn, "Known Remedies")

local ingredientList = Instance.new("ScrollingFrame")
ingredientList.Name = "IngredientList"
ingredientList.Size = UDim2.new(1, 0, 1, -34)
ingredientList.Position = UDim2.fromOffset(0, 34)
ingredientList.BackgroundColor3 = COLORS.panelDark
ingredientList.BackgroundTransparency = 0.1
ingredientList.BorderSizePixel = 0
ingredientList.CanvasSize = UDim2.fromScale(0, 0)
ingredientList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ingredientList.ScrollBarThickness = 6
ingredientList.Parent = leftColumn

local ingredientLayout = Instance.new("UIListLayout")
ingredientLayout.Padding = UDim.new(0, 6)
ingredientLayout.SortOrder = Enum.SortOrder.LayoutOrder
ingredientLayout.Parent = ingredientList

local ingredientPadding = Instance.new("UIPadding")
ingredientPadding.PaddingTop = UDim.new(0, 8)
ingredientPadding.PaddingBottom = UDim.new(0, 8)
ingredientPadding.PaddingLeft = UDim.new(0, 8)
ingredientPadding.PaddingRight = UDim.new(0, 8)
ingredientPadding.Parent = ingredientList

local slotFrame = Instance.new("Frame")
slotFrame.Name = "Slots"
slotFrame.Size = UDim2.new(1, 0, 0, 104)
slotFrame.Position = UDim2.fromOffset(0, 48)
slotFrame.BackgroundTransparency = 1
slotFrame.Parent = centerColumn

local slotLayout = Instance.new("UIListLayout")
slotLayout.FillDirection = Enum.FillDirection.Horizontal
slotLayout.Padding = UDim.new(0, 12)
slotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
slotLayout.Parent = slotFrame

local slotButtons = {}
for index = 1, 2 do
	local slot = Instance.new("TextButton")
	slot.Name = "Slot" .. index
	slot.Size = UDim2.new(0.5, -6, 1, 0)
	slot.BackgroundColor3 = COLORS.panelDark
	slot.BorderSizePixel = 0
	slot.Font = Enum.Font.GothamBold
	slot.Text = "Empty"
	slot.TextColor3 = COLORS.textDim
	slot.TextSize = 16
	slot.TextWrapped = true
	slot.Parent = slotFrame
	slotButtons[index] = slot
end

local mixtureIndicator = Instance.new("TextLabel")
mixtureIndicator.Name = "MixtureIndicator"
mixtureIndicator.Size = UDim2.new(1, 0, 0, 56)
mixtureIndicator.Position = UDim2.fromOffset(0, 172)
mixtureIndicator.BackgroundColor3 = COLORS.panelDark
mixtureIndicator.BackgroundTransparency = 0.1
mixtureIndicator.BorderSizePixel = 0
mixtureIndicator.Font = Enum.Font.Gotham
mixtureIndicator.Text = "Select two ingredients."
mixtureIndicator.TextColor3 = COLORS.textDim
mixtureIndicator.TextSize = 16
mixtureIndicator.TextWrapped = true
mixtureIndicator.Parent = centerColumn

local actionsFrame = Instance.new("Frame")
actionsFrame.Name = "Actions"
actionsFrame.Size = UDim2.new(1, 0, 0, 46)
actionsFrame.Position = UDim2.fromOffset(0, 246)
actionsFrame.BackgroundTransparency = 1
actionsFrame.Parent = centerColumn

local actionsLayout = Instance.new("UIListLayout")
actionsLayout.FillDirection = Enum.FillDirection.Horizontal
actionsLayout.Padding = UDim.new(0, 10)
actionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionsLayout.Parent = actionsFrame

local function makeActionButton(name, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0.5, -5, 1, 0)
	button.BackgroundColor3 = COLORS.buttonDisabled
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = COLORS.textDim
	button.TextSize = 16
	button.Parent = actionsFrame
	return button
end

local testButton = makeActionButton("Test", "Test")
local craftButton = makeActionButton("Craft", "Craft")

local recipeList = Instance.new("ScrollingFrame")
recipeList.Name = "Recipes"
recipeList.Size = UDim2.new(1, 0, 1, -34)
recipeList.Position = UDim2.fromOffset(0, 34)
recipeList.BackgroundColor3 = COLORS.panelDark
recipeList.BackgroundTransparency = 0.1
recipeList.BorderSizePixel = 0
recipeList.CanvasSize = UDim2.fromScale(0, 0)
recipeList.AutomaticCanvasSize = Enum.AutomaticSize.Y
recipeList.ScrollBarThickness = 6
recipeList.Parent = rightColumn

local recipeLayout = Instance.new("UIListLayout")
recipeLayout.Padding = UDim.new(0, 6)
recipeLayout.SortOrder = Enum.SortOrder.LayoutOrder
recipeLayout.Parent = recipeList

local recipePadding = Instance.new("UIPadding")
recipePadding.PaddingTop = UDim.new(0, 8)
recipePadding.PaddingBottom = UDim.new(0, 8)
recipePadding.PaddingLeft = UDim.new(0, 8)
recipePadding.PaddingRight = UDim.new(0, 8)
recipePadding.Parent = recipeList

local currentSatchel = {}
local currentWorkbench = nil
local selectedSlots = { nil, nil }
local lastPlacedSlot = 1
local panelOpen = false

local function itemLabel(itemName)
	local item = ItemData[itemName]
	return item and item.displayName or tostring(itemName)
end

local function clearList(frame)
	for _, child in frame:GetChildren() do
		if not (child:IsA("UILayout") or child:IsA("UIPadding")) then
			child:Destroy()
		end
	end
end

local function getSatchelQuantity(itemName)
	local quantity = 0
	for _, slot in currentSatchel do
		if slot.itemName == itemName then
			quantity += slot.quantity
		end
	end
	return quantity
end

local function hasIngredients(ingredients)
	local required = {}
	for _, itemName in ingredients do
		required[itemName] = (required[itemName] or 0) + 1
	end
	for itemName, quantity in required do
		if getSatchelQuantity(itemName) < quantity then
			return false
		end
	end
	return true
end

local function updateButtons()
	local active = selectedSlots[1] ~= nil and selectedSlots[2] ~= nil
	for _, button in { testButton, craftButton } do
		button.AutoButtonColor = active
		button.BackgroundColor3 = active and COLORS.button or COLORS.buttonDisabled
		button.TextColor3 = active and COLORS.textNormal or COLORS.textDim
	end
end

local function updateSlotText()
	for index, button in slotButtons do
		local itemName = selectedSlots[index]
		if itemName then
			button.Text = itemLabel(itemName)
			button.TextColor3 = COLORS.textBright
		else
			button.Text = "Empty"
			button.TextColor3 = COLORS.textDim
		end
	end
	updateButtons()
end

local function clearSlots()
	selectedSlots[1] = nil
	selectedSlots[2] = nil
	lastPlacedSlot = 1
	mixtureIndicator.Text = "Select two ingredients."
	mixtureIndicator.TextColor3 = COLORS.textDim
	updateSlotText()
end

local function selectIngredient(itemName)
	local targetSlot
	if not selectedSlots[1] then
		targetSlot = 1
	elseif not selectedSlots[2] then
		targetSlot = 2
	else
		targetSlot = lastPlacedSlot
	end

	selectedSlots[targetSlot] = itemName
	lastPlacedSlot = targetSlot
	mixtureIndicator.Text = "Mixture ready."
	mixtureIndicator.TextColor3 = COLORS.textNormal
	updateSlotText()
end

local function makeEmptyLabel(parent, text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 0, 44)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = COLORS.textDim
	label.TextSize = 14
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function renderSatchel(satchel)
	currentSatchel = satchel or {}
	clearList(ingredientList)

	local count = 0
	for index, slot in currentSatchel do
		local item = slot.itemName and ItemData[slot.itemName]
		if item and item.isIngredient and slot.quantity > 0 then
			count += 1

			local button = Instance.new("TextButton")
			button.Name = "Ingredient_" .. slot.itemName
			button.Size = UDim2.new(1, -16, 0, 52)
			button.BackgroundColor3 = COLORS.button
			button.BorderSizePixel = 0
			button.Font = Enum.Font.GothamBold
			button.Text = item.displayName .. "  x" .. tostring(slot.quantity)
			button.TextColor3 = COLORS.textNormal
			button.TextSize = 14
			button.TextWrapped = true
			button.LayoutOrder = index
			button.Parent = ingredientList

			local capturedItem = slot.itemName
			button.MouseButton1Click:Connect(function()
				selectIngredient(capturedItem)
			end)
		end
	end

	if count == 0 then
		makeEmptyLabel(ingredientList, "No ingredients in satchel.")
	end
end

local function renderRecipes(entries)
	clearList(recipeList)

	local rendered = 0
	for index, entry in entries or {} do
		local ingredients = entry.ingredients
		local resultItem = entry.item or entry.resultItem
		if type(ingredients) == "table" and #ingredients == 2 and resultItem then
			rendered += 1
			local available = hasIngredients(ingredients)
			local result = ItemData[resultItem]
			local category = entry.category
			if not category and result and result.symptomCategories then
				category = table.concat(result.symptomCategories, ", ")
			end

			local row = Instance.new("TextButton")
			row.Name = "Recipe_" .. tostring(resultItem)
			row.Size = UDim2.new(1, -16, 0, 74)
			row.BackgroundColor3 = available and COLORS.button or COLORS.buttonDisabled
			row.BorderSizePixel = 0
			row.AutoButtonColor = available
			row.Font = Enum.Font.Gotham
			row.Text = itemLabel(resultItem)
				.. "\n"
				.. itemLabel(ingredients[1])
				.. " + "
				.. itemLabel(ingredients[2])
				.. "\n"
				.. tostring(category or "unknown")
			row.TextColor3 = available and COLORS.textNormal or COLORS.textDim
			row.TextSize = 13
			row.TextWrapped = true
			row.LayoutOrder = index
			row.Parent = recipeList

			row.MouseButton1Click:Connect(function()
				if not available then
					return
				end
				selectedSlots[1] = ingredients[1]
				selectedSlots[2] = ingredients[2]
				lastPlacedSlot = 2
				mixtureIndicator.Text = "Known recipe selected."
				mixtureIndicator.TextColor3 = COLORS.textNormal
				updateSlotText()
			end)
		end
	end

	if rendered == 0 then
		makeEmptyLabel(recipeList, "No confirmed remedies yet.")
	end
end

local function closePanel()
	if not panelOpen then
		return
	end

	panelOpen = false
	overlay.Visible = false
	currentWorkbench = nil
	clearSlots()
	notifyGuiOpen(false)
end

local function openPanel(payload)
	panelOpen = true
	overlay.Visible = true
	currentWorkbench = payload and payload.workbench or nil
	clearSlots()
	renderSatchel(payload and payload.satchel or {})
	renderRecipes({})
	notifyGuiOpen(true)
	RemoteEvents.RequestJournalSection:FireServer("Remedies")
end

local function getWorkbenchPosition()
	if not currentWorkbench or not currentWorkbench.Parent then
		return nil
	end

	if currentWorkbench:IsA("BasePart") then
		return currentWorkbench.Position
	end

	if currentWorkbench:IsA("Model") then
		return currentWorkbench:GetPivot().Position
	end

	return nil
end

for index, slot in slotButtons do
	slot.MouseButton1Click:Connect(function()
		selectedSlots[index] = nil
		mixtureIndicator.Text = "Select two ingredients."
		mixtureIndicator.TextColor3 = COLORS.textDim
		updateSlotText()
	end)
end

closeButton.MouseButton1Click:Connect(closePanel)

testButton.MouseButton1Click:Connect(function()
	if not selectedSlots[1] or not selectedSlots[2] then
		return
	end

	mixtureIndicator.Text = "Testing mixture..."
	mixtureIndicator.TextColor3 = COLORS.textDim
	RemoteEvents.TestMixture:FireServer({ selectedSlots[1], selectedSlots[2] })
end)

craftButton.MouseButton1Click:Connect(function()
	if not selectedSlots[1] or not selectedSlots[2] then
		return
	end

	mixtureIndicator.Text = "Crafting..."
	mixtureIndicator.TextColor3 = COLORS.textDim
	RemoteEvents.AttemptCraft:FireServer({ selectedSlots[1], selectedSlots[2] })
end)

RemoteEvents.OpenCraftingUI.OnClientEvent:Connect(openPanel)

RemoteEvents.TestMixtureResult.OnClientEvent:Connect(function(payload)
	if not panelOpen then
		return
	end

	local result = payload and payload.result
	if result == TreatmentRules.TestResults.Promising then
		mixtureIndicator.Text = "Promising."
		mixtureIndicator.TextColor3 = COLORS.amber
	elseif result == TreatmentRules.TestResults.Wrong then
		mixtureIndicator.Text = "Wrong reaction."
		mixtureIndicator.TextColor3 = COLORS.red
	else
		mixtureIndicator.Text = "Inert."
		mixtureIndicator.TextColor3 = COLORS.grey
	end
end)

RemoteEvents.AttemptCraftResult.OnClientEvent:Connect(function(payload)
	if not panelOpen then
		return
	end

	if payload and payload.satchel then
		renderSatchel(payload.satchel)
	end

	clearSlots()

	if payload and payload.outcome == TreatmentRules.Outcomes.Success then
		mixtureIndicator.Text = "Crafted " .. itemLabel(payload.resultItem) .. "."
		mixtureIndicator.TextColor3 = COLORS.green
	else
		mixtureIndicator.Text = "The mixture failed."
		mixtureIndicator.TextColor3 = COLORS.red
	end

	RemoteEvents.RequestJournalSection:FireServer("Remedies")
end)

RemoteEvents.JournalSectionResponse.OnClientEvent:Connect(function(section, entries)
	if not panelOpen or section ~= "Remedies" then
		return
	end

	renderRecipes(entries)
end)

task.spawn(function()
	while true do
		task.wait(1)
		if panelOpen then
			local character = localPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local benchPosition = getWorkbenchPosition()
			if not root or not benchPosition or (root.Position - benchPosition).Magnitude > 10 then
				closePanel()
			end
		end
	end
end)
