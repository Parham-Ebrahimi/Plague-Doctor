local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local JournalData = require(Server.data.JournalData)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.core.GameConstants)
local ItemData = require(Shared.data.ItemData)

local SatchelData = {}

local satchels = {}
local discoveredItems = {}

local function getInGameDay()
	local secondsPerDay = GameConstants.HOURS_PER_DAY * GameConstants.HOUR_IN_SECONDS
	return math.floor(os.clock() / secondsPerDay)
end

local function emptySatchel()
	local s = {}
	for i = 1, GameConstants.SATCHEL_SIZE do
		s[i] = { itemName = nil, quantity = 0 }
	end
	return s
end

local function markDiscovered(player, itemName)
	local item = ItemData[itemName]
	if not item or not item.isIngredient then
		return
	end

	if not discoveredItems[player.UserId] then
		discoveredItems[player.UserId] = {}
	end

	if discoveredItems[player.UserId][itemName] then
		return
	end

	discoveredItems[player.UserId][itemName] = true
	JournalData.AddEntry(player, "Ingredients", {
		day = getInGameDay(),
		item = itemName,
		content = item.sensoryDescription,
		hint = item.journalHint,
	})
end

function SatchelData.GetSatchel(player)
	if not satchels[player.UserId] then
		satchels[player.UserId] = emptySatchel()
	end
	return satchels[player.UserId]
end

function SatchelData.HasItem(player, itemName)
	local satchel = SatchelData.GetSatchel(player)
	for _, slot in satchel do
		if slot.itemName == itemName and slot.quantity > 0 then
			return true
		end
	end
	return false
end

function SatchelData.GetItemQuantity(player, itemName)
	local satchel = SatchelData.GetSatchel(player)
	local quantity = 0
	for _, slot in satchel do
		if slot.itemName == itemName then
			quantity += slot.quantity
		end
	end
	return quantity
end

function SatchelData.AddItem(player, itemName, qty)
	qty = qty or 1
	if not ItemData[itemName] then
		return false, "unknown item"
	end

	local satchel = SatchelData.GetSatchel(player)

	for _, slot in satchel do
		if slot.itemName == itemName then
			slot.quantity += qty
			markDiscovered(player, itemName)
			return true
		end
	end

	for _, slot in satchel do
		if not slot.itemName or slot.quantity == 0 then
			slot.itemName = itemName
			slot.quantity = qty
			markDiscovered(player, itemName)
			return true
		end
	end

	return false, "satchel full"
end

function SatchelData.RemoveItem(player, itemName, qty)
	qty = qty or 1
	local satchel = SatchelData.GetSatchel(player)

	for _, slot in satchel do
		if slot.itemName == itemName and slot.quantity > 0 then
			slot.quantity -= qty
			if slot.quantity <= 0 then
				slot.itemName = nil
				slot.quantity = 0
			end
			return true
		end
	end
	return false, "no such item"
end

Players.PlayerRemoving:Connect(function(player)
	satchels[player.UserId] = nil
	discoveredItems[player.UserId] = nil
end)

return SatchelData
