--[[
	Author(s): Josh, Claude
	Module: LeaderstatsServer.luau
--]]

-- Services
local Players = game:GetService("Players")

-- Modules
local PlayerAddedUtil = shared("PlayerAddedUtil") ---@module PlayerAddedUtil
local PlayerDataServer = shared("PlayerDataServer") ---@module PlayerDataServer
local Timer = shared("Timer") ---@module Timer

-- Constants
local SYNC_INTERVAL = 0.5

local LeaderstatsServer = {}

-- Types
type StatValues = {
	Money: IntValue,
	Rebirths: IntValue,
}

-- Variables
local PlayerStats: { [Player]: StatValues } = {}

-- Private functions

function LeaderstatsServer:_createLeaderstats(player: Player)
	local replica = PlayerDataServer:GetReplica(player)
	if replica == nil or PlayerStats[player] then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local moneyValue = Instance.new("IntValue")
	moneyValue.Name = "Money"
	moneyValue.Value = replica.Data.Money
	moneyValue.Parent = leaderstats

	local rebirthsValue = Instance.new("IntValue")
	rebirthsValue.Name = "Rebirths"
	rebirthsValue.Value = replica.Data.Rebirths
	rebirthsValue.Parent = leaderstats

	leaderstats.Parent = player
	PlayerStats[player] = {
		Money = moneyValue,
		Rebirths = rebirthsValue,
	}
end

function LeaderstatsServer:_syncAll()
	for player, statValues in PlayerStats do
		local replica = PlayerDataServer:GetReplica(player)
		if replica == nil then
			continue
		end
		statValues.Money.Value = replica.Data.Money
		statValues.Rebirths.Value = replica.Data.Rebirths
	end
end

-- Start

function LeaderstatsServer:Run()
	PlayerDataServer.PlayerReady:Connect(function(player: Player)
		self:_createLeaderstats(player)
	end)
	for _, player in Players:GetPlayers() do
		self:_createLeaderstats(player)
	end
	PlayerAddedUtil:Connect({
		Removing = function(player: Player)
			PlayerStats[player] = nil
		end,
	})
	Timer.Simple(SYNC_INTERVAL, function()
		self:_syncAll()
	end)
end

return LeaderstatsServer
