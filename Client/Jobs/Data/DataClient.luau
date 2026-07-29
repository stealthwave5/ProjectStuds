--[[
	Author(s): Gory
	Module: DataClient.luau
--]]

local ReplicaController = shared("ReplicaController") ---@module ReplicaController
local Signal = shared("Signal") ---@module Signal

local DataClient = {}
DataClient.Ready = Signal.new()

export type Replica = ReplicaController.Replica

local DataReplica

function DataClient:IsReady()
	return DataReplica ~= nil
end

function DataClient:GetReplica(): Replica?
	return DataReplica
end

function DataClient:WaitForReplica(): Replica
	if DataReplica == nil then
		self.Ready:Wait()
	end
	return DataReplica
end

function DataClient:Run()
	ReplicaController.ReplicaOfClassCreated("PlayerData", function(replica)
		DataReplica = replica
		self.Ready:Fire()
	end)
	ReplicaController.RequestData()
end

return DataClient
