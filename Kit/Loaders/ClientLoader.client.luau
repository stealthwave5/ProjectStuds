--[[
	Author(s): Gory
	Module: ClientLoader.client.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage:WaitForChild("Kit"))
Kit.Starter:StartClient()
