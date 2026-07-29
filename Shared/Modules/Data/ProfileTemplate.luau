--[[
	Author(s): Gory, Josh, Claude
	Module: ProfileTemplate.luau
--]]

local ProfileTemplate = {
	Money = 0,
	Rebirths = 0,
	Upgrades = {
		Speed = 0,
		Value = 0,
		Capacity = 0,
	},
	Carried = 0, -- Backpack units currently held.
	CarriedValue = 0, -- Accumulated base $ of held studs.
	CarriedItems = {} :: { { Type: string, Mutation: string? } },
}

return ProfileTemplate
