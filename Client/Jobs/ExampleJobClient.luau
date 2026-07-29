--[[
	Author(s): Gory
	Module: ExampleJobClient.luau
--]]

local Assets = shared("Assets") ---@module Assets
local DataClient = shared("DataClient") ---@module DataClient
local GetRemote = shared("GetRemote") ---@module GetRemote

local ExampleJobClient = {}

local ExampleRemote = GetRemote("Example")

function ExampleJobClient:Init() end

function ExampleJobClient:Run() end

return ExampleJobClient
