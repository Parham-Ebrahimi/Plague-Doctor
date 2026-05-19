local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local NPCData = require(Server.npc.NPCData)
local NPCVisuals = require(Server.npc.NPCVisuals)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InfectionStages = require(Shared.core.InfectionStages)
local GameConstants = require(Shared.core.GameConstants)

NPCData.OnStageChanged(function(npc, newStage)
	NPCVisuals.UpdateAppearance(npc, newStage)
end)

NPCData.RegisterAllTagged()

for npc in NPCData.GetAll() do
	NPCVisuals.UpdateAppearance(npc, NPCData.GetStage(npc))
end

local function tickHour()
	for npc, entry in NPCData.GetAll() do
		local stage = entry.stage
		if stage < InfectionStages.Exposed or stage > InfectionStages.Critical then
			continue
		end

		local increment = NPCData.IsBroadSpectrumActive(npc)
				and GameConstants.BROAD_SPECTRUM_MULTIPLIER
			or 1

		entry.stageTimer += increment

		local daysNeeded = GameConstants.STAGE_DURATIONS[stage]
		local hoursNeeded = daysNeeded * GameConstants.HOURS_PER_DAY

		if entry.stageTimer >= hoursNeeded then
			NPCData.SetStage(npc, stage + 1)
		end
	end
end

while true do
	task.wait(GameConstants.HOUR_IN_SECONDS)
	tickHour()
end
