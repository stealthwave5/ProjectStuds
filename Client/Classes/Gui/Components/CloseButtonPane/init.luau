--[[
	Author(s): Josh, Claude
	Module: CloseButtonPane.luau
]]

-- Modules

local GuiStyles = shared("GuiStyles") ---@module GuiStyles

local GuiButtonPane = shared("GuiButtonPane") ---@module GuiButtonPane
local CloseButtonPane = setmetatable({}, GuiButtonPane)
CloseButtonPane.__index = CloseButtonPane
CloseButtonPane.ClassName = "CloseButtonPane"

-- Types

export type CloseButtonPane = GuiButtonPane.GuiButtonPane & {
	-- Type
}

-- Constants

local HIGHLIGHT_SCALE = 0.08
local PRESS_SCALE = 0.1
local HIGHLIGHT_BRIGHTNESS = 0.12

-- Private functions

function CloseButtonPane:_updateGui(values: {
	Alpha: number,
	Chosen: number,
	Enabled: number,
	Highlight: number,
	Press: number,
})
	local shownAmount = 1 - values.Alpha
	local juiceScale = 1 + HIGHLIGHT_SCALE * values.Highlight - PRESS_SCALE * values.Press
	local designScale = shownAmount * juiceScale

	local designBrightness = math.clamp(self._accentBrightness + HIGHLIGHT_BRIGHTNESS * values.Highlight, 0, 1)

	self._design.Size = UDim2.fromScale(designScale, designScale)
	self._design.BackgroundColor3 = Color3.fromHSV(self._accentHue, self._accentSaturation, designBrightness)
	self._design.BackgroundTransparency = values.Alpha
	self._designStroke.Transparency = values.Alpha
	self._iconLabel.TextTransparency = values.Alpha
	self.Gui.Visible = shownAmount > 0.001
end

-- Constructor

function CloseButtonPane.new(): CloseButtonPane
	local self = setmetatable(
		GuiButtonPane.new({
			Template = "CloseButtonPaneTemplate",
			Instances = {
				_design = "CloseDesign",
				_designStroke = "CloseStroke",
				_iconLabel = "CloseIcon",
			},
		}),
		CloseButtonPane
	)

	self:SetAlphaEnabled(true)

	local accentHue, accentSaturation, accentBrightness = Color3.toHSV(GuiStyles.Colors.Buttons.Red)
	self._accentHue = accentHue
	self._accentSaturation = accentSaturation
	self._accentBrightness = accentBrightness

	self:_guiPaneReady()

	return self
end

return CloseButtonPane
