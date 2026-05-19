local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Server = ServerScriptService:WaitForChild("Server")
local NPCData = require(Server.npc.NPCData)
local SatchelData = require(Server.player.SatchelData)
local JournalData = require(Server.data.JournalData)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InfectionStages = require(Shared.core.InfectionStages)
local GameConstants = require(Shared.core.GameConstants)
local ItemData = require(Shared.data.ItemData)
local SymptomData = require(Shared.data.SymptomData)
local TreatmentRules = require(Shared.rules.TreatmentRules)
local RemoteEvents = require(Shared.core.RemoteEvents)

local activeExaminations = {}

local function getInGameDay()
	-- Placeholder until DayNightCycle exists.
	local secondsPerDay = GameConstants.HOURS_PER_DAY * GameConstants.HOUR_IN_SECONDS
	return math.floor(os.clock() / secondsPerDay)
end

local function isPlayerNearNPC(player, npc, maxDistance)
	local character = player.Character
	if not character then
		return false
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")
	if not hrp or not npcRoot then
		return false
	end

	return (hrp.Position - npcRoot.Position).Magnitude <= maxDistance
end

local function stopNPCMovement(npc)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local root = npc:FindFirstChild("HumanoidRootPart")

	npc:SetAttribute("MovementLocked", true)

	if humanoid then
		humanoid:MoveTo(root and root.Position or npc:GetPivot().Position)
		humanoid.WalkSpeed = 0
	end

	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end

local function restoreNPCMovement(npc)
	local entry = NPCData.GetEntry(npc)
	if not entry or entry.quarantined then
		return
	end

	npc:SetAttribute("MovementLocked", false)

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = GameConstants.WALK_SPEEDS[entry.stage] or 16
	end
end

local function setActiveExamination(player, npc)
	local previous = activeExaminations[player]
	if previous and previous ~= npc then
		restoreNPCMovement(previous)
	end

	activeExaminations[player] = npc
	stopNPCMovement(npc)
end

local function clearActiveExamination(player, npc)
	if activeExaminations[player] ~= npc then
		return
	end

	activeExaminations[player] = nil

	if NPCData.GetEntry(npc) then
		restoreNPCMovement(npc)
	else
		npc:SetAttribute("MovementLocked", false)
	end
end

