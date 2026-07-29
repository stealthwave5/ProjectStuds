--[[
	Author(s): Josh, Claude
	Module: ShopItemButtonPane.luau
]]

-- Modules

local GuiStyles = shared("GuiStyles") ---@module GuiStyles

local GuiButtonPane = shared("GuiButtonPane") ---@module GuiButtonPane
local ShopItemButtonPane = setmetatable({}, GuiButtonPane)
ShopItemButtonPane.__index = ShopItemButtonPane
ShopItemButtonPane.ClassName = "ShopItemButtonPane"

-- Types

export type ShopItemButtonPaneOptions = {
	Title: string?,
	Subtitle: string?,
	Accent: Color3?,
}

export type ShopItemButtonPane = GuiButtonPane.GuiButtonPane & {
	SetTitle: (self: ShopItemButtonPane, title: string) -> (),
	SetSubtitle: (self: ShopItemButtonPane, subtitle: string) -> (),
	SetOwned: (self: ShopItemButtonPane, owned: boolean) -> (),
	IsOwned: (self: ShopItemButtonPane) -> boolean,
}

-- Constants

local OWNED_SUBTITLE = "OWNED ✓"
local HIGHLIGHT_SCALE = 0.05
local PRESS_SCALE = 0.08
local HIGHLIGHT_BRIGHTNESS = 0.12
local DISABLED_SATURATION = 0.4
local DISABLED_BRIGHTNESS = 0.6

-- Public functions

function ShopItemButtonPane:SetTitle(title: string)
	self._titleLabel.Text = title
end

function ShopItemButtonPane:SetSubtitle(subtitle: string)
	self._subtitleLabel.Text = subtitle
end

---Switches the button into (or out of) the green non-interactable owned state.
function ShopItemButtonPane:SetOwned(owned: boolean)
	if self._owned == owned then
		return
	end
	self._owned = owned
	if owned then
		self._subtitleBeforeOwned = self._subtitleLabel.Text
		self:_applyAccent(GuiStyles.Colors.Buttons.Green)
		self:SetSubtitle(OWNED_SUBTITLE)
		self:SetInteractionEnabled(false)
	else
		self:_applyAccent(self._baseAccent)
		self:SetSubtitle(self._subtitleBeforeOwned or "")
		self:SetInteractionEnabled(true)
	end
end

function ShopItemButtonPane:IsOwned(): boolean
	return self._owned == true
end

-- Private functions

function ShopItemButtonPane:_applyAccent(accent: Color3)
	local accentHue, accentSaturation, accentBrightness = Color3.toHSV(accent)
	self._accentHue = accentHue
	self._accentSaturation = accentSaturation
	self._accentBrightness = accentBrightness
	self._springSet:Update()
end

function ShopItemButtonPane:_updateGui(values: {
	Alpha: number,
	Chosen: number,
	Enabled: number,
	Highlight: number,
	Press: number,
})
	local shownAmount = 1 - values.Alpha
	local juiceScale = 1 + HIGHLIGHT_SCALE * values.Highlight - PRESS_SCALE * values.Press
	local designScale = shownAmount * juiceScale

	local enabledSaturation = self._accentSaturation * (DISABLED_SATURATION + (1 - DISABLED_SATURATION) * values.Enabled)
	local enabledBrightness = self._accentBrightness * (DISABLED_BRIGHTNESS + (1 - DISABLED_BRIGHTNESS) * values.Enabled)
	local designBrightness = math.clamp(enabledBrightness + HIGHLIGHT_BRIGHTNESS * values.Highlight, 0, 1)

	self._design.Size = UDim2.fromScale(designScale, designScale)
	self._design.BackgroundColor3 = Color3.fromHSV(self._accentHue, enabledSaturation, designBrightness)
	self._design.BackgroundTransparency = values.Alpha
	self._designStroke.Transparency = values.Alpha
	self._titleLabel.TextTransparency = values.Alpha
	self._subtitleLabel.TextTransparency = values.Alpha
	self.Gui.Visible = shownAmount > 0.001
end

-- Constructor

function ShopItemButtonPane.new(options: ShopItemButtonPaneOptions?): ShopItemButtonPane
	local paneOptions: ShopItemButtonPaneOptions = options or {}
	local self = setmetatable(
		GuiButtonPane.new({
			Template = "ShopItemButtonPaneTemplate",
			Instances = {
				_design = "ShopItemDesign",
				_designStroke = "ShopItemStroke",
				_titleLabel = "ShopItemTitle",
				_subtitleLabel = "ShopItemSubtitle",
			},
		}),
		ShopItemButtonPane
	)

	self:SetAlphaEnabled(true)

	self._owned = false
	self._baseAccent = paneOptions.Accent or GuiStyles.Colors.Buttons.Green
	self:_applyAccent(self._baseAccent)

	if paneOptions.Title ~= nil then
		self:SetTitle(paneOptions.Title)
	end
	if paneOptions.Subtitle ~= nil then
		self:SetSubtitle(paneOptions.Subtitle)
	end

	self:_guiPaneReady()

	return self
end

return ShopItemButtonPane
