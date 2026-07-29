--[[
	Author(s): Codesense, ChiefWildin, Gory
	Module: BeforeRun.luau
	Version: 1.1.0

	Determines who is allowed to run commands with cmdr.
--]]

local Permissions = shared("Permissions") ---@module Permissions

return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		local hasPermission = Permissions:IsAdmin(context.Executor)

		if not hasPermission then
			return "You don't have permission to run this command"
		end

		return nil -- Pass.
	end)
end
