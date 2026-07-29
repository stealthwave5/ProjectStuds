--[[
	Author(s): Josh, Claude
	Module: ToolBaseObjectServer.luau
--]]

-- Services
local Players = game:GetService("Players")

-- Modules
local Maid = shared("Maid") ---@module Maid

local ToolBaseObjectServer = {}
ToolBaseObjectServer.__index = ToolBaseObjectServer
ToolBaseObjectServer.ClassName = "ToolBaseObjectServer"

-- Types
export type ToolBaseObjectServer = {
	GetOwner: (self: ToolBaseObjectServer) -> Player?,
	OnActivated: (self: ToolBaseObjectServer) -> (),
	OnEquipped: (self: ToolBaseObjectServer) -> (),
	OnUnequipped: (self: ToolBaseObjectServer) -> (),
	Destroy: (self: ToolBaseObjectServer) -> (),
	Tool: Tool,
	ToolName: string,
}

-- Constructor

function ToolBaseObjectServer.new(tool: Tool): ToolBaseObjectServer
	local self = setmetatable({}, ToolBaseObjectServer)
	self:_setup(tool)
	return self :: any
end

-- Private functions

---Shared setup so subclasses can construct through their own metatable.
function ToolBaseObjectServer:_setup(tool: Tool)
	self._maid = Maid.new()

	self.Tool = tool
	local toolName = tool:GetAttribute("ToolName")
	self.ToolName = if type(toolName) == "string" then toolName else tool.Name

	self._maid:Add(tool.Activated:Connect(function()
		self:OnActivated()
	end))
	self._maid:Add(tool.Equipped:Connect(function()
		self:OnEquipped()
	end))
	self._maid:Add(tool.Unequipped:Connect(function()
		self:OnUnequipped()
	end))
end

-- Public functions

function ToolBaseObjectServer:GetOwner(): Player?
	local tool = self.Tool :: Tool
	local parent = tool.Parent
	if parent and parent:IsA("Model") then
		local player = Players:GetPlayerFromCharacter(parent)
		if player then
			return player
		end
	end
	return tool:FindFirstAncestorOfClass("Player")
end

function ToolBaseObjectServer:OnActivated() end

function ToolBaseObjectServer:OnEquipped() end

function ToolBaseObjectServer:OnUnequipped() end

function ToolBaseObjectServer:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._maid:DoCleaning()
end

return ToolBaseObjectServer
