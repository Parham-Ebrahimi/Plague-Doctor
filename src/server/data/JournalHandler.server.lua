local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local JournalData = require(Server.data.JournalData)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteEvents = require(Shared.core.RemoteEvents)

RemoteEvents.RequestJournalSection.OnServerEvent:Connect(function(player, section)
	if type(section) ~= "string" then
		return
	end

	if not JournalData.IsValidSection(section) then
		RemoteEvents.JournalSectionResponse:FireClient(player, section, {})
		return
	end

	local entries = JournalData.GetSection(player, section)
	RemoteEvents.JournalSectionResponse:FireClient(player, section, entries)
end)
