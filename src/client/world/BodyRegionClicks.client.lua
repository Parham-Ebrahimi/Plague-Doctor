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

local camera = Workspace.CurrentCamera

-- Fan-out event for region clicks during examination. Fires
-- with a region string (one of Humours.Regions.* values:
-- "head", "chest", "arms", or "legs") on every successful
-- raycast that resolves to a mapped R15 part. Does NOT
-- dedupe — subscribers handle their own dedupe at whatever
-- granularity makes sense (e.g. HumourReveal dedupes by
-- humour; the future symptom-discovery subscriber will
-- dedupe by symptom key). Carries only the region string;
-- subscribers consult ExaminationState directly for any
-- per-NPC state they need.
local clickedRegion = Instance.new("BindableEvent")
clickedRegion.Name = "ClickedRegion"
clickedRegion.Parent = script

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
	local regionName = nil

	for _ = 1, 5 do
		local result = Workspace:Raycast(origin, direction * 1000, raycastParams)
		if not result or not result.Instance then
			return
		end
		local mapped = Humours.RegionByPart[result.Instance.Name]
		if mapped then
			regionName = mapped
			break
		end

		-- Start the next ray just past this surface to avoid
		-- re-hitting it. 0.05 studs is large enough to clear
		-- floating-point noise on the hit position, small enough
		-- to be invisible to gameplay.
		origin = result.Position + direction.Unit * 0.5
	end

	if not regionName then
		return
	end

	clickedRegion:Fire(regionName)
end)
