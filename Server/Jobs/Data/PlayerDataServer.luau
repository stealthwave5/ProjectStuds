--[[
	Author(s): Gory
	Module: PlayerDataServer.luau
--]]

local Players = game:GetService("Players")

local PlayerAddedUtil = shared("PlayerAddedUtil") ---@module PlayerAddedUtil
local ProfileService = shared("ProfileService") ---@module ProfileService
local ProfileTemplate = shared("ProfileTemplate") ---@module ProfileTemplate
local ReplicaService = shared("ReplicaService") ---@module ReplicaService
local Signal = shared("Signal") ---@module Signal

local PlayerDataServer = {}
PlayerDataServer.PlayerReady = Signal.new() :: Signal.Signal<Player, Replica>

export type Replica = ReplicaService.Replica

local STORE_NAME = "PlayerData-10"

local PlayerProfileStore
local ReplicaToken = ReplicaService.NewClassToken("PlayerData")

local PlayerProfiles: { [Player]: {} } = {}
local PlayerDataReplicas: { [Player]: Replica } = {}
-- Fires either when a replica is added or removed, or when a player is added or removed.
local WaitingForReplicaSignal = Signal.new()

--[[
	Helpers
]]

function PlayerDataServer:SetValue(player: Player, path: { string }, value: any?)
	self:WaitForReplica(player):SetValue(path, value)
end

function PlayerDataServer:Reset(player: Player): boolean
	self:_stopPlayerData(player)
	if not PlayerProfileStore:WipeProfileAsync(tostring(player.UserId)) then
		return false
	end
	player:Kick()
	return true
end

--[[
	Replica and Profile
]]

function PlayerDataServer:GetReplica(player: Player): Replica?
	return PlayerDataReplicas[player]
end

function PlayerDataServer:WaitForReplica(player: Player, timeout: number?): Replica?
	local replica = PlayerDataReplicas[player]
	if replica then
		return replica
	end
	local timeoutThread
	local timedout = false
	if timeout then
		timeoutThread = task.delay(timeout, function()
			timedout = true
			WaitingForReplicaSignal:Fire()
		end)
	end
	while replica == nil and not timedout do
		if not player:IsDescendantOf(Players) then
			break
		end
		WaitingForReplicaSignal:Wait()
		replica = PlayerDataReplicas[player]
	end
	if timeoutThread then
		pcall(task.cancel, timeoutThread)
	end
	return replica
end

function PlayerDataServer:_onProfileReleasing(player: Player)
	local replica = PlayerDataReplicas[player]
	if replica then
		replica:Destroy()
		PlayerDataReplicas[player] = nil
	end
	PlayerProfiles[player] = nil

	player:Kick("[PlayerDataServer]: Duplicate sessions. Rejoin")
end

function PlayerDataServer:_startPlayerData(player: Player)
	local profile = PlayerProfileStore:LoadProfileAsync(tostring(player.UserId), "ForceLoad")
	if profile == nil then
		player:Kick("[PlayerDataServer]: Error getting profile, please rejoin.")
		return
	end

	if not player:IsDescendantOf(Players) then
		profile:Release()
		return
	end

	self:_setJoinedSessionValues(profile.Data)

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile:ListenToRelease(function()
		self:_setLeavingSessionValues(profile.Data)
		self:_onProfileReleasing(player)
	end)
	local replica = ReplicaService.NewReplica({
		ClassToken = ReplicaToken,
		Tags = { Player = player },
		Data = profile.Data,
		Replication = { [player] = true },
	})

	PlayerProfiles[player] = profile
	PlayerDataReplicas[player] = replica
	self.PlayerReady:Fire(player, replica)
	WaitingForReplicaSignal:Fire()
end

function PlayerDataServer:_stopPlayerData(player: Player)
	local profile = PlayerProfiles[player]
	if profile then
		profile:Release()
	end
end

function PlayerDataServer:_setJoinedSessionValues(data: {
	FirstTimeJoined: number?,
	LastTimeJoined: number?,
	LastTimeLeaving: number?,
	TimeBetweenSessions: number?,
})
	local timeNow = DateTime.now().UnixTimestamp
	data.LastTimeJoined = timeNow
	if data.LastTimeLeaving ~= nil then
		data.TimeBetweenSessions = data.LastTimeJoined - data.LastTimeLeaving
	end
	if data.FirstTimeJoined == nil then
		data.FirstTimeJoined = timeNow
	end
end

function PlayerDataServer:_setLeavingSessionValues(data: {
	LastTimeJoined: number?,
	LastTimeLeaving: number?,
	TimeBetweenSessions: number?,
})
	data.LastTimeLeaving = DateTime.now().UnixTimestamp
end

function PlayerDataServer:Run()
	PlayerProfileStore = ProfileService.GetProfileStore(STORE_NAME, ProfileTemplate)

	PlayerAddedUtil:Connect({
		Added = function(player: Player)
			self:_startPlayerData(player)
		end,
		Removing = function(player: Player)
			WaitingForReplicaSignal:Fire()
			self:_stopPlayerData(player)
		end,
	})
end

return PlayerDataServer
