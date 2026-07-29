--[[
	Author(s): Josh, Claude
	Module: ScreenGuisClient.luau
]]

-- Services

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Types

export type ScreenGuiOptions = {
	Name: string,
	DisplayOrder: number?,
	Enabled: boolean?,
}

-- Constants

--	The offset-based layout is designed against 1920x1080; smaller viewports get a
--	proportional UIScale so the UI never reads oversized (or overflows) on laptops/mobile.
local DESIGN_RESOLUTION = Vector2.new(1920, 1080)
local MIN_UI_SCALE = 0.6
local MAX_UI_SCALE = 1

-- Variables

local ScreenGuisClient = {}

local ScreenGuis: { [string]: ScreenGui } = {}
local UiScales: { UIScale } = {}

-- Private functions

local function getViewportScale(): number
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return 1
	end
	local viewportSize = camera.ViewportSize
	local scale = math.min(viewportSize.X / DESIGN_RESOLUTION.X, viewportSize.Y / DESIGN_RESOLUTION.Y)
	return math.clamp(scale, MIN_UI_SCALE, MAX_UI_SCALE)
end

local function refreshUiScales()
	local scale = getViewportScale()
	for _, uiScale in UiScales do
		uiScale.Scale = scale
	end
end

local cameraViewportConnection: RBXScriptConnection? = nil

local function watchCameraViewport()
	if cameraViewportConnection ~= nil then
		cameraViewportConnection:Disconnect()
		cameraViewportConnection = nil
	end
	local camera = Workspace.CurrentCamera
	if camera ~= nil then
		cameraViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshUiScales)
	end
end

-- Public functions

---Creates (or returns the existing) named ScreenGui under PlayerGui. Idempotent.
---Defaults: Enabled = false, ResetOnSpawn = false, ZIndexBehavior = Sibling.
function ScreenGuisClient:Create(options: ScreenGuiOptions): ScreenGui
	assert(type(options) == "table" and type(options.Name) == "string", "[ScreenGuisClient] Options require Name.")

	local existing = ScreenGuis[options.Name]
	if existing ~= nil then
		if options.DisplayOrder ~= nil then
			existing.DisplayOrder = options.DisplayOrder
		end
		if options.Enabled ~= nil then
			existing.Enabled = options.Enabled
		end
		return existing
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = options.Name
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = options.DisplayOrder or 0
	screenGui.Enabled = options.Enabled == true

	local uiScale = Instance.new("UIScale")
	uiScale.Name = "ViewportScale"
	uiScale.Scale = getViewportScale()
	uiScale.Parent = screenGui
	table.insert(UiScales, uiScale)

	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	ScreenGuis[options.Name] = screenGui
	return screenGui
end

---Returns a previously created ScreenGui by name, or nil.
function ScreenGuisClient:Get(name: string): ScreenGui?
	return ScreenGuis[name]
end

-- Start

function ScreenGuisClient:Run()
	watchCameraViewport()
	refreshUiScales()
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		watchCameraViewport()
		refreshUiScales()
	end)
end

return ScreenGuisClient
