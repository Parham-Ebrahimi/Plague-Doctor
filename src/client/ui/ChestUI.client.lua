local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemData = require(Shared.data.ItemData)
local RemoteEvents = require(Shared.core.RemoteEvents)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local clientFolder = localPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")

local cameraControllerScript = clientFolder:WaitForChild("hud"):WaitForChild("CameraController", 10)
local setGuiOpen = cameraControllerScript and cameraControllerScript:WaitForChild("SetGuiOpen", 10)
if not setGuiOpen then
	warn("[ChestUI] SetGuiOpen BindableEvent missing; mouse cursor will stay locked while chest is open.")
end

local function notifyGuiOpen(open)
	if setGuiOpen then
		setGuiOpen:Fire(open)
	end
end

local COLORS = {
	background = Color3.fromRGB(25, 24, 22),
	panel = Color3.fromRGB(34, 32, 28),
	panelDark = Color3.fromRGB(20, 19, 17),
	stroke = Color3.fromRGB(88, 76, 54),
	textBright = Color3.fromRGB(235, 219, 176),
	textNormal = Color3.fromRGB(220, 216, 204),
	textDim = Color3.fromRGB(154, 148, 136),
	button = Color3.fromRGB(70, 60, 42),
	buttonHover = Color3.fromRGB(95, 78, 48),
	red = Color3.fromRGB(150, 74, 66),
	green = Color3.fromRGB(96, 143, 88),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChestInterface"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 7
screenGui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.38
overlay.Visible = false
overlay.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "ChestPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Size = UDim2.new(0.72, 0, 0.72, 0)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = COLORS.background
panel.BorderSizePixel = 0
panel.Parent = overlay

local panelSize = Instance.new("UISizeConstraint")
panelSize.MinSize = Vector2.new(680, 420)
panelSize.MaxSize = Vector2.new(1040, 680)
panelSize.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = COLORS.stroke
panelStroke.Thickness = 2
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -90, 0, 44)
title.Position = UDim2.fromOffset(24, 16)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Chest"
title.TextColor3 = COLORS.textBright
title.TextSize = 25
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, -90, 0, 24)
statusLabel.Position = UDim2.fromOffset(24, 54)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = ""
statusLabel.TextColor3 = COLORS.textDim
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = panel

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
content.Size = UDim2.new(1, -48, 1, -102)
content.Position = UDim2.fromOffset(24, 86)
content.BackgroundTransparency = 1
content.Parent = panel

local columns = Instance.new("UIListLayout")
columns.FillDirection = Enum.FillDirection.Horizontal
columns.Padding = UDim.new(0, 18)
columns.SortOrder = Enum.SortOrder.LayoutOrder
columns.Parent = content

local function makeColumn(name, labelText)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(0.5, -9, 1, 0)
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

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 26)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.Text = labelText
	header.TextColor3 = COLORS.textBright
	header.TextSize = 17
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = frame

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Size = UDim2.new(1, 0, 1, -36)
	list.Position = UDim2.fromOffset(0, 36)
	list.BackgroundColor3 = COLORS.panelDark
	list.BackgroundTransparency = 0.08
	list.BorderSizePixel = 0
	list.CanvasSize = UDim2.fromScale(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 6
	list.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 7)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 8)
	listPadding.PaddingBottom = UDim.new(0, 8)
	listPadding.PaddingLeft = UDim.new(0, 8)
	listPadding.PaddingRight = UDim.new(0, 8)
	listPadding.Parent = list

	return frame, list
end

local chestColumn, chestList = makeColumn("ChestColumn", "Chest Contents")
local satchelColumn, satchelList = makeColumn("SatchelColumn", "Satchel")

local dragGhost = Instance.new("TextLabel")
dragGhost.Name = "DragGhost"
dragGhost.Size = UDim2.fromOffset(170, 42)
dragGhost.BackgroundColor3 = COLORS.buttonHover
dragGhost.BackgroundTransparency = 0.1
dragGhost.BorderSizePixel = 0
dragGhost.Font = Enum.Font.GothamBold
dragGhost.TextColor3 = COLORS.textBright
dragGhost.TextSize = 14
dragGhost.TextWrapped = true
dragGhost.Visible = false
dragGhost.ZIndex = 20
dragGhost.Parent = overlay

local currentChest = nil
local currentChestItems = {}
local currentSatchel = {}
local panelOpen = false
local dragState = nil

local function itemLabel(itemName)
	local item = ItemData[itemName]
	return item and item.displayName or tostring(itemName)
end

local function clearList(list)
	for _, child in list:GetChildren() do
		if not (child:IsA("UILayout") or child:IsA("UIPadding")) then
			child:Destroy()
		end
	end
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
end

local function getItemQuantityInSatchel(itemName)
	local quantity = 0
	for _, slot in currentSatchel do
		if slot.itemName == itemName then
			quantity += slot.quantity
		end
	end
	return quantity
end

local function requestMove(source, itemName)
	if not currentChest then
		return
	end

	local direction = source == "chest" and "chest_to_satchel" or "satchel_to_chest"
	statusLabel.Text = "Moving " .. itemLabel(itemName) .. "..."
	statusLabel.TextColor3 = COLORS.textDim
	RemoteEvents.MoveChestItem:FireServer(currentChest, direction, itemName)
