--[[
	Author(s): Gory
	Module: KitModules.luau
--]]

local RunService = game:GetService("RunService")

local KitModuleRef = require(script.Parent.KitModuleRef) ---@module KitModuleRef
local KitTimer = require(script.Parent.KitTimer) ---@module KitTimer

local KitModules = {}

type TreeNode = {
	[string]: KitModuleRef.KitModuleRef,
} | KitModuleRef.KitModuleRef
type IndexRules = {
	DoLoad: boolean?,
	DoJobs: boolean?,
	DoNested: boolean?,
}

local PATH_DELIMITER = "/"
local SUB_CONTAINER_RULES: { [string]: IndexRules } = {
	Jobs = {
		DoJobs = true,
		DoLoad = true,
		DoNested = true,
	},
	Modules = {
		DoLoad = true,
		DoNested = true,
	},
	Vendor = {
		DoLoad = true,
		DoNested = false,
	},
	Default = {
		DoLoad = true,
		DoNested = true,
	},
	Admin = {
		DoLoad = false,
	},
}

local DestroyStories = RunService:IsRunning()
local InverseTree: { [string]: TreeNode } = {}
local CallStack: { string } = {}

--[[
	Shared Require Pattern:
	Escape requiring by path by using shared("ModuleName").
]]

function KitModules.__call(
	_,
	query: string | { string },
	options: {
		Defer: boolean?,
	}
)
	local moduleRef: KitModuleRef.KitModuleRef
	if type(query) == "string" then
		moduleRef = KitModules:_getPlain(query)
	else
		moduleRef = KitModules:_getPath(query)
	end
	if moduleRef:HasRequired() then
		return moduleRef:GetModule()
	end
	--	Defer: return a table with __index and __newindex set to the module.
	if options and options.Defer then
		return moduleRef:GetDeferredRef()
	end
	if moduleRef:IsRequiring() then
		error(`Cyclic detected: {moduleRef:GetName()}`)
	end

	if moduleRef:IsRequiring() then
		--	This module is already on the call stack.
		--	Find the index on the call stack and throw error.

		--[[
			Example:
			A -> B -> C -> D -> shared("C")
					  ^		 	^
					  |		 	|
					  |		 	|
		]]

		for index = #CallStack, 1, -1 do
			if CallStack[index] ~= moduleRef then
				continue
			end

			--	Create call stack string.
			local callStackNames = {}
			for cyclicIndex = index, #CallStack do
				table.insert(callStackNames, CallStack[cyclicIndex]:GetName())
			end
			local tracebackString = debug.traceback()
			local callStackString = table.concat(callStackNames, " ->\n")
			local errorMessage = "Cylic detected:"
				.. `\n\n{callStackString} ->\n{moduleRef:GetName()}\n`
				.. `\n\n{tracebackString}`

			--	Ugly many line error avoided by yielding and spawning the error separate.
			task.spawn(error, errorMessage, 2)
			KitTimer.disconnectFeatureStarting()
			task.wait(10_000)
		end
	end

	local index = #CallStack + 1
	CallStack[index] = moduleRef
	local module = moduleRef:GetModule()

	--	Due to the serial nature of calls, the index WILL be the same.
	CallStack[index] = nil

	return module
end

setmetatable(shared, KitModules)
setmetatable(KitModules, KitModules)

--[[
	Public Methods
]]

function KitModules:AddModule(name: string, module: any)
	local moduleRef = KitModuleRef.fromLoaded(module)
	InverseTree[name] = moduleRef
	return moduleRef
end

function KitModules:IndexModules(options: {
	AddJobsTo: { KitModuleRef.KitModuleRef }?,
	Containers: { Instance },
})
	for _, container in options.Containers do
		for _, subContainer in container:GetChildren() do
			local rules = SUB_CONTAINER_RULES[subContainer.Name] or SUB_CONTAINER_RULES.Default
			if not rules.DoLoad then
				continue
			end
			self:_indexModulesIn(subContainer, {
				AddJobsTo = options.AddJobsTo,
				DoJobs = rules.DoJobs and options.AddJobsTo ~= nil,
				DoNested = rules.DoNested,
			})
		end
	end
end

--[[
	Private Methods
]]

function KitModules:_getPlain(moduleName: string)
	local moduleRef: TreeNode = InverseTree[moduleName]
	if moduleRef == nil then
		error(`No module "{moduleName}".`, 3)
	end
	if KitModuleRef.is(moduleRef) then
		return moduleRef
	end
	local possibles = self:_flatReverseTree(moduleRef)
	print("Possibles:", possibles)
	error("Insufficient Accuracy." .. `\n{moduleName}` .. `\n.. {table.concat(possibles, "\n.. ")}`)
end

function KitModules:_getPath(path: { string })
	local moduleRef
	local lastNode: TreeNode = InverseTree
	local nextNode: TreeNode
	for index = #path, 1, -1 do
		local pathPart = path[index]
		nextNode = lastNode[pathPart]
		if not nextNode then
			error("Not found.")
		end
		if KitModuleRef.is(nextNode) then
			moduleRef = nextNode
			break
		end
		lastNode = nextNode
	end
	if moduleRef == nil then
		local possibles = self:_flatReverseTree(lastNode)
		error(
			"Insufficient Accuracy."
				.. `\n{table.concat(path, PATH_DELIMITER)}`
				.. `\n.. {table.concat(possibles, "\n.. ")}`
		)
	end

	return moduleRef
end

function KitModules:_indexModulesIn(
	instance: Instance,
	options: {
		AddJobsTo: {},
		DoJobs: boolean?,
		DoNested: boolean?,
	}
)
	for _, child in instance:GetChildren() do
		if child.ClassName == "ModuleScript" then
			if string.find(child.Name, ".", nil, true) then
				if DestroyStories then
					child:Destroy()
				end
				continue -- Don't load stories.
			end
			local moduleRef = self:_createRef(child)
			if options.DoJobs then
				table.insert(options.AddJobsTo, moduleRef)
			end
			if not options.DoNested then
				continue
			end
		end
		self:_indexModulesIn(child, options)
	end
end

function KitModules:_createRef(moduleScript: ModuleScript)
	local instance: Instance = moduleScript
	local lastNode: TreeNode = InverseTree
	local nextNode: TreeNode
	while true do
		nextNode = lastNode[instance.Name]
		if nextNode == nil then
			break
		end
		if KitModuleRef.is(nextNode) then
			--	Split the tree here.
			lastNode[instance.Name] = {
				[nextNode:GetParent().Name] = nextNode,
			}
			continue --	Retry.
		end
		lastNode = nextNode
		instance = instance.Parent
	end

	local moduleRef = KitModuleRef.new(moduleScript)
	lastNode[instance.Name] = moduleRef
	return moduleRef
end

function KitModules:_getPathStrings(node: TreeNode)
	return self:_flatReverseTree(node)
end

function KitModules:_flatReverseTree(node, result, path)
	result = result or {}
	path = path or {}

	for key, value in node do
		if KitModuleRef.is(value) then
			local fullKey = key
			for _, p in path do
				fullKey = fullKey .. PATH_DELIMITER .. p
			end
			result[fullKey] = value
		else
			table.insert(path, 1, key)
			self:_flatReverseTree(value, result, path)
			table.remove(path, 1)
		end
	end

	return result
end

return KitModules
