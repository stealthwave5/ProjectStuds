--[[
	Author(s): Gory
	Module: CmdrStarterServer.luau
--]]

local ServerScriptService = game:GetService("ServerScriptService")

local Cmdr = shared("Cmdr") ---@module Cmdr/Shared/Registry

local CmdrStarterServer = {}

function CmdrStarterServer:_registerContainer(container: Folder)
	local commandsFolder = container:FindFirstChild("Commands")
	if commandsFolder then
		Cmdr:RegisterCommandsIn(commandsFolder)
	end
	local hooksFolder = container:FindFirstChild("Hooks")
	if hooksFolder then
		Cmdr:RegisterHooksIn(hooksFolder)
	end
	local typesFolder = container:FindFirstChild("Types")
	if typesFolder then
		Cmdr:RegisterTypesIn(typesFolder)
	end
end

function CmdrStarterServer:Run()
	Cmdr:RegisterDefaultCommands(function(command)
		return true
	end)
	self:_registerContainer(ServerScriptService.Server.Admin)
end

return CmdrStarterServer
