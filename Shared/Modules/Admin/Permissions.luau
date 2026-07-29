--[[
	Author(s): Gory
	Module: Permissions.luau
--]]

local Players = game:GetService("Players")

local Retry = shared("Retry") ---@module Retry

local Permissions = {}

local ADMIN_GROUPS = {
	{
		Name = "Throw Stuff At A Wall",
		GroupId = 255304134,
		Rank = 100,
	},
}

local Cached = {}

function Permissions:LocalPlayerIsAdmin(): boolean
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		return self:IsAdmin(localPlayer)
	end
end

function Permissions:IsAdmin(player: Player): boolean
	-- local server testing
	if player.UserId < 0 then
		return true
	end

	local admin = Cached[player]
	if admin ~= nil then
		return admin
	end

	admin = false

	for index, group in ADMIN_GROUPS do
		local success, playerRank = Retry({
			Delay = 0,
			Limit = 2,
		}, function()
			return player:GetRankInGroup(group.GroupId)
		end)

		if success and playerRank >= group.Rank then
			admin = true
			break
		end
	end

	Cached[player] = admin
	player.AncestryChanged:Once(function()
		Cached[player] = nil
	end)

	return admin
end

return Permissions
