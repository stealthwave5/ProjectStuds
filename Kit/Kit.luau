--[[
	Author(s): Gory
	Module: Kit.luau
--]]

local RunService = game:GetService("RunService")

local Modules = script:WaitForChild("Modules")
local KitModuleRef = require(Modules.KitModuleRef)
local KitModules = require(Modules.KitModules)
local KitStarter = require(Modules.KitStarter)
local KitTimer = require(Modules.KitTimer)

KitModules:AddModule("KitModuleRef", KitModuleRef)
KitModules:AddModule("KitModules", KitModules)
KitModules:AddModule("KitStarter", KitStarter)
KitModules:AddModule("KitTimer", KitTimer)

local Kit = {
	ModuleRef = KitModuleRef,
	Modules = KitModules,
	Starter = KitStarter,
	Timer = KitTimer,
}

if not RunService:IsRunning() then
	Kit.Starter:StartStory()
end

return Kit
