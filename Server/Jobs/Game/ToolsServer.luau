--[[
	Author(s): Josh, Claude
	Module: ToolsServer.luau
--]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Modules
local Assets = shared("Assets") ---@module Assets
local PlayerAddedUtil = shared("PlayerAddedUtil") ---@module PlayerAddedUtil
local TagObjects = shared("TagObjects") ---@module TagObjects
local ToolBaseObjectServer = shared("ToolBaseObjectServer") ---@module ToolBaseObjectServer

-- Constants
local TOOL_TAG = "Tool"
local BAT_ASSET_NAME = "Bat"
local BACKPACK_WAIT_TIMEOUT = 10

local ToolsServer = {}
ToolsServer.Binder = nil :: TagObjects.TagObjects?

-- Private functions

---Resolves `{ToolName}ToolObjectServer` (fallback ToolBaseObjectServer) and
---binds it. Ignores tagged instances outside Workspace/Players (templates).
function ToolsServer:_createToolObject(instance: Instance): any?
	if not instance:IsA("Tool") then
		return nil
	end
	if not (instance:IsDescendantOf(Workspace) or instance:IsDescendantOf(Players)) then
		return nil
	end

	local objectClass = nil
	local toolName = instance:GetAttribute("ToolName")
	if type(toolName) == "string" then
		local success, result = pcall(shared, `{toolName}ToolObjectServer`)
		if success then
			objectClass = result
		end
	end
	if objectClass == nil then
		objectClass = ToolBaseObjectServer
	end
	return objectClass.new(instance)
end

---Grants the Bat every spawn (StarterPack parity).
function ToolsServer:_grantBat(player: Player)
	task.spawn(function()
		local backpack = player:WaitForChild("Backpack", BACKPACK_WAIT_TIMEOUT)
		if backpack == nil then
			return
		end
		local character = player.Character
		local hasBat = backpack:FindFirstChild(BAT_ASSET_NAME) ~= nil
			or (character ~= nil and character:FindFirstChild(BAT_ASSET_NAME) ~= nil)
		if hasBat then
			return
		end
		local bat = Assets:Clone(BAT_ASSET_NAME)
		bat.Parent = backpack
	end)
end

function ToolsServer:_onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function()
		self:_grantBat(player)
	end)
	if player.Character then
		self:_grantBat(player)
	end
end

-- Start

function ToolsServer:Run()
	self.Binder = TagObjects.new(TOOL_TAG, function(instance: Instance)
		return self:_createToolObject(instance)
	end)
	PlayerAddedUtil:Connect({
		Added = function(player: Player)
			self:_onPlayerAdded(player)
		end,
	})
end

return ToolsServer
