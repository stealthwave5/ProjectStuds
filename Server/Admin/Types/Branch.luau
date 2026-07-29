--[[
	Author(s): Gory
	Module: Branch.luau
--]]

local GetBranches = shared("GetBranches") ---@module GetBranches
local Util ---@module Cmdr/Shared/Util

local BranchType = {
	Transform = function(text)
		local branches = GetBranches()
		local findBranch = Util.MakeFuzzyFinder(branches)
		return findBranch(text)
	end,

	Validate = function(branches)
		return #branches > 0, "No branch with that name."
	end,

	Autocomplete = function(branches)
		return Util.GetNames(branches)
	end,

	Parse = function(branches)
		return branches[1]
	end,
}

return function(registry)
	Util = registry.Cmdr.Util
	registry:RegisterType("branch", BranchType)
end
