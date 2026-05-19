local NPCData = {}

local npcStages = {}

local MIN_STAGE = 1
local MAX_STAGE = 5

function NPCData.GetStage(npcId)
	return npcStages[npcId]
end

function NPCData.SetStage(npcId, stage)
	if type(npcId) ~= "string" or npcId == "" then
		return false, "npcId must be a non-empty string"
	end

	if type(stage) ~= "number" or stage % 1 ~= 0 then
		return false, "stage must be an integer"
	end

	if stage < MIN_STAGE or stage > MAX_STAGE then
		return false, "stage must be between 1 and 5"
	end

	npcStages[npcId] = stage
	return true
end

function NPCData.GetAllNPCs()
	local copy = {}
	for npcId, stage in pairs(npcStages) do
		copy[npcId] = stage
	end

	return copy
end

return NPCData