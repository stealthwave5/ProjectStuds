--[[
	Author(s): Josh, Claude
	Module: RebirthServer.luau
--]]

-- Modules
local BackpackServer = shared("BackpackServer") ---@module BackpackServer
local GameConfig = shared("GameConfig") ---@module GameConfig
local GetRemote = shared("GetRemote") ---@module GetRemote
local PlayerDataServer = shared("PlayerDataServer") ---@module PlayerDataServer
local UpgradesServer = shared("UpgradesServer") ---@module UpgradesServer

local RebirthServer = {}

-- Variables
local RebirthRemote = GetRemote("RebirthServer:Rebirth")
local RebirthResultRemote = GetRemote("RebirthServer:RebirthResult")

-- Private functions

function RebirthServer:_sendResult(player: Player, ok: boolean, msg: string)
	RebirthResultRemote:FireClient(player, { ok = ok, msg = msg })
end

function RebirthServer:_onRebirth(player: Player)
	local replica = PlayerDataServer:GetReplica(player)
	if replica == nil then
		return
	end

	local rebirths = replica.Data.Rebirths
	local cost = GameConfig.getRebirthCost(rebirths)
	if replica.Data.Money < cost then
		self:_sendResult(player, false, `Need ${cost} to rebirth!`)
		return
	end

	replica:SetValue({ "Money" }, 0)
	replica:SetValue({ "Upgrades" }, {
		Speed = 0,
		Value = 0,
		Capacity = 0,
	})
	BackpackServer:Clear(player)
	local newRebirths = rebirths + 1
	replica:SetValue({ "Rebirths" }, newRebirths)
	UpgradesServer:ApplyWalkSpeed(player)

	self:_sendResult(player, true, `Rebirth {newRebirths}! Coin value x{newRebirths + 1}`)
end

-- Start

function RebirthServer:Init()
	RebirthRemote:OnServerEvent(function(player: Player)
		self:_onRebirth(player)
	end)
end

return RebirthServer
