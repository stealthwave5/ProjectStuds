--[[
	Author(s): Gory
	Module: Assets.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local CREATE_FOLDER_IF_NIL = true
local FOLDER_LOCATION = ReplicatedStorage
local FOLDER_NAME = "Assets"
local PATH_DELIMITER = "."
local SERVER_FOLDER_LOCATION: Instance? = ServerStorage
local SERVER_FOLDER_NAME: string? = "Assets"
local WARN_REPEAT_NAMES = true

local Maid = shared("Maid") ---@module Maid

local Assets = {}
Assets.Priority = 1_000

local AssetsFolder: Folder
local Registry: { [string]: Instance } = {}
local Running = RunService:IsRunning()
local Server = RunService:IsServer()

--[[
	Public Methods
]]

---Clones an asset by name, from registry.
---
---**Params:**
---@param name string Asset name.
---**Returns:**
---@return Instance asset The cloned asset instance.
function Assets:Clone(name: string): Instance
	local template = self:Get(name)
	return template:Clone()
end

---Gets an asset by name, from registry.
---
---**Params:**
---@param name string Asset name.
---**Returns:**
---@return Instance asset The asset instance.
function Assets:Get(name: string): Instance
	local asset = Registry[name]
	if asset == nil then
		error(`[Resources]: No {name} in registry.`)
	end
	return asset
end

---Attempts to clone an asset through a full path.
---
---Best used when you have multiple assets that share the same name.
---
---**Params:**
---@param query string|{string} The full path to the asset. Automatically starts with the Assets folder.
---**Returns:**
---@return Instance|nil result The resulting asset instance.
--[[**Example:**
```lua
local asset = Resources:GetPath("Folder.To.MyAsset", false)
```]]
function Assets:ClonePath(query: { string } | string): Instance
	local template = self:GetPath(query)
	return template:Clone()
end

---Attempts to get an asset through a full path.
---
---Best used when you have multiple assets that share the same name.
---
---**Params:**
---@param query string|{string} The full path to the asset. Automatically starts with the Assets folder.
---**Returns:**
---@return Instance|nil result The resulting asset instance.
--[[**Example:**
```lua
local asset = Resources:GetPath("Folder.To.MyAsset", false)
```]]
function Assets:GetPath(query: { string } | string): Instance
	local path = self:_queryToPath(query)

	local instance = AssetsFolder
	for index, pathPart in path do
		instance = instance:FindFirstChild(pathPart)
		if instance == nil then
			local pathProblem = table.concat(path, PATH_DELIMITER, 1, index)
			error(`[Resources:GetPath]: Path does not exist, "{pathProblem}".`)
		end
	end

	return instance
end

function Assets:Fetch()
	error("[Resources:Fetch]: Not implemented.")
end

function Assets:FetchPath()
	error("[Resources:FetchPath]: Not implemented.")
end

--[[
	Private Methods: Pathing
]]

---Converts query into an array of strings.
function Assets:_queryToPath(query: { string } | string): { string }
	if type(query) == "table" then
		assert(
			type(query[1]) == "string",
			`[Resources:_queryToPath]: Invalid path array, expected string got {typeof(query[1])}.`
		)
		return query
	elseif type(query) == "string" then
		return string.split(query, PATH_DELIMITER)
	end
	error(`[Resources:_queryToPath]: Invalid query, expected string got {typeof(query)}.`)
end

--[[
	Private Methods: Registry
]]

function Assets:_addToRegistry(child: Instance)
	local childName = child.Name
	if WARN_REPEAT_NAMES and Registry[childName] then
		warn(`[Resources]: Duplicate {childName} in registry.`)
	end
	Registry[childName] = child
end

function Assets:_removeFromRegistry(child: Instance)
	local childName = child.Name
	if Registry[childName] == child then
		Registry[childName] = nil
	end
end

function Assets:_registerChildAdded(child: Instance, maid: Maid.Maid)
	if child:IsA("Folder") then
		local extendedMaid = Maid.new()
		maid[child] = extendedMaid

		self:_registerFolder(child, extendedMaid)
	else
		self:_addToRegistry(child)
	end
end

function Assets:_registerChildRemoved(child: Instance, maid: Maid.Maid)
	if child:IsA("Folder") then
		maid[child] = nil
	else
		self:_removeFromRegistry(child)
	end
end

function Assets:_registerFolder(folder: Folder, maid: Maid.Maid)
	if Running then
		maid:Add(folder.ChildAdded:Connect(function(child)
			self:_registerChildAdded(child, maid)
		end))
		maid:Add(folder.ChildRemoved:Connect(function(child)
			self:_registerChildRemoved(child, maid)
		end))
	end
	for index, child in folder:GetChildren() do
		self:_registerChildAdded(child, maid)
	end
	maid:Add(function()
		for index, child in folder:GetChildren() do
			self:_registerChildRemoved(child, maid)
		end
	end)
end

function Assets:_registerContainer(container: Folder)
	self:_registerFolder(container, Maid.new())
end

--[[
	Setup
]]

function Assets:_setupFolders()
	--	Find or create.
	AssetsFolder = FOLDER_LOCATION:FindFirstChild(FOLDER_NAME)
	if AssetsFolder == nil and Running and Server and CREATE_FOLDER_IF_NIL then
		AssetsFolder = Instance.new("Folder")
		AssetsFolder.Archivable = false
		AssetsFolder.Name = FOLDER_NAME
		AssetsFolder.Parent = FOLDER_LOCATION
	end
	assert(AssetsFolder, "[Resources]: No assets folder.")
end

function Assets:_setupRegistry()
	self:_registerContainer(AssetsFolder)
	if Running and Server and SERVER_FOLDER_NAME and SERVER_FOLDER_LOCATION then
		local serverAssetsFolder = SERVER_FOLDER_LOCATION:FindFirstChild(SERVER_FOLDER_NAME)
		assert(
			serverAssetsFolder,
			`[Resources:Init] No server assets {SERVER_FOLDER_LOCATION.Name}.{SERVER_FOLDER_NAME}.`
		)
		self:_registerContainer(serverAssetsFolder)
	end
end

function Assets:Init()
	self:_setupFolders()
	self:_setupRegistry()
end

if not Running then
	Assets:Init()
end

return Assets
