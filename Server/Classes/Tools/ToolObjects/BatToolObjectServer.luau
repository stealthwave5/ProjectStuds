--[[
	Author(s): Josh, Claude
	Module: BatToolObjectServer.luau
--]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Modules
local BackpackServer = shared("BackpackServer") ---@module BackpackServer
local ToolBaseObjectServer = shared("ToolBaseObjectServer") ---@module ToolBaseObjectServer

-- Constants
local SWING_COOLDOWN = 1
local HIT_RANGE = 8
local HIT_DOT_THRESHOLD = 0.2
local SWING_OUT_TIME = 0.12
local SWING_BACK_TIME = 0.18
local SWING_ANGLE_DEGREES = -110
local SWING_SOUND_NAME = "Swing"

local BatToolObjectServer = setmetatable({}, { __index = ToolBaseObjectServer })
BatToolObjectServer.__index = BatToolObjectServer
BatToolObjectServer.ClassName = "BatToolObjectServer"

export type BatToolObjectServer = ToolBaseObjectServer.ToolBaseObjectServer

-- Constructor

function BatToolObjectServer.new(tool: Tool): BatToolObjectServer
	local self = setmetatable({}, BatToolObjectServer)
	self:_setup(tool)

	self._lastSwingTime = 0
	self._baseGrip = tool.Grip

	return self :: any
end

-- Private functions

function BatToolObjectServer:_playSwing()
	local tool = self.Tool :: Tool
	local baseGrip = self._baseGrip :: CFrame
	local outGrip = baseGrip * CFrame.Angles(math.rad(SWING_ANGLE_DEGREES), 0, 0)

	local outTween = TweenService:Create(
		tool,
		TweenInfo.new(SWING_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Grip = outGrip }
	)
	outTween.Completed:Once(function()
		TweenService:Create(
			tool,
			TweenInfo.new(SWING_BACK_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Grip = baseGrip }
		):Play()
	end)
	outTween:Play()

	local handle = tool:FindFirstChild("Handle")
	local swingSound = handle and handle:FindFirstChild(SWING_SOUND_NAME)
	if swingSound and swingSound:IsA("Sound") then
		swingSound:Play()
	end
end

function BatToolObjectServer:_hitPlayersInArc(attacker: Player, rootPart: BasePart)
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer == attacker then
			continue
		end
		local otherCharacter = otherPlayer.Character
		if otherCharacter == nil then
			continue
		end
		local otherHumanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
		local otherRoot = otherCharacter:FindFirstChild("HumanoidRootPart")
		if otherHumanoid == nil or otherHumanoid.Health <= 0 then
			continue
		end
		if otherRoot == nil or not otherRoot:IsA("BasePart") then
			continue
		end

		local offset = otherRoot.Position - rootPart.Position
		if offset.Magnitude > HIT_RANGE or offset.Magnitude == 0 then
			continue
		end
		if offset.Unit:Dot(rootPart.CFrame.LookVector) <= HIT_DOT_THRESHOLD then
			continue
		end

		BackpackServer:DropCarried(otherPlayer)
	end
end

-- Public functions

function BatToolObjectServer:OnActivated()
	local now = os.clock()
	if now - self._lastSwingTime < SWING_COOLDOWN then
		return
	end
	self._lastSwingTime = now

	local attacker = self:GetOwner()
	local character = attacker and attacker.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if attacker == nil or rootPart == nil or not rootPart:IsA("BasePart") then
		return
	end

	self:_playSwing()
	self:_hitPlayersInArc(attacker, rootPart)
end

return BatToolObjectServer
