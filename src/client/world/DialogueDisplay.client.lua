local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DialogueData = require(Shared.data.DialogueData)
local InfectionStages = require(Shared.core.InfectionStages)

local localPlayer = Players.LocalPlayer
local clientFolder = localPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local proximityScript = clientFolder:WaitForChild("world"):WaitForChild("ProximityDetector")
local NPCInRange = proximityScript:WaitForChild("NPCInRange")

local activeBubbles = {}

local function clearBubble(npc)
	local existing = activeBubbles[npc]
	if existing and existing.Parent then
		existing:Destroy()
	end
	activeBubbles[npc] = nil
end

local function showLine(npc, line)
	clearBubble(npc)

	local root = npc:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(220, 60)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = root
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.BackgroundTransparency = 0.25
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextWrapped = true
	label.Text = line
	label.Parent = billboard

	activeBubbles[npc] = billboard

	task.delay(4.5, function()
		if activeBubbles[npc] == billboard then
			clearBubble(npc)
		end
	end)
end

NPCInRange.Event:Connect(function(npc)
	local stage = npc:GetAttribute("Stage") or InfectionStages.Healthy
	local condition
	if stage == InfectionStages.Critical then
		condition = "critical"
	elseif stage == InfectionStages.Symptomatic then
		condition = "symptomatic"
	else
		return
	end

	local line = DialogueData.GetLine(condition)
	if line then
		showLine(npc, line)
	end
end)
