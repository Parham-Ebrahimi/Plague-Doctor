local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.core.GameConstants)

local activeNPCs = {}

local function getRandomOffset(radius)
	return Vector3.new(
		math.random(-radius, radius),
		0,
		math.random(-radius, radius)
	)
end

local function setupNPC(npc)
	if activeNPCs[npc] then
		return
	end

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local root = npc:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		warn("[NPCWanderTest] NPC needs a Humanoid and HumanoidRootPart: " .. npc:GetFullName())
		return
	end

	activeNPCs[npc] = true

	task.spawn(function()
		local spawnPosition = root.Position

		while activeNPCs[npc] and npc:IsDescendantOf(game) and humanoid.Health > 0 do
			if npc:GetAttribute("MovementLocked") or npc:GetAttribute("Quarantined") then
				humanoid:MoveTo(root.Position)
				task.wait(0.5)
				continue
			end

			local offset = getRandomOffset(GameConstants.NPC_WANDER_RADIUS)
			local destination = spawnPosition + offset

			humanoid:MoveTo(destination)

			task.wait(math.random(
				GameConstants.NPC_WANDER_INTERVAL_MIN,
				GameConstants.NPC_WANDER_INTERVAL_MAX
			))
		end

		activeNPCs[npc] = nil
	end)

	npc.AncestryChanged:Connect(function()
		if not npc:IsDescendantOf(game) then
			activeNPCs[npc] = nil
		end
	end)
end

for _, npc in CollectionService:GetTagged("NPC") do
	setupNPC(npc)
end

CollectionService:GetInstanceAddedSignal("NPC"):Connect(setupNPC)
