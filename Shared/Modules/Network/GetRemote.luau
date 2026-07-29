--[[
	Author(s): Gory
	Module: GetRemote.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CONTAINER = ReplicatedStorage
local FOLDER_NAME = "Remotes"

local AllRemotes: { [string]: {} } = {}
local RequestFunction: RemoteFunction
local RemotesFolder: Folder

local Remote = {}
Remote.__index = Remote
Remote.ClassName = Remote

export type Remote = {
	OnClientEvent: (self: Remote, callback: (...any) -> ()) -> RBXScriptConnection,
	OnServerEvent: (self: Remote, callback: (player: Player, ...any) -> ()) -> RBXScriptConnection,
	FireClient: (self: Remote, player: Player, ...any) -> (),
	FireClientList: (self: Remote, players: { Player }, ...any) -> (),
	FireAllClients: (self: Remote, ...any) -> (),
	FireAllExcept: (self: Remote, except: Player, ...any) -> (),
	FireServer: (self: Remote, ...any) -> (),
}

function Remote.new(name: string): Remote
	local self = setmetatable({}, Remote)

	self._name = name
	self._remoteEvent = nil :: RemoteEvent

	AllRemotes[name] = self

	return self
end

function Remote:OnClientEvent(callback): RBXScriptConnection
	return self:_getEventClient().OnClientEvent:Connect(callback)
end

function Remote:OnServerEvent(callback): RBXScriptConnection
	return self:_getEventServer().OnServerEvent:Connect(callback)
end

function Remote:FireAllClients(...: any...)
	self:_getEventServer():FireAllClients(...)
end

function Remote:FireAllExcept(except: Player, ...: any...)
	local event = self:_getEventServer()
	for index, player in Players:GetPlayers() do
		if player ~= except then
			event:FireClient(player, ...)
		end
	end
end

function Remote:FireClient(player: Player, ...: any...)
	self:_getEventServer():FireClient(player, ...)
end

function Remote:FireClientList(players: { Player }, ...: any...)
	local event = self:_getEventServer()
	for index, player in players do
		event:FireClient(player, ...)
	end
end

function Remote:FireServer(...: any...)
	self:_getEventClient():FireServer(...)
end

function Remote:_getEventClient(): RemoteEvent
	if self._remoteEvent then
		return self._remoteEvent
	end

	self._remoteEvent = RemotesFolder:FindFirstChild(self._name)
	if self._remoteEvent then
		return self._remoteEvent
	end

	self._remoteEvent = RequestFunction:InvokeServer(self._name)
	if self._remoteEvent then
		return self._remoteEvent
	end

	error(`[GetRemote]: Is {self._name} created on the server?`)
end

function Remote:_getEventServer()
	if self._remoteEvent then
		return self._remoteEvent
	end

	self._remoteEvent = Instance.new("RemoteEvent")
	self._remoteEvent.Name = self._name
	self._remoteEvent.Parent = RemotesFolder
	return self._remoteEvent
end

--[[
	Return function according to context.
]]

if not RunService:IsRunning() then
	--[[
		Mock
	]]
	return function(name: string): Remote
		return Remote.new(name)
	end
elseif RunService:IsServer() then
	--[[
		Server Creates Instances
	]]
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Archivable = false
	RemotesFolder.Name = FOLDER_NAME
	RemotesFolder.Parent = CONTAINER

	RequestFunction = Instance.new("RemoteFunction")
	RequestFunction.Name = "Request"
	RequestFunction.Parent = RemotesFolder

	function RequestFunction.OnServerInvoke(player: Player, name: string)
		local remote = AllRemotes[name]
		if remote then
			return remote:_getEventServer()
		end
	end

	return function(name: string): Remote
		local remote = AllRemotes[name]
		if remote == nil then
			remote = Remote.new(name)
		end
		return remote
	end
elseif RunService:IsClient() then
	--[[
		Client Waits for Instances
	]]
	return function(name: string): Remote
		if RemotesFolder == nil then
			RemotesFolder = CONTAINER:WaitForChild(FOLDER_NAME)
			RequestFunction = RemotesFolder:WaitForChild("Request")
		end
		return Remote.new(name)
	end
end
