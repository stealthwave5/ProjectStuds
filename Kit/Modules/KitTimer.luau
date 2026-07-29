--[[
	Author(s): Gory
	Module: KitTimer.luau
--]]

local RunService = game:GetService("RunService")

local KitSettings = require(script.Parent.KitSettings) ---@module KitSettings

local KitTimer = {}

local HUNG_WARNING_TIME = 4

local CurrentLabel
local CurrentStartTime
local WarningsEnabled = RunService:IsStudio()
local LastWarning = 0

local FeatureStartingOvertimeLabels: { string }?
local FeatureStartingConnection: RBXScriptConnection?

function KitTimer:ConnectJobStarting()
	FeatureStartingOvertimeLabels = {}
	FeatureStartingConnection = RunService.Heartbeat:Connect(function()
		if CurrentLabel == nil then
			return
		end
		local clock = os.clock()
		if clock - LastWarning < 1 then
			return
		end
		LastWarning = clock
		local duration = clock - CurrentStartTime
		if duration > HUNG_WARNING_TIME then
			warn(`Stuck on {CurrentLabel}`)
			LastWarning = clock
		end
	end)
end

function KitTimer:DisconnectJobStarting()
	if FeatureStartingConnection then
		FeatureStartingConnection:Disconnect()
		FeatureStartingConnection = nil
	end
	if FeatureStartingOvertimeLabels then
		local longTimers: string
		if FeatureStartingOvertimeLabels[1] then
			longTimers =
				`\n\nReduce these time consuming features:\n\n{table.concat(FeatureStartingOvertimeLabels, "\n")}`
		else
			longTimers = ""
		end
		FeatureStartingOvertimeLabels = nil
		return longTimers
	end
end

function KitTimer:Time(label: string, budget: number, callback: (any...) -> any..., ...: any...): any...
	local startTime = os.clock()
	CurrentLabel = label
	CurrentStartTime = startTime

	local returnArgs = { callback(...) }
	local duration = os.clock() - startTime

	if WarningsEnabled and duration > budget then
		local warning = string.format("%.3f %s", duration, label)
		if not KitSettings.Verbose and FeatureStartingOvertimeLabels then
			table.insert(FeatureStartingOvertimeLabels, warning)
		else
			warn(warning)
		end
	elseif KitSettings.Verbose then
		print(string.format("%.3f %s", duration, label))
	end
	if CurrentLabel == label then
		CurrentLabel = nil
	end
	return unpack(returnArgs)
end

return KitTimer
