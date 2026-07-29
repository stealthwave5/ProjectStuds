--[[
	Author(s): Gory
	Module: PlayerAddedUtil.luau
--]]

local Players = game:GetService("Players")

local Maid = shared("Maid") ---@module Maid

local PlayerAddedUtil = {}

local KEYS = { "Added", "Removing" }

function PlayerAddedUtil:Connect(options: {
	Added: (player: Player) -> (),
	Removing: (player: Player) -> (),
}): Maid.Maid
	local maid = Maid.new()
	if options.Added then
		maid:Add(Players.PlayerAdded:Connect(options.Added))
		for index, player in Players:GetPlayers() do
			task.spawn(options.Added, player)
		end
	end
	if options.Removing then
		maid:Add(Players.PlayerRemoving:Connect(options.Removing))
	end
	for key in options do
		if not table.find(KEYS, key) then
			error(`[PlayerAddedUtil]: No option "{key}".`)
		end
	end
	return maid
end

return PlayerAddedUtil
