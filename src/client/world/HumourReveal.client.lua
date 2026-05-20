-- HumourReveal — legacy click-to-reveal-humour subscriber.
--
-- Subscribes to BodyRegionClicks.ClickedRegion and maps the
-- clicked region to its associated humour, then dispatches
-- to TreatmentPanelUI.SetHumour to update the panel display.
-- Owns per-NPC dedupe (revealedHumours, humour-keyed) so
-- the same region click after the first is a no-op for this
-- subscriber.
--
-- This is the legacy click-to-reveal-humour-value mechanic.
-- It will be deleted when the symptom-discovery system
-- replaces direct humour reveal. At that point: delete this
-- file, delete Humours.BodyRegions in src/shared/core/Humours.lua,
-- delete the key-set assertion in the same file, and delete
-- the SetHumour BindableEvent + handler in TreatmentPanelUI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Humours = require(Shared.core.Humours)

local localPlayer = Players.LocalPlayer
local clientFolder = localPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")

local examinationStateScript = clientFolder:WaitForChild("world"):WaitForChild("ExaminationState")
local ExaminationState = require(examinationStateScript)
local currentNPCChanged = examinationStateScript:WaitForChild("CurrentNPCChanged")

local treatmentPanelScript = clientFolder:WaitForChild("ui"):WaitForChild("TreatmentPanelUI")
local setHumour = treatmentPanelScript:WaitForChild("SetHumour", 10)
if not setHumour then
	warn("[HumourReveal] SetHumour BindableEvent missing; cannot reveal humour values.")
	return
end

local bodyRegionClicksScript = clientFolder:WaitForChild("world"):WaitForChild("BodyRegionClicks")
local clickedRegion = bodyRegionClicksScript:WaitForChild("ClickedRegion", 10)
if not clickedRegion then
	warn("[HumourReveal] ClickedRegion BindableEvent missing; legacy reveal disabled.")
	return
end

-- Region → humour mapping. Only the four click-discoverable
-- regions; passive isn't reachable via raycast (passive
-- symptoms are surfaced separately by the symptom-discovery
-- subscriber once it exists).
local regionToHumour = {
	[Humours.Regions.Head]  = Humours.BlackBile,
	[Humours.Regions.Chest] = Humours.Blood,
	[Humours.Regions.Arms]  = Humours.YellowBile,
	[Humours.Regions.Legs]  = Humours.Phlegm,
}

-- Tracks which humours have already been revealed for the
-- currently-examined NPC. Keyed by humour display-name. Reset
-- on every CurrentNPCChanged transition so re-examining the
-- same NPC after Leave starts fresh.
local revealedHumours = {}

currentNPCChanged.Event:Connect(function()
	revealedHumours = {}
end)

clickedRegion.Event:Connect(function(regionName)
	local humourName = regionToHumour[regionName]
	if not humourName then
		return
	end

	if revealedHumours[humourName] then
		-- First-click-only per humour. Subsequent clicks on
		-- any part of the same region during this examination
		-- are no-ops.
		return
	end

	local value = ExaminationState.GetHumour(humourName)
	if value == nil then
		warn("[HumourReveal] No humour value for", humourName, "on current NPC")
		return
	end

	revealedHumours[humourName] = true
	setHumour:Fire(humourName, value)
end)
