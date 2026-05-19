local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local ItemData = require(Shared.data.ItemData)
local SymptomData = require(Shared.data.SymptomData)

local TreatmentRules = {}

TreatmentRules.Outcomes = {
	Success = "success",
	Failure = "failure",
	Adverse = "adverse",
	BroadSpectrum = "broad_spectrum",
}

TreatmentRules.TestResults = {
	Promising = "promising",
	Wrong = "wrong",
	Inert = "inert",
}

TreatmentRules.Recipes = {
	{
		ingredients = { "WillowBark", "Elderflower" },
		resultItem = "FeverTonic",
		symptomCategory = "fever",
	},
	{
		ingredients = { "Camphor", "JuniperBerries" },
		resultItem = "BreathingDraught",
		symptomCategory = "respiratory",
	},
	{
		ingredients = { "Honey", "Vinegar" },
		resultItem = "WoundSalve",
		symptomCategory = "wound",
	},
	{
		ingredients = { "Charcoal", "BitterOil" },
		resultItem = "BroadSpectrumCompound",
		symptomCategory = "broad_spectrum",
	},
	{
		ingredients = { "Sulfur", "Vinegar" },
		resultItem = "FumigationCompound",
		symptomCategory = "environmental",
	},
	{
		ingredients = { "Garlic", "Rue" },
		resultItem = "VascularTincture",
		symptomCategory = "vascular",
	},
	{
		ingredients = { "SleepExtract", "Wormwood" },
		resultItem = "NeuralSedative",
		symptomCategory = "neural",
	},
	{
		ingredients = { "WillowBark", "Wormwood" },
		resultItem = "AmplifiedFeverTonic",
		symptomCategory = "fever",
	},
	{
		ingredients = { "Camphor", "Myrrh" },
		resultItem = "PneumonicDraught",
		symptomCategory = "respiratory",
	},
	{
		ingredients = { "Earthroot", "PlagueMoss" },
		resultItem = "CompoundRemedy",
		symptomCategory = "compound",
	},
}

TreatmentRules.Conflicts = {
	{ "herb", "resin" },
	{ "liquid", "resin" },
	{ "mineral", "mineral" },
	{ "material", "mineral" },
}

local activeRecipes = table.clone(TreatmentRules.Recipes)

local function makePairKey(a, b)
	if a > b then
		a, b = b, a
	end

	return a .. "+" .. b
end

local function makeIngredientKey(ingredientList)
	if type(ingredientList) ~= "table" or #ingredientList ~= 2 then
		return nil
	end

	if type(ingredientList[1]) ~= "string" or type(ingredientList[2]) ~= "string" then
		return nil
	end

	return makePairKey(ingredientList[1], ingredientList[2])
end

local function buildRecipeLookup()
	local lookup = {}
	for _, recipe in activeRecipes do
		lookup[makePairKey(recipe.ingredients[1], recipe.ingredients[2])] = recipe
	end
	return lookup
end

local function buildConflictLookup()
	local lookup = {}
	for _, conflict in TreatmentRules.Conflicts do
		lookup[makePairKey(conflict[1], conflict[2])] = true
	end
	return lookup
end

local function getCategories(ingredientList)
	local categories = {}
	for _, itemName in ingredientList do
		local item = ItemData[itemName]
		if not item or not item.isIngredient then
			return nil
		end
		table.insert(categories, item.category)
	end
	return categories
end

local function hasCategoryConflict(ingredientList)
	local categories = getCategories(ingredientList)
	if not categories or #categories ~= 2 then
		return false
	end

	local conflictLookup = buildConflictLookup()
	return conflictLookup[makePairKey(categories[1], categories[2])] == true
end

local function evaluateCrafting(ingredientList)
	local key = makeIngredientKey(ingredientList)
	if not key then
		return TreatmentRules.Outcomes.Failure, nil
	end

	local recipe = buildRecipeLookup()[key]
	if recipe then
		return TreatmentRules.Outcomes.Success, recipe.resultItem, recipe
	end

	return TreatmentRules.Outcomes.Failure, nil
end

local function evaluateTreatment(itemName, symptoms)
	local item = ItemData[itemName]
	if not item or not item.isRemedy then
		return TreatmentRules.Outcomes.Failure
	end

	if item.isBroadSpectrum then
		return TreatmentRules.Outcomes.BroadSpectrum
	end

	local symptomCategories = item.symptomCategories or {}
	for _, symptomKey in symptoms or {} do
		local symptom = SymptomData[symptomKey]
		if symptom then
			for _, category in symptomCategories do
				if category == symptom.category then
					return TreatmentRules.Outcomes.Success
				end
			end
		end
	end

	return TreatmentRules.Outcomes.Failure
end

function TreatmentRules.Evaluate(firstArg, secondArg)
	if type(firstArg) == "table" and secondArg == nil then
		return evaluateCrafting(firstArg)
	end

	return evaluateTreatment(firstArg, secondArg)
end

function TreatmentRules.GetTestResult(ingredientList)
	local outcome, resultItem = evaluateCrafting(ingredientList)
	if outcome == TreatmentRules.Outcomes.Success then
		return TreatmentRules.TestResults.Promising, resultItem
	end

	if hasCategoryConflict(ingredientList) then
		return TreatmentRules.TestResults.Wrong, nil
	end

	return TreatmentRules.TestResults.Inert, nil
end

function TreatmentRules.ApplyMutation(mutationData)
	if type(mutationData) ~= "table" then
		return false
	end

	if type(mutationData.recipes) == "table" then
		activeRecipes = table.clone(TreatmentRules.Recipes)
		for _, recipe in mutationData.recipes do
			table.insert(activeRecipes, recipe)
		end
	end

	return true
end

return TreatmentRules
