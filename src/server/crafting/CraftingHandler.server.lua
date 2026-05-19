local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Server = ServerScriptService:WaitForChild("Server")
local JournalData = require(Server.data.JournalData)
local SatchelData = require(Server.player.SatchelData)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.core.GameConstants)
local ItemData = require(Shared.data.ItemData)
local RemoteEvents = require(Shared.core.RemoteEvents)
local TreatmentRules = require(Shared.rules.TreatmentRules)

local WORKBENCH_NAME = "Workbench"
local WORKBENCH_DISTANCE = 8

local function getInGameDay()
	local secondsPerDay = GameConstants.HOURS_PER_DAY * GameConstants.HOUR_IN_SECONDS
	return math.floor(os.clock() / secondsPerDay)
end

local function copyList(list)
	local copy = {}
	for index, value in list do
		copy[index] = value
	end
	return copy
end

local function makeCombinationKey(ingredientList, status)
	local copy = copyList(ingredientList)
	table.sort(copy)
	return tostring(status) .. ":" .. table.concat(copy, "+")
end

local function getItemLabel(itemName)
	local item = ItemData[itemName]
	return item and item.displayName or tostring(itemName)
end

local function formatIngredientList(ingredientList)
	local labels = {}
	for _, itemName in ingredientList do
		table.insert(labels, getItemLabel(itemName))
	end
	return table.concat(labels, " + ")
end

local function normalizeIngredientList(ingredientList)
	if type(ingredientList) ~= "table" or #ingredientList ~= 2 then
		return nil
	end

	local normalized = {}
	for index = 1, 2 do
		local itemName = ingredientList[index]
		local item = type(itemName) == "string" and ItemData[itemName] or nil
		if not item or not item.isIngredient then
			return nil
		end
		normalized[index] = itemName
	end

	return normalized
end

local function playerHasIngredients(player, ingredientList)
	local required = {}
	for _, itemName in ingredientList do
		required[itemName] = (required[itemName] or 0) + 1
	end

	for itemName, quantity in required do
		if SatchelData.GetItemQuantity(player, itemName) < quantity then
			return false
		end
	end

	return true
end

local function removeIngredients(player, ingredientList)
	for _, itemName in ingredientList do
		SatchelData.RemoveItem(player, itemName, 1)
	end
end

local function logRecipeDiscovery(player, resultItem, ingredientList, recipe)
	local result = ItemData[resultItem]
	if not result then
		return false
	end

	return JournalData.AddEntry(player, "Remedies", {
		day = getInGameDay(),
		item = resultItem,
		ingredients = copyList(ingredientList),
		symptomCategories = result.symptomCategories,
		category = recipe and recipe.symptomCategory,
	})
end

local function logMixtureNote(player, ingredientList, status)
	local label = formatIngredientList(ingredientList)
	local note
	if status == TreatmentRules.TestResults.Wrong then
		note = label .. " reacted badly. The categories fight each other."
	elseif status == TreatmentRules.TestResults.Inert then
		note = label .. " produced no useful reaction."
	else
		note = label .. " failed at the bench."
	end

	JournalData.AddEntry(player, "Ingredients", {
		day = getInGameDay(),
		combination = copyList(ingredientList),
		combinationKey = makeCombinationKey(ingredientList, status),
		status = status,
		content = note,
	})
end

RemoteEvents.TestMixture.OnServerEvent:Connect(function(player, ingredientList)
	local normalized = normalizeIngredientList(ingredientList)
	if not normalized then
		RemoteEvents.TestMixtureResult:FireClient(player, {
			result = TreatmentRules.TestResults.Inert,
			resultItem = nil,
		})
		return
	end

	local result, resultItem = TreatmentRules.GetTestResult(normalized)
	if result == TreatmentRules.TestResults.Wrong or result == TreatmentRules.TestResults.Inert then
		logMixtureNote(player, normalized, result)
	end

	RemoteEvents.TestMixtureResult:FireClient(player, {
		result = result,
		resultItem = resultItem,
		ingredients = normalized,
	})
end)

RemoteEvents.AttemptCraft.OnServerEvent:Connect(function(player, ingredientList)
	local normalized = normalizeIngredientList(ingredientList)
	if not normalized then
		RemoteEvents.AttemptCraftResult:FireClient(player, {
			outcome = TreatmentRules.Outcomes.Failure,
			reason = "invalid_ingredients",
			satchel = SatchelData.GetSatchel(player),
		})
		return
	end

	if not playerHasIngredients(player, normalized) then
		RemoteEvents.AttemptCraftResult:FireClient(player, {
			outcome = TreatmentRules.Outcomes.Failure,
			reason = "missing_ingredients",
			satchel = SatchelData.GetSatchel(player),
		})
		return
	end

	removeIngredients(player, normalized)

	local outcome, resultItem, recipe = TreatmentRules.Evaluate(normalized)
	if outcome == TreatmentRules.Outcomes.Success and resultItem then
		local added, reason = SatchelData.AddItem(player, resultItem, 1)
		if not added then
			RemoteEvents.AttemptCraftResult:FireClient(player, {
				outcome = TreatmentRules.Outcomes.Failure,
				reason = reason,
				satchel = SatchelData.GetSatchel(player),
			})
			return
		end

		logRecipeDiscovery(player, resultItem, normalized, recipe)
		RemoteEvents.AttemptCraftResult:FireClient(player, {
			outcome = outcome,
			resultItem = resultItem,
			ingredients = normalized,
			satchel = SatchelData.GetSatchel(player),
		})
	else
		logMixtureNote(player, normalized, TreatmentRules.Outcomes.Failure)
		RemoteEvents.AttemptCraftResult:FireClient(player, {
			outcome = TreatmentRules.Outcomes.Failure,
			reason = "bad_recipe",
			ingredients = normalized,
			satchel = SatchelData.GetSatchel(player),
		})
	end
end)

local function getPromptParent(workbench)
	if workbench:IsA("BasePart") then
		return workbench
	end

	if workbench:IsA("Model") then
		return workbench.PrimaryPart or workbench:FindFirstChildWhichIsA("BasePart", true)
	end

	return nil
end

local function setupWorkbench(workbench)
	if workbench.Name ~= WORKBENCH_NAME or workbench:GetAttribute("CraftingReady") then
		return
	end

	if not workbench:IsA("Model") and not workbench:IsA("BasePart") then
		return
	end

	local promptParent = getPromptParent(workbench)
	if not promptParent then
		return
	end

	workbench:SetAttribute("CraftingReady", true)

	local prompt = promptParent:FindFirstChild("CraftingPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CraftingPrompt"
		prompt.Parent = promptParent
	end

	prompt.ActionText = "Craft"
	prompt.ObjectText = "Workbench"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = WORKBENCH_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0

	prompt.Triggered:Connect(function(player)
		RemoteEvents.OpenCraftingUI:FireClient(player, {
			workbench = workbench,
			satchel = SatchelData.GetSatchel(player),
		})
	end)
end

for _, descendant in Workspace:GetDescendants() do
	setupWorkbench(descendant)
end

Workspace.DescendantAdded:Connect(setupWorkbench)