local function applyQuarantine(npc)
	NPCData.SetQuarantined(npc, true)

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:MoveTo(npc:GetPivot().Position)
		humanoid.WalkSpeed = 0
	end

	local root = npc:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.Anchored = true
	end

	if root and not root:FindFirstChild("QuarantineFlag") then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "QuarantineFlag"
		billboard.Size = UDim2.fromOffset(100, 30)
		billboard.StudsOffset = Vector3.new(0, 3.5, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = root

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
		label.BackgroundTransparency = 0.2
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Text = "QUARANTINE"
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = billboard
	end
end

local function removeQuarantine(npc)
	NPCData.SetQuarantined(npc, false)
	npc:SetAttribute("MovementLocked", false)

	local root = npc:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = false
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		local flag = root:FindFirstChild("QuarantineFlag")
		if flag then
			flag:Destroy()
		end
	end

	restoreNPCMovement(npc)
end

local function getImprovedSymptomLabels(itemName, symptoms)
	local item = ItemData[itemName]
	if not item then
		return {}
	end

	local categories = {}
	local symptomCategories = item.symptomCategories or {}
	for _, category in symptomCategories do
		categories[category] = true
	end

	local labels = {}
	for _, symptomKey in symptoms do
		local symptom = SymptomData[symptomKey]
		if symptom and categories[symptom.category] then
			table.insert(labels, symptom.label)
		end
	end

	return labels
end

RemoteEvents.RequestExamination.OnServerEvent:Connect(function(player, npc)
	if typeof(npc) ~= "Instance" or not npc:IsA("Model") then
		return
	end

	if not isPlayerNearNPC(player, npc, GameConstants.EXAM_VALID_RANGE) then
		return
	end

	local entry = NPCData.GetEntry(npc)
	if not entry then
		return
	end

	if entry.stage ~= InfectionStages.Symptomatic and entry.stage ~= InfectionStages.Critical then
		return
	end

	setActiveExamination(player, npc)

	-- Turn the NPC to face the examining player (Y-axis only) before the client
	-- computes the examination camera framing from the NPC HumanoidRootPart
	-- LookVector. Graceful degradation: if either root is missing, skip the
	-- rotation and continue with the examination as normal.
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")
	local playerCharacter = player.Character
	local playerRoot = playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")
	if npcRoot and playerRoot then
		local npcPosition = npcRoot.Position
		local playerPosition = playerRoot.Position
		npcRoot.CFrame = CFrame.lookAt(
			npcPosition,
			Vector3.new(playerPosition.X, npcPosition.Y, playerPosition.Z)
		)
	end

	RemoteEvents.ExaminationApproved:FireClient(player, {
		npcRef = npc,
		npcName = npc:GetAttribute("DisplayName") or entry.npcType,
		stage = entry.stage,
		symptoms = entry.symptoms,
		quarantined = entry.quarantined,
		treatedByPlayer = NPCData.WasTreatedBy(npc, player),
		satchel = SatchelData.GetSatchel(player),
	})
end)

RemoteEvents.CloseExamination.OnServerEvent:Connect(function(player, npc)
	if typeof(npc) ~= "Instance" or not npc:IsA("Model") then
		return
	end

	clearActiveExamination(player, npc)
end)

RemoteEvents.AttemptTreatment.OnServerEvent:Connect(function(player, npc, itemName)
	if typeof(npc) ~= "Instance" or not npc:IsA("Model") then
		return
	end
	if type(itemName) ~= "string" then
		return
	end

	if not isPlayerNearNPC(player, npc, GameConstants.EXAM_VALID_RANGE) then
		return
	end

	local entry = NPCData.GetEntry(npc)
	if not entry then
		clearActiveExamination(player, npc)
		RemoteEvents.TreatmentResult:FireClient(player, "no_target")
		return
	end

	if entry.stage == InfectionStages.Dead then
		clearActiveExamination(player, npc)
		RemoteEvents.TreatmentResult:FireClient(player, "no_target")
		return
	end

	if not SatchelData.HasItem(player, itemName) then
		clearActiveExamination(player, npc)
		RemoteEvents.TreatmentResult:FireClient(player, "no_item")
		return
	end

	local item = ItemData[itemName]
	if not item or not item.isRemedy then
		clearActiveExamination(player, npc)
		RemoteEvents.TreatmentResult:FireClient(player, "invalid_item")
		return
	end

	SatchelData.RemoveItem(player, itemName, 1)

	local outcome = TreatmentRules.Evaluate(itemName, entry.symptoms)

	if outcome == TreatmentRules.Outcomes.BroadSpectrum then
		local durationSeconds = GameConstants.BROAD_SPECTRUM_DURATION_DAYS
			* GameConstants.HOURS_PER_DAY
			* GameConstants.HOUR_IN_SECONDS
		NPCData.SetBroadSpectrumActive(npc, durationSeconds)
		clearActiveExamination(player, npc)
		RemoteEvents.TreatmentResult:FireClient(player, "broad_spectrum")
		return
	end

	if outcome == TreatmentRules.Outcomes.Success then
		local nextStage = math.max(InfectionStages.Healthy, entry.stage - 1)
		local treatedSymptoms = table.clone(entry.symptoms)
		local improved = getImprovedSymptomLabels(itemName, treatedSymptoms)
		NPCData.SetStage(npc, nextStage)
		NPCData.MarkTreatedBy(npc, player)

		JournalData.AddEntry(player, "Remedies", {
			day = getInGameDay(),
			symptoms = treatedSymptoms,
			item = itemName,
			improved = improved,
		})

		clearActiveExamination(player, npc)
		RemoteEvents.TreatmentResult:FireClient(player, "success")
	else
		clearActiveExamination(player, npc)
		RemoteEvents.TreatmentResult:FireClient(player, "failure")
	end
end)

RemoteEvents.AttemptQuarantine.OnServerEvent:Connect(function(player, npc)
	if typeof(npc) ~= "Instance" or not npc:IsA("Model") then
		return
	end

	if not isPlayerNearNPC(player, npc, GameConstants.EXAM_VALID_RANGE) then
		return
	end

	local entry = NPCData.GetEntry(npc)
	if not entry then
		return
	end

	if entry.quarantined then
		RemoteEvents.QuarantineResult:FireClient(player, "already_quarantined")
		return
	end

	if not SatchelData.HasItem(player, "QuarantineMarker") then
		RemoteEvents.QuarantineResult:FireClient(player, "no_marker")
		return
	end

	SatchelData.RemoveItem(player, "QuarantineMarker", 1)
	applyQuarantine(npc)

	activeExaminations[player] = nil
	RemoteEvents.QuarantineResult:FireClient(player, "success")
end)

RemoteEvents.AttemptUnquarantine.OnServerEvent:Connect(function(player, npc)
	if typeof(npc) ~= "Instance" or not npc:IsA("Model") then
		return
	end

	if not isPlayerNearNPC(player, npc, GameConstants.EXAM_VALID_RANGE) then
		return
	end

	local entry = NPCData.GetEntry(npc)
	if not entry then
		return
	end

	if not entry.quarantined then
		RemoteEvents.QuarantineResult:FireClient(player, "not_quarantined")
		return
	end

	activeExaminations[player] = nil
	removeQuarantine(npc)
	RemoteEvents.QuarantineResult:FireClient(player, "unquarantine_success")
end)

Players.PlayerRemoving:Connect(function(player)
	local npc = activeExaminations[player]
	if npc then
		clearActiveExamination(player, npc)
	end
end)
