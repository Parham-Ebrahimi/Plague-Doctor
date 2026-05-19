local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENT_NAMES = {
	"RequestExamination",
	"ExaminationApproved",
	"CloseExamination",
	"AttemptTreatment",
	"TreatmentResult",
	"AttemptQuarantine",
	"AttemptUnquarantine",
	"QuarantineResult",
	"RequestJournalSection",
	"JournalSectionResponse",
	"OpenCraftingUI",
	"TestMixture",
	"TestMixtureResult",
	"AttemptCraft",
	"AttemptCraftResult",
	"OpenChestUI",
	"MoveChestItem",
	"ChestTransferResult",
}

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RemoteEvents"
		folder.Parent = ReplicatedStorage
	end
else
	folder = ReplicatedStorage:WaitForChild("RemoteEvents")
end

local RemoteEvents = {}

for _, name in EVENT_NAMES do
	if RunService:IsServer() then
		local existing = folder:FindFirstChild(name)
		if not existing then
			existing = Instance.new("RemoteEvent")
			existing.Name = name
			existing.Parent = folder
		end
		RemoteEvents[name] = existing
	else
		RemoteEvents[name] = folder:WaitForChild(name)
	end
end

return RemoteEvents
