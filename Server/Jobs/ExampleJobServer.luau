--[[
	Author(s): Gory
	Module: ExampleJobServer.luau
--]]

local GetRemote = shared("GetRemote") ---@module GetRemote
local Timer = shared("Timer") ---@module Timer

local ExampleJobServer = {}

local ExampleRemote = GetRemote("Example")

function ExampleJobServer:Run()
	Timer.Simple(2, function()
		ExampleRemote:FireAllClients("Hi!")
	end)
end

return ExampleJobServer
