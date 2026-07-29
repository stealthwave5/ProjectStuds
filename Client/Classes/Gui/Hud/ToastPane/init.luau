--[[
	Author(s): Josh, Claude
	Module: ToastPane.luau
]]

-- Modules

local GuiStyles = shared("GuiStyles") ---@module GuiStyles

local GuiPane = shared("GuiPane") ---@module GuiPane
local ToastPane = setmetatable({}, GuiPane)
ToastPane.__index = ToastPane
ToastPane.ClassName = "ToastPane"

-- Types

export type ToastPane = GuiPane.GuiPane & {
	SetText: (self: ToastPane, text: string) -> (),
	SetColor: (self: ToastPane, color: Color3) -> (),
	Play: (self: ToastPane) -> (),
}

-- Constants

local DRIFT_SPRING = { t = 0, s = 4, d = 1 }
local DRIFT_PIXELS = 46
local DRIFT_FADE = 0.85
local TOAST_SECONDS = 1.6

-- Public functions

function ToastPane:SetText(text: string)
	self._label.Text = text
end

function ToastPane:SetColor(color: Color3)
	self._label.TextColor3 = color
end

---Shows the toast instantly, drifts it upward while fading, then auto-hides.
function ToastPane:Play()
	self:SetVisible(false, true)
	self:SetVisible(true, true)
	self._springSet:Snap("Drift", 0)
	self._springSet:SetTarget("Drift", 1)
	self.Maid._toastHide = task.delay(TOAST_SECONDS, function()
		self:SetVisible(false, true)
	end)
end

-- Private functions

function ToastPane:_updateGui(values: { Alpha: number, Drift: number })
	local drift = values.Drift
	local fade = math.clamp(values.Alpha + DRIFT_FADE * drift * drift, 0, 1)

	self._label.Position = UDim2.new(0.5, 0, 0.5, -DRIFT_PIXELS * drift)
	self._label.TextTransparency = fade
	self._labelStroke.Transparency = fade
	self.Gui.Visible = fade < 0.999
end

-- Constructor

function ToastPane.new(): ToastPane
	local self = setmetatable(
		GuiPane.new({
			Template = "ToastPaneTemplate",
			Instances = {
				_label = "ToastLabel",
				_labelStroke = "ToastStroke",
			},
		}),
		ToastPane
	)

	self:SetAlphaEnabled(true)

	self._springSet:AddSpring("Drift", DRIFT_SPRING)

	self:SetColor(GuiStyles.Colors.TextWhite)

	self:_guiPaneReady()

	return self
end

return ToastPane
