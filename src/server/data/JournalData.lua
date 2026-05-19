local Players = game:GetService("Players")

local JournalData = {}

local SECTIONS = {
	Remedies = true,
	Ingredients = true,
	Findings = true,
}

local journals = {}

local function emptyJournal()
	return {
		Remedies = {},
		Ingredients = {},
		Findings = {},
	}
end

local function getJournal(player)
	if not journals[player.UserId] then
		journals[player.UserId] = emptyJournal()
	end
	return journals[player.UserId]
end

-- Two symptom arrays match if they contain the same items, regardless of order.
local function symptomsMatch(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end

	if #a ~= #b then
		return false
	end

	local seen = {}
	for _, value in a do
		seen[value] = true
	end

	for _, value in b do
		if not seen[value] then
			return false
		end
	end

	return true
end

local function makeCombinationKey(items)
	if type(items) ~= "table" or #items == 0 then
		return nil
	end

	local copy = table.clone(items)
	table.sort(copy)
	return table.concat(copy, "+")
end

local function remedyHas(entries, itemName, symptoms, ingredients)
	for _, existing in entries do
		local existingName = existing.item or existing.itemUsed
		local symptomsSame = symptoms and symptomsMatch(existing.symptoms or existing.symptomSet, symptoms)
		local ingredientsSame = ingredients
			and makeCombinationKey(existing.ingredients) == makeCombinationKey(ingredients)

		if existingName == itemName and (symptomsSame or ingredientsSame) then
			return true
		end
	end

	return false
end

local function ingredientNoteHas(entries, itemName, combinationKey)
	for _, existing in entries do
		local existingName = existing.item or existing.itemUsed
		if itemName and existingName == itemName then
			return true
		end
		if combinationKey and existing.combinationKey == combinationKey then
			return true
		end
	end

	return false
end

function JournalData.IsValidSection(section)
	return SECTIONS[section] == true
end

function JournalData.AddEntry(player, section, entry)
	if not SECTIONS[section] then
		warn("[JournalData] unknown section: " .. tostring(section))
		return false
	end

	if type(entry) ~= "table" then
		return false
	end

	local sectionEntries = getJournal(player)[section]

	if section == "Remedies" then
		local symptoms = entry.symptoms or entry.symptomSet
		local ingredients = entry.ingredients
		local itemName = entry.item or entry.itemUsed or entry.resultItem
		if not itemName or (not symptoms and not ingredients) or remedyHas(sectionEntries, itemName, symptoms, ingredients) then
			return false
		end
	elseif section == "Ingredients" then
		local itemName = entry.item or entry.itemUsed
		local combinationKey = entry.combinationKey or makeCombinationKey(entry.combination)
		if not itemName and not combinationKey then
			return false
		end
		entry.combinationKey = combinationKey
		if ingredientNoteHas(sectionEntries, itemName, combinationKey) then
			return false
		end
	end

	table.insert(sectionEntries, entry)
	return true
end

function JournalData.GetSection(player, section)
	if not SECTIONS[section] then
		return {}
	end

	local entries = getJournal(player)[section]

	local copy = table.create(#entries)
	for index, entry in entries do
		copy[index] = entry
	end

	table.sort(copy, function(a, b)
		local dayA = tonumber(a.day) or 0
		local dayB = tonumber(b.day) or 0
		return dayA > dayB
	end)

	return copy
end

Players.PlayerRemoving:Connect(function(player)
	journals[player.UserId] = nil
end)

return JournalData
