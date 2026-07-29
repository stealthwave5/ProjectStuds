--[[
	Author(s): Gory
	Module: KitStarter.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local KitModuleRef = require(script.Parent.KitModuleRef)
local KitModules = require(script.Parent.KitModules)
local KitTimer = require(script.Parent.KitTimer)

local KitStarter = {}

function KitStarter:StartClient()
	local jobsToStart: { KitModuleRef.KitModuleRef } = {}
	KitModules:IndexModules({
		AddJobsTo = jobsToStart,
		Containers = {
			ReplicatedStorage.Shared,
			ReplicatedStorage.Client,
		},
	})
	self:_startJobs("Client", jobsToStart)
	workspace:SetAttribute("KitClientStarted", os.clock())
end

function KitStarter:StartServer()
	local jobsToStart: { KitModuleRef.KitModuleRef } = {}
	KitModules:IndexModules({
		AddJobsTo = jobsToStart,
		Containers = {
			ReplicatedStorage.Shared,
			ServerScriptService.Server,
		},
	})
	self:_startJobs("Server", jobsToStart)
end

function KitStarter:StartStory()
	KitModules:IndexModules({
		Containers = {
			ReplicatedStorage.Shared,
			ReplicatedStorage.Client,
			ServerScriptService.Server,
		},
	})
end

local function SortByPriority(aRef: KitModuleRef.KitModuleRef, bRef: KitModuleRef.KitModuleRef)
	local aModule = aRef:GetModule()
	local bModule = bRef:GetModule()
	if not (aModule.Priority and bModule.Priority) then
		return bModule.Priority ~= nil
	end
	return aModule.Priority > bModule.Priority
end

function KitStarter:_startJobs(context: string, jobRefs: { KitModuleRef.KitModuleRef })
	KitTimer:ConnectJobStarting()

	local jobsWithStarts = {
		Strict = {}, -- Must run in 1 frame.
		Init = {}, -- Must run before next thing runs.
		Run = {}, -- Spawned.
	}
	for _, jobRef in jobRefs do
		local job = jobRef:GetModule()
		if type(job) ~= "table" then
			continue
		end
		for key, keyJobRefs in jobsWithStarts do
			if job[key] then
				table.insert(keyJobRefs, jobRef)
			end
		end
	end
	for key, keyJobRefs in jobsWithStarts do
		table.sort(keyJobRefs, SortByPriority)
	end

	local firstFrame = true
	RunService.PostSimulation:Once(function()
		firstFrame = false
	end)

	for _, jobRef in jobsWithStarts.Strict do
		KitTimer:Time(`{jobRef:GetName()}:Strict`, 0.01, function()
			jobRef:GetModule():Strict()
		end)
		if not firstFrame then
			error(`[{jobRef:GetName()}:Strict]: Can't yield.`)
		end
	end
	for _, jobRef in jobsWithStarts.Init do
		KitTimer:Time(`{jobRef:GetName()}:Init`, 0.01, function()
			jobRef:GetModule():Init()
		end)
	end
	for _, jobRef in jobsWithStarts.Run do
		task.spawn(function()
			jobRef:GetModule():Run()
		end)
	end

	local longTimers = KitTimer:DisconnectJobStarting()
	print(`{context} Kit Started.{longTimers}`)
end

return KitStarter
