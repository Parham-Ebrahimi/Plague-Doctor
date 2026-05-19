local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Server = ServerScriptService:WaitForChild("Server")
local SatchelData = require(Server.player.SatchelData)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemData = require(Shared.data.ItemData)
local RemoteEvents = require(Shared.core.RemoteEvents)

local CHEST_DISTANCE = 8

local chestInventories = {}

local function makeIngredientStock()
	local stock = {}
	for itemName, item in ItemData do
		if item.isIngredient then
			stock[itemName] = 5
		end
	end
	return stock
end

local function getChestInventory(chest)
	if not chestInventories[chest] then
		chestInventories[chest] = makeIngredientStock()
	end
	return chestInventories[chest]
end

local function getChestPayload(chest)
	local inventory = getChestInventory(chest)
	local list = {}

	for itemName, quantity in inventory do
		if quantity > 0 then
			table.insert(list, {
				itemName = itemName,
				quantity = quantity,
			})
		end
	end

	table.sort(list, function(a, b)
		local itemA = ItemData[a.itemName]
		local itemB = ItemData[b.itemName]
		local labelA = itemA and itemA.displayName or a.itemName
		local labelB = itemB and itemB.displayName or b.itemName
		return labelA < labelB
	end)

	return list
end

local function getPromptParent(chest)
	if chest:IsA("BasePart") then
		return chest
	end

	if chest:IsA("Model") then
		return chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart", true)
	end

	return nil
end

local function isPlayerNearChest(player, chest)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not chest or not chest.Parent then
		return false
	end

	local chestPosition
	if chest:IsA("BasePart") then
		chestPosition = chest.Position
	elseif chest:IsA("Model") then
		chestPosition = chest:GetPivot().Position
	else
		return false
	end

	return (root.Position - chestPosition).Magnitude <= CHEST_DISTANCE + 3
end

local function fireChestState(player, chest, outcome, reason)
	RemoteEvents.ChestTransferResult:FireClient(player, {
		outcome = outcome,
		reason = reason,
		chest = chest,
		chestItems = getChestPayload(chest),
		satchel = SatchelData.GetSatchel(player),
	})
end

local function setupChest(chest)
	if string.lower(chest.Name) ~= "chest" or chest:GetAttribute("ChestReady") then
		return
	end

	if not chest:IsA("Model") and not chest:IsA("BasePart") then
		return
	end

	local promptParent = getPromptParent(chest)
	if not promptParent then
		return
	end

	chest:SetAttribute("ChestReady", true)

	local prompt = promptParent:FindFirstChild("ChestPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ChestPrompt"
		prompt.Parent = promptParent
	end

	prompt.ActionText = "Open"
	prompt.ObjectText = "Chest"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = CHEST_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0

	prompt.Triggered:Connect(function(player)
		RemoteEvents.OpenChestUI:FireClient(player, {
			chest = chest,
			chestItems = getChestPayload(chest),
			satchel = SatchelData.GetSatchel(player),
		})
	end)

	chest.AncestryChanged:Connect(function()
		if not chest:IsDescendantOf(game) then
			chestInventories[chest] = nil
		end
	end)
end

RemoteEvents.MoveChestItem.OnServerEvent:Connect(function(player, chest, direction, itemName)
	if typeof(chest) ~= "Instance" or (not chest:IsA("Model") and not chest:IsA("BasePart")) then
		return
	end
	if type(direction) ~= "string" or type(itemName) ~= "string" then
		return
	end
	if not isPlayerNearChest(player, chest) then
		return
	end

	local item = ItemData[itemName]
	if not item or not item.isIngredient then
		fireChestState(player, chest, "failure", "invalid_item")
		return
	end

	local inventory = getChestInventory(chest)

	if direction == "chest_to_satchel" then
		if (inventory[itemName] or 0) <= 0 then
			fireChestState(player, chest, "failure", "chest_empty")
			return
		end

		local added, reason = SatchelData.AddItem(player, itemName, 1)
		if not added then
			fireChestState(player, chest, "failure", reason)
			return
		end

		inventory[itemName] -= 1
		fireChestState(player, chest, "success", nil)
	elseif direction == "satchel_to_chest" then
		local removed, reason = SatchelData.RemoveItem(player, itemName, 1)
		if not removed then
			fireChestState(player, chest, "failure", reason)
			return
		end

		inventory[itemName] = (inventory[itemName] or 0) + 1
		fireChestState(player, chest, "success", nil)
	end
end)

for _, descendant in Workspace:GetDescendants() do
	setupChest(descendant)
end

Workspace.DescendantAdded:Connect(setupChest)