end

local function isPointInside(guiObject, position)
	local absolutePosition = guiObject.AbsolutePosition
	local absoluteSize = guiObject.AbsoluteSize
	return position.X >= absolutePosition.X
		and position.X <= absolutePosition.X + absoluteSize.X
		and position.Y >= absolutePosition.Y
		and position.Y <= absolutePosition.Y + absoluteSize.Y
end

local function beginDrag(source, itemName)
	local mousePosition = UserInputService:GetMouseLocation()
	dragState = {
		source = source,
		itemName = itemName,
	}
	dragGhost.Text = itemLabel(itemName)
	dragGhost.Position = UDim2.fromOffset(mousePosition.X + 12, mousePosition.Y + 12)
	dragGhost.Visible = true
end

local function endDrag(inputPosition)
	if not dragState then
		return
	end

	local source = dragState.source
	local itemName = dragState.itemName
	dragState = nil
	dragGhost.Visible = false

	if source == "chest" and isPointInside(satchelColumn, inputPosition) then
		requestMove("chest", itemName)
	elseif source == "satchel" and isPointInside(chestColumn, inputPosition) then
		requestMove("satchel", itemName)
	end
end

local function makeItemButton(parent, source, itemName, quantity, order)
	local button = Instance.new("TextButton")
	button.Name = source .. "_" .. itemName
	button.Size = UDim2.new(1, -16, 0, 52)
	button.BackgroundColor3 = COLORS.button
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = itemLabel(itemName) .. "  x" .. tostring(quantity)
	button.TextColor3 = COLORS.textNormal
	button.TextSize = 14
	button.TextWrapped = true
	button.LayoutOrder = order
	button.Parent = parent

	button.MouseButton1Click:Connect(function()
		requestMove(source, itemName)
	end)

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			beginDrag(source, itemName)
		end
	end)

	return button
end

local function renderChest()
	clearList(chestList)

	local count = 0
	for index, entry in currentChestItems do
		if entry.quantity and entry.quantity > 0 then
			count += 1
			makeItemButton(chestList, "chest", entry.itemName, entry.quantity, index)
		end
	end

	if count == 0 then
		makeEmptyLabel(chestList, "Chest is empty.")
	end
end

local function renderSatchel()
	clearList(satchelList)

	local count = 0
	for itemName, item in ItemData do
		if item.isIngredient then
			local quantity = getItemQuantityInSatchel(itemName)
			if quantity > 0 then
				count += 1
				makeItemButton(satchelList, "satchel", itemName, quantity, count)
			end
		end
	end

	if count == 0 then
		makeEmptyLabel(satchelList, "Satchel has no ingredients.")
	end
end

local function renderAll()
	renderChest()
	renderSatchel()
end

local function closePanel()
	if not panelOpen then
		return
	end

	panelOpen = false
	overlay.Visible = false
	currentChest = nil
	dragState = nil
	dragGhost.Visible = false
	notifyGuiOpen(false)
end

local function openPanel(payload)
	panelOpen = true
	overlay.Visible = true
	currentChest = payload and payload.chest or nil
	currentChestItems = payload and payload.chestItems or {}
	currentSatchel = payload and payload.satchel or {}
	statusLabel.Text = ""
	renderAll()
	notifyGuiOpen(true)
end

local function getChestPosition()
	if not currentChest or not currentChest.Parent then
		return nil
	end

	if currentChest:IsA("BasePart") then
		return currentChest.Position
	end

	if currentChest:IsA("Model") then
		return currentChest:GetPivot().Position
	end

	return nil
end

closeButton.MouseButton1Click:Connect(closePanel)

UserInputService.InputChanged:Connect(function(input)
	if dragState and input.UserInputType == Enum.UserInputType.MouseMovement then
		dragGhost.Position = UDim2.fromOffset(input.Position.X + 12, input.Position.Y + 12)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if dragState and input.UserInputType == Enum.UserInputType.MouseButton1 then
		endDrag(Vector2.new(input.Position.X, input.Position.Y))
	end
end)

RemoteEvents.OpenChestUI.OnClientEvent:Connect(openPanel)

RemoteEvents.ChestTransferResult.OnClientEvent:Connect(function(payload)
	if not panelOpen then
		return
	end

	currentChest = payload and payload.chest or currentChest
	currentChestItems = payload and payload.chestItems or currentChestItems
	currentSatchel = payload and payload.satchel or currentSatchel
	renderAll()

	if payload and payload.outcome == "success" then
		statusLabel.Text = "Moved item."
		statusLabel.TextColor3 = COLORS.green
	elseif payload and payload.reason then
		statusLabel.Text = tostring(payload.reason)
		statusLabel.TextColor3 = COLORS.red
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		if panelOpen then
			local character = localPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local chestPosition = getChestPosition()
			if not root or not chestPosition or (root.Position - chestPosition).Magnitude > 10 then
				closePanel()
			end
		end
	end
end)
