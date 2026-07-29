--[[
	Author(s): Josh, Claude
	Module: BuyButtonPane.luau
]]

-- Modules

local FormatUtil = shared("FormatUtil") ---@module FormatUtil
local GuiStyles = shared("GuiStyles") ---@module GuiStyles

local GuiButtonPane = shared("GuiButtonPane") ---@module GuiButtonPane
local BuyButtonPane = setmetatable({}, GuiButtonPane)
BuyButtonPane.__index = BuyButtonPane
BuyButtonPane.ClassName = "BuyButtonPane"

-- Types

export type BuyButtonPane = GuiButtonPane.GuiButtonPane & {
	SetCost: (self: BuyButtonPane, cost: number?) -> (),
}

-- Constants

local MAX_TEXT = "MAX"
local HIGHLIGHT_SCALE = 0.05
local PRESS_SCALE = 0.08
local HIGHLIGHT_BRIGHTNESS = 0.12
local DISABLED_TEXT_FADE = 0.25

-- Public functions

---Sets the displayed cost. Pass nil to show the gray MAX state.
function BuyButtonPane:SetCost(cost: number?)
	if cost == nil then
		self._costLabel.Text = MAX_TEXT
	else
		self._costLabel.Text = FormatUtil:FormatCash(cost)
	end
end

-- Private functions

function BuyButtonPane:_updateGui(values: {
	Alpha: number,
	Chosen: number,
	Enabled: number,
	Highlight: number,
	Press: number,
})
	local shownAmount = 1 - values.Alpha
	local disabledAmount = 1 - values.Enabled
	local juiceScale = 1 + HIGHLIGHT_SCALE * values.Highlight - PRESS_SCALE * values.Press
	local designScale = shownAmount * juiceScale

	local designBrightness = math.clamp(self._accentBrightness + HIGHLIGHT_BRIGHTNESS * values.Highlight, 0, 1)
	local designColor = Color3.fromHSV(self._accentHue, self._accentSaturation, designBrightness)

	self._design.Size = UDim2.fromScale(designScale, designScale)
	self._design.BackgroundColor3 = designColor:Lerp(GuiStyles.Colors.Disabled, disabledAmount)
	self._design.BackgroundTransparency = values.Alpha
	self._designStroke.Transparency = values.Alpha
	self._costLabel.TextTransparency = values.Alpha + DISABLED_TEXT_FADE * disabledAmount
	self.Gui.Visible = shownAmount > 0.001
end

-- Constructor

function BuyButtonPane.new(): BuyButtonPane
	local self = setmetatable(
		GuiButtonPane.new({
			Template = "BuyButtonPaneTemplate",
			Instances = {
				_design = "BuyDesign",
				_designStroke = "BuyStroke",
				_costLabel = "BuyLabel",
			},
		}),
		BuyButtonPane
	)

	self:SetAlphaEnabled(true)

	local accentHue, accentSaturation, accentBrightness = Color3.toHSV(GuiStyles.Colors.Buttons.Green)
	self._accentHue = accentHue
	self._accentSaturation = accentSaturation
	self._accentBrightness = accentBrightness

	self:_guiPaneReady()

	return self
end

return BuyButtonPane
