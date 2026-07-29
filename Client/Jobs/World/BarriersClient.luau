--[[
	Author(s): Josh, Claude
	Module: BarriersClient.luau
]]

-- Services
local Players = game:GetService("Players")

-- Types
type BarrierEntry = {
	Part: BasePart,
	Label: TextLabel,
	RequiredSpeed: number,
}

-- Constants
local TIER_FLOORS_NAME = "TierFloors"
local TIER_FLOORS_TIMEOUT = 10
local REQUIRED_SPEED_ATTRIBUTE = "RequiredSpeed"
local SIGN_NAME = "Sign"
local SIGN_LABEL_NAME = "Label"

local PASSABLE_TRANSPARENCY = 0.85
local BLOCKED_TRANSPARENCY = 0.35
local PASSABLE_COLOR = Color3.fromRGB(130, 255, 150)
local BLOCKED_COLOR = Color3.fromRGB(255, 90, 90)

local DEFAULT_WALK_SPEED = 16

-- Variables
local BarriersClient = {}

local barrierEntries: { BarrierEntry } = {}
local currentWalkSpeed = DEFAULT_WALK_SPEED

-- Private functions
local function applyBarrierState(barrierEntry: BarrierEntry)
	local passable = currentWalkSpeed >= barrierEntry.RequiredSpeed

	barrierEntry.Part.CanCollide = not passable
	barrierEntry.Part.Transparency = if passable then PASSABLE_TRANSPARENCY else BLOCKED_TRANSPARENCY

	if passable then
		barrierEntry.Label.Text = `✓ {barrierEntry.RequiredSpeed} SPEED`
		barrierEntry.Label.TextColor3 = PASSABLE_COLOR
	else
		barrierEntry.Label.Text = `REQUIRES {barrierEntry.RequiredSpeed} SPEED`
		barrierEntry.Label.TextColor3 = BLOCKED_COLOR
	end
end

local function refreshAllBarriers()
	for _, barrierEntry in barrierEntries do
		applyBarrierState(barrierEntry)
	end
end

local function watchBarrier(barrierInstance: Instance)
	if not barrierInstance:IsA("BasePart") then
		return
	end

	local requiredSpeed = barrierInstance:GetAttribute(REQUIRED_SPEED_ATTRIBUTE)
	if typeof(requiredSpeed) ~= "number" then
		return
	end

	task.spawn(function()
		local sign = barrierInstance:WaitForChild(SIGN_NAME)
		local signLabel = sign:WaitForChild(SIGN_LABEL_NAME)
		if not signLabel:IsA("TextLabel") then
			warn(`[BarriersClient] {barrierInstance.Name}.{SIGN_NAME}.{SIGN_LABEL_NAME} is not a TextLabel`)
			return
		end

		local barrierEntry: BarrierEntry = {
			Part = barrierInstance,
			Label = signLabel,
			RequiredSpeed = requiredSpeed,
		}
		table.insert(barrierEntries, barrierEntry)
		applyBarrierState(barrierEntry)
	end)
end

local function watchCharacter(character: Model)
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid")
		if not humanoid:IsA("Humanoid") then
			return
		end

		currentWalkSpeed = humanoid.WalkSpeed
		refreshAllBarriers()

		humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			currentWalkSpeed = humanoid.WalkSpeed
			refreshAllBarriers()
		end)
	end)
end

-- Start
function BarriersClient:Run()
	local tierFloors = workspace:WaitForChild(TIER_FLOORS_NAME, TIER_FLOORS_TIMEOUT)
	if not tierFloors then
		warn(`[BarriersClient] {TIER_FLOORS_NAME} not found in Workspace`)
		return
	end

	tierFloors.ChildAdded:Connect(watchBarrier)
	for _, barrierInstance in tierFloors:GetChildren() do
		watchBarrier(barrierInstance)
	end

	local localPlayer = Players.LocalPlayer
	localPlayer.CharacterAdded:Connect(watchCharacter)
	if localPlayer.Character then
		watchCharacter(localPlayer.Character)
	end
end

return BarriersClient
