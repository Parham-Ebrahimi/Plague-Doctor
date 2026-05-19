local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InfectionStages = require(Shared.core.InfectionStages)
local GameConstants = require(Shared.core.GameConstants)

local NPCVisuals = {}

local DEFAULT_COLOR = Color3.fromRGB(163, 162, 165)
--local COUGH_SOUND_ID = "rbxassetid://6379893292"

local activeCoughLoops = {}

local function setNPCColor(npc, color)
	for _, descendant in npc:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Color = color
		end
	end
end

function NPCVisuals.AddCoughSound(npc)
	if activeCoughLoops[npc] then
		return
	end

	local root = npc:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = "CoughSound"
	sound.SoundId = COUGH_SOUND_ID
	sound.Volume = 0.6
	sound.RollOffMaxDistance = 30
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.Parent = root

	local active = true
	activeCoughLoops[npc] = function()
		active = false
		sound:Destroy()
	end

	task.spawn(function()
		while active do
			task.wait(math.random(GameConstants.COUGH_INTERVAL_MIN, GameConstants.COUGH_INTERVAL_MAX))
			if active and sound.Parent then
				sound:Play()
			end
		end
	end)
end

function NPCVisuals.RemoveCoughSound(npc)
	local stop = activeCoughLoops[npc]
	if stop then
		stop()
		activeCoughLoops[npc] = nil
	end
end

function NPCVisuals.UpdateAppearance(npc, stage)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = GameConstants.WALK_SPEEDS[stage] or 16

	local color = GameConstants.STAGE_COLORS[stage] or DEFAULT_COLOR
	setNPCColor(npc, color)

	if stage == InfectionStages.Symptomatic or stage == InfectionStages.Critical then
		NPCVisuals.AddCoughSound(npc)
	else
		NPCVisuals.RemoveCoughSound(npc)
	end

	if stage == InfectionStages.Dead then
		humanoid.Health = 0
		npc:SetAttribute("Dead", true)
	end
end

return NPCVisuals
