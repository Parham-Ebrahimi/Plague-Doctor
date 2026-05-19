local ExaminationState = {}

-- Client-side store for the currently-examined NPC and its
-- humour values. Populated by TreatmentPanelUI on
-- examination open, cleared on close, read by the
-- body-region click detection script during examination.
--
-- Humour map keys are display-name strings ("Blood",
-- "Phlegm", "Yellow Bile", "Black Bile") matching
-- Humours.Names and the panel's humourValueLabels.
--
-- The asymmetry between this module (returns shallow copies
-- on read) and the server's NPCData (returns the live entry
-- table) is intentional: the server-to-client boundary
-- serialises by value, but in-process readers on the same
-- side could mutate a shared table by accident if the
-- module handed out its internal reference.
--
-- CurrentNPCChanged (BindableEvent, child of this script) fires on each currentNPC transition, carrying the new NPC (or nil).

local currentNPC = nil
local currentHumours = nil

local currentNPCChanged = Instance.new("BindableEvent")
currentNPCChanged.Name = "CurrentNPCChanged"
currentNPCChanged.Parent = script

function ExaminationState.SetCurrentNPC(npc, humourValues)
	currentNPC = npc
	currentHumours = humourValues
	currentNPCChanged:Fire(currentNPC)
end

function ExaminationState.ClearCurrentNPC()
	currentNPC = nil
	currentHumours = nil
	currentNPCChanged:Fire(nil)
end

function ExaminationState.GetCurrentNPC()
	return currentNPC
end

function ExaminationState.GetHumour(humourName)
	if not currentHumours then
		return nil
	end
	return currentHumours[humourName]
end

function ExaminationState.GetAllHumours()
	if not currentHumours then
		return nil
	end
	local copy = {}
	for name, value in currentHumours do
		copy[name] = value
	end
	return copy
end

return ExaminationState
