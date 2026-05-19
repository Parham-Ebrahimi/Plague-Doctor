local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Humours = require(Shared.core.Humours)

local localPlayer = Players.LocalPlayer
local clientFolder = localPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")

local examinationStateScript = clientFolder:WaitForChild("world"):WaitForChild("ExaminationState")
local ExaminationState = require(examinationStateScript)
local currentNPCChanged = examinationStateScript:WaitForChild("CurrentNPCChanged")

local treatmentPanelScript = clientFolder:WaitForChild("ui"):WaitForChild("TreatmentPanelUI")
local setHumour = treatmentPanelScript:WaitForChild("SetHumour")

local camera = Workspace.CurrentCamera

-- Tracks which humours have already been revealed for the
-- currently-examined NPC. Keyed by humour display-name. Reset
-- whenever the examined NPC reference changes (including
-- transitions to nil), so re-examining the same NPC after
-- Leave starts fresh — consistent with the panel's
-- resetHumourValues() on every open.
local revealedHumours = {}

currentNPCChanged.Event:Connect(function()
	-- Reset on every transition (start of new examination
	-- or end of current one). Both same-NPC re-examination
	-- and different-NPC examination correctly start fresh.
	revealedHumours = {}
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	local currentNPC = ExaminationState.GetCurrentNPC()
	if not currentNPC then
		return
	end

	local mouseLocation = UserInputService:GetMouseLocation()
	local unitRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	-- NPC-Include filter: the raycast only hits descendants of
	-- the currently-examined NPC. Other NPCs, world geometry,
	-- and the local character (which is faded out during exam
	-- anyway) are all ignored. With this filter we don't need
	-- an explicit distance clamp — the only thing the ray can
	-- hit is the examined NPC itself.
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { currentNPC }
	raycastParams.IgnoreWater = true

	-- Cast progressively further along the ray, treating unmapped
	-- parts as transparent. HumanoidRootPart (invisible, present on
	-- every R15 rig) and accessory Handles (hair, beard, hats) are
	-- the typical occluders. Without passthrough, the ray hits them
	-- first and the click silently fails. Five iterations is a
	-- generous safety bound; a normal NPC has at most a handful of
	-- unmapped parts between the camera and the body surface.
	local origin = unitRay.Origin
	local direction = unitRay.Direction
	local humourName = nil

	for _ = 1, 5 do
		local result = Workspace:Raycast(origin, direction * 1000, raycastParams)
		if not result or not result.Instance then
			return
		end

		local mapped = Humours.BodyRegions[result.Instance.Name]
		if mapped then
			humourName = mapped
			break
		end

		-- Start the next ray just past this surface to avoid
		-- re-hitting it. 0.05 studs is large enough to clear
		-- floating-point noise on the hit position, small enough
		-- to be invisible to gameplay.
		origin = result.Position + direction.Unit * 0.05
	end

	if not humourName then
		return
	end

	if revealedHumours[humourName] then
		-- First-click-only: the humour for this region has
		-- already been revealed for this examination. Stay
		-- visible, do nothing.
		return
	end

	local value = ExaminationState.GetHumour(humourName)
	if value == nil then
		-- Shouldn't happen — humours are set when the panel
		-- opens. Warn rather than silently no-op so a missing
		-- payload key is loud during development.
		warn("[BodyRegionClicks] No humour value for", humourName, "on current NPC")
		return
	end

	revealedHumours[humourName] = true
	setHumour:Fire(humourName, value)
end)
