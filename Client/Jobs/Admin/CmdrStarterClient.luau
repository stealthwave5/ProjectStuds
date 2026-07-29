--[[
	Author(s): Gory
	Module: CmdrStarterClient.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrStarterClient = {}

function CmdrStarterClient:Run()
	local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient"))
	CmdrClient:SetActivationKeys({ Enum.KeyCode.F2, Enum.KeyCode.BackSlash })
end

return CmdrStarterClient
