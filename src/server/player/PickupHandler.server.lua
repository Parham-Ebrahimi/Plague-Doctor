local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local SatchelData = require(Server.player.SatchelData)

local PICKUP_NAME = "Cloth"
local PICKUP_DISTANCE = 8

local function setupClothPickup(instance)
	if not instance:IsA("BasePart") or instance.Name ~= PICKUP_NAME then
		return
	end

	if instance:GetAttribute("PickupReady") then
		return
	end
	instance:SetAttribute("PickupReady", true)

	local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Parent = instance
	end

	prompt.ActionText = "Pick up"
	prompt.ObjectText = "Cloth"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = PICKUP_DISTANCE
	prompt.RequiresLineOfSight = true
	prompt.HoldDuration = 0

	prompt.Triggered:Connect(function(player)
		if instance:GetAttribute("Collected") then
			return
		end

		local added = SatchelData.AddItem(player, "Cloth", 1)
		if not added then
			return
		end

		instance:SetAttribute("Collected", true)
		instance:Destroy()
	end)
end

for _, descendant in Workspace:GetDescendants() do
	setupClothPickup(descendant)
end

Workspace.DescendantAdded:Connect(setupClothPickup)
