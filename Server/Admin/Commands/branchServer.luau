--[[
	Author(s): Gory
	Module: branchServer.luau
--]]

local TeleportService = game:GetService("TeleportService")

local GetBranches ---@module GetBranches

return function(context, branch: GetBranches.Branch, players: { Player })
	context:Reply(`Teleporting to "{branch.DisplayName}" ...`)

	local result = TeleportService:TeleportAsync(branch.PlaceId, players) -- Yields.
	if result then
		return `Teleported {#players} players to "{branch.DisplayName}".`
	end
	return "Teleport failed."
end
