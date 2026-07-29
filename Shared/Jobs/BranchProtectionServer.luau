--[[
	Author(s): Gory
	Module: BranchProtectionServer.luau
--]]

local Players = game:GetService("Players")

local GetBranches = shared("GetBranches") ---@module GetBranches
local Permissions = shared("Permissions") ---@module Permissions

local BranchProtectionServer = {}

local DEBUG_NO_ADMINS = false
local WHITELISTED_PLACES: { number? } = { 124520719057900 }

local ThisBranch: GetBranches.Branch

function BranchProtectionServer:_kickNonAdmin(player: Player)
	if not DEBUG_NO_ADMINS and Permissions:IsAdmin(player) then
		return
	end
	player:Kick(`{ThisBranch.DisplayName} is a protected branch.`)
end

function BranchProtectionServer:_lockdown()
	Players.PlayerAdded:Connect(function(player)
		self:_kickNonAdmin(player)
	end)
	for index, player in Players:GetPlayers() do
		self:_kickNonAdmin(player)
	end
end

function BranchProtectionServer:Run()
	local placeId = game.PlaceId
	for index, branch in GetBranches() do
		if branch.PlaceId == placeId then
			ThisBranch = branch
			break
		end
	end
	if WHITELISTED_PLACES and table.find(WHITELISTED_PLACES, placeId) then
		return
	end
	self:_lockdown()
end

return BranchProtectionServer
