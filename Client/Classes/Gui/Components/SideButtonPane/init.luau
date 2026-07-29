--[[
	Author(s): Josh, Claude
	Module: SideButtonPane.luau
]]

-- Modules

local GuiStyles = shared("GuiStyles") ---@module GuiStyles

local GuiButtonPane = shared("GuiButtonPane") ---@module GuiButtonPane
local SideButtonPane = setmetatable({}, GuiButtonPane)
SideButtonPane.__index = SideButtonPane
SideButtonPane.ClassName = "SideButtonPane"

-- Types

export type SideButtonPaneOptions = {
	Icon: string,
	Title: string,
	Accent: Color3?,
	CostLineEnabled: boolean?,
}

export type SideButtonPane = GuiButtonPane.GuiButtonPane & {
	SetCostText: (self: SideButtonPane, costText: string?) -> (),
}

-- Constants

local HIGHLIGHT_SCALE = 0.05
local PRESS_SCALE = 0.08
local CHOSEN_SCALE = 0.03
local DISABLED_SATURATION = 0.35
local DISABLED_BRIGHTNESS = 0.55
local HIGHLIGHT_BRIGHTNESS = 0.12

-- Public functions

function SideButtonPane:SetCostText(costText: string?)
	if costText == nil then
		self._costLabel.Visible = false
		return
	end
	self._costLabel.Visible = true
	self._costLabel.Text = costText
end

-- Private functions

function SideButtonPane:_updateGui(values: {
	Alpha: number,
	Chosen: number,
	Enabled: number,
	Highlight: number,
	Press: number,
})
	local shownAmount = 1 - values.Alpha
	local juiceScale = 1
		+ HIGHLIGHT_SCALE * values.Highlight
		- PRESS_SCALE * values.Press
		+ CHOSEN_SCALE * values.Chosen
	local designScale = shownAmount * juiceScale

	local enabledSaturation = self._accentSaturation * (DISABLED_SATURATION + (1 - DISABLED_SATURATION) * values.Enabled)
	local enabledBrightness = self._accentBrightness * (DISABLED_BRIGHTNESS + (1 - DISABLED_BRIGHTNESS) * values.Enabled)
	local designBrightness = math.clamp(enabledBrightness + HIGHLIGHT_BRIGHTNESS * values.Highlight, 0, 1)

	self._design.Size = UDim2.fromScale(designScale, designScale)
	self._design.BackgroundColor3 = Color3.fromHSV(self._accentHue, enabledSaturation, designBrightness)
	self._design.BackgroundTransparency = values.Alpha
	self._designStroke.Transparency = values.Alpha
	self._iconLabel.TextTransparency = values.Alpha
	self._titleLabel.TextTransparency = values.Alpha
	self._costLabel.TextTransparency = values.Alpha
	self.Gui.Visible = shownAmount > 0.001
end

-- Constructor

function SideButtonPane.new(options: SideButtonPaneOptions): SideButtonPane
	local self = setmetatable(
		GuiButtonPane.new({
			Template = "SideButtonPaneTemplate",
			Instances = {
				_design = "SideDesign",
				_designStroke = "SideStroke",
				_iconLabel = "SideIcon",
				_titleLabel = "SideTitle",
				_costLabel = "SideCost",
			},
		}),
		SideButtonPane
	)

	self:SetAlphaEnabled(true)

	local accent = options.Accent or GuiStyles.Colors.Buttons.Blue
	local accentHue, accentSaturation, accentBrightness = Color3.toHSV(accent)
	self._accentHue = accentHue
	self._accentSaturation = accentSaturation
	self._accentBrightness = accentBrightness

	self._iconLabel.Text = options.Icon
	self._titleLabel.Text = options.Title
	self._costLabel.Visible = options.CostLineEnabled == true

	self:_guiPaneReady()

	return self
end

return SideButtonPane
