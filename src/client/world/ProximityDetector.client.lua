local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InfectionStages = require(Shared.core.InfectionStages)
local GameConstants = require(Shared.core.GameConstants)

local localPlayer = Players.LocalPlayer

-- Other client scripts subscribe to these by reading them as children of this script.
local NPCInRange = Instance.new("BindableEvent")
NPCInRange.Name = "NPCInRange"
NPCInRange.Parent = script

local NPCOutOfRange = Instance.new("BindableEvent")
NPCOutOfRange.Name = "NPCOutOfRange"
NPCOutOfRange.Parent = script

local currentNPC = nil
local comfortTimerHandle = nil

local function isInteractable(stage)
	return stage == InfectionStages.Symptomatic or stage == InfectionStages.Critical
end

local function clearComfortTimer()
	if comfortTimerHandle then
		task.cancel(comfortTimerHandle)
		comfortTimerHandle = nil
	end
end

local function setCurrent(npc)
	if npc == currentNPC then
		return
	end

	if currentNPC then
		NPCOutOfRange:Fire(currentNPC, "walked_away")
		clearComfortTimer()
	end

	currentNPC = npc

	if currentNPC then
		NPCInRange:Fire(currentNPC)
		comfortTimerHandle = task.delay(GameConstants.COMFORT_TIMER, function()
			if currentNPC then
				NPCOutOfRange:Fire(currentNPC, "comfort_timer")
				currentNPC = nil
			end
			comfortTimerHandle = nil
		end)
	end
end

local function findNearestNPC()
	local character = localPlayer.Character
	if not character then
		return nil
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end

	local nearest = nil
	local nearestDist = GameConstants.PROXIMITY_RANGE

	for _, npc in CollectionService:GetTagged("NPC") do
		local stage = npc:GetAttribute("Stage") or InfectionStages.Healthy
		if not isInteractable(stage) then
			continue
		end

		local npcRoot = npc:FindFirstChild("HumanoidRootPart")
		if not npcRoot then
			continue
		end

		local dist = (hrp.Position - npcRoot.Position).Magnitude
		if dist <= nearestDist then
			nearest = npc
			nearestDist = dist
		end
	end

	return nearest
end

while true do
	task.wait(0.2)
	setCurrent(findNearestNPC())
end
