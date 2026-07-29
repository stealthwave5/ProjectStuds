--[[
	Author(s): Josh, Claude
	Module: Components.storybook.luau
]]

local Storybook = {
	name = string.gsub(script.Name, ".storybook", ""),
	storyRoots = { script.Parent },
	groupRoots = false,
}

return Storybook
