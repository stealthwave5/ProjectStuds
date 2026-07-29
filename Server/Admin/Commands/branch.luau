--[[
	Author(s): Gory
	Module: branch.luau
--]]

return {
	Name = "branch",
	Aliases = {},
	Group = "Admin",
	Description = "Teleport to a specific development branch.",
	Args = {
		{
			Type = "branch",
			Name = "branch",
			Description = "The branch to teleport to.",
		},
		{
			Type = "players",
			Name = "players",
			Description = "Players who will be teleported to the branch.",
		},
	},
}
