local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InfectionStages = require(Shared.core.InfectionStages)
local Humours = require(Shared.core.Humours)
local GameConstants = require(Shared.core.GameConstants)
local SymptomData = require(Shared.data.SymptomData)

local NPCData = {}

local entries = {}
local stageChangedCallbacks = {}

local SYMPTOM_POOLS = {
	default = { "fever", "cough", "laboured_breathing", "pale_skin" },
	plague = { "dark_swelling", "fever", "tremors", "pale_skin", "laboured_breathing" },
}

local function pickSymptoms(npc)
	local poolName = npc:GetAttribute("DiseaseType") or "default"
	local pool = SYMPTOM_POOLS[poolName] or SYMPTOM_POOLS.default

	local count = math.random(2, math.min(3, #pool))
	local picks = {}
	local used = {}
	while #picks < count do
		local idx = math.random(1, #pool)
		if not used[idx] then
			used[idx] = true
			table.insert(picks, pool[idx])
		end
	end
	return picks
end

local function rollHumours()
	local values = {}
	for _, humourName in Humours.Names do
		values[humourName] = math.random(
			GameConstants.HUMOUR_VALUE_MIN,
			GameConstants.HUMOUR_VALUE_MAX
		)
	end
	return values
end

function NPCData.Register(npc)
	if entries[npc] then
		return
	end

	local startStage = npc:GetAttribute("StartStage") or InfectionStages.Healthy

	entries[npc] = {
		stage = startStage,
		stageTimer = 0,
		district = npc:GetAttribute("District") or "Unknown",
		npcType = npc:GetAttribute("NPCType") or "Resident",
		symptoms = {},
		quarantined = false,
		broadSpectrumExpiry = nil,
		treatedByPlayer = {},
		-- Humours are generated once at registration and are
		-- intentionally NOT re-rolled on stage transitions; they
		-- represent stable patient state, unlike symptoms.
		humours = rollHumours(),
	}

	npc:SetAttribute("Stage", startStage)

	if startStage >= InfectionStages.Symptomatic and startStage < InfectionStages.Dead then
		entries[npc].symptoms = pickSymptoms(npc)
	end

	npc.AncestryChanged:Connect(function()
		if not npc:IsDescendantOf(game) then
			entries[npc] = nil
		end
	end)
end

function NPCData.GetEntry(npc)
	return entries[npc]
end

function NPCData.GetStage(npc)
	local e = entries[npc]
	return e and e.stage or InfectionStages.Healthy
end

function NPCData.SetStage(npc, newStage)
	local e = entries[npc]
	if not e then
		return
	end

	local oldStage = e.stage
	e.stage = newStage
	e.stageTimer = 0

	npc:SetAttribute("Stage", newStage)

	-- Symptoms appear once at stage 3 and stay through stage 4. Cleared on recovery.
	if newStage == InfectionStages.Symptomatic and #e.symptoms == 0 then
		e.symptoms = pickSymptoms(npc)
	elseif newStage <= InfectionStages.Exposed then
		e.symptoms = {}
	end

	for _, cb in stageChangedCallbacks do
		task.spawn(cb, npc, newStage, oldStage)
	end
end

function NPCData.GetSymptoms(npc)
	local e = entries[npc]
	return e and e.symptoms or {}
end

-- Returns a list of symptom keys present on this NPC, derived from
-- the NPC's hidden humour values. Pure derivation — does not mutate
-- entry state, does not read entry.symptoms. Iterates new-schema
-- SymptomData entries; legacy entries (cough, laboured_breathing,
-- etc.) are skipped because they lack the humour and threshold
-- fields. See docs/symptom-vocabulary.md for the symptom-discovery
-- design.
--
-- Does not gate on NPC stage. rollHumours runs on every NPC at
-- Register, including Healthy ones, so calling ComputeSymptoms on
-- a Healthy NPC will return symptoms based on their random humour
-- values. The current call path (examination) already gates on
-- Symptomatic/Critical at the request level. The deferred decision
-- about natural temperaments (current-status.md) sits upstream of
-- this behaviour.
function NPCData.ComputeSymptoms(npc)
	local entry = entries[npc]
	if not entry then
		return {}
	end

	local present = {}
	for symptomKey, symptomData in pairs(SymptomData) do
		if symptomData.humour
			and symptomData.threshold
			and symptomData.direction
		then
			local humourValue = entry.humours[symptomData.humour]
			if humourValue then
				if symptomData.direction == "excess"
					and humourValue >= symptomData.threshold
				then
					table.insert(present, symptomKey)
				elseif symptomData.direction == "deficiency"
					and humourValue <= symptomData.threshold
				then
					table.insert(present, symptomKey)
				end
			end
		end
	end

	return present
end

function NPCData.SetQuarantined(npc, value)
	local e = entries[npc]
	if not e then
		return
	end
	e.quarantined = value
	npc:SetAttribute("Quarantined", value)
end

function NPCData.IsQuarantined(npc)
	local e = entries[npc]
	return e ~= nil and e.quarantined
end

function NPCData.SetBroadSpectrumActive(npc, durationSeconds)
	local e = entries[npc]
	if not e then
		return
	end
	e.broadSpectrumExpiry = os.clock() + durationSeconds
end

function NPCData.IsBroadSpectrumActive(npc)
	local e = entries[npc]
	return e ~= nil and e.broadSpectrumExpiry ~= nil and os.clock() < e.broadSpectrumExpiry
end

function NPCData.MarkTreatedBy(npc, player)
	local e = entries[npc]
	if not e then
		return
	end
	e.treatedByPlayer[player.UserId] = true
end

function NPCData.WasTreatedBy(npc, player)
	local e = entries[npc]
	return e ~= nil and e.treatedByPlayer[player.UserId] == true
end

function NPCData.GetAll()
	return entries
end

function NPCData.OnStageChanged(callback)
	table.insert(stageChangedCallbacks, callback)
end

function NPCData.RegisterAllTagged()
	for _, npc in CollectionService:GetTagged("NPC") do
		NPCData.Register(npc)
	end
	CollectionService:GetInstanceAddedSignal("NPC"):Connect(NPCData.Register)
end

return NPCData
