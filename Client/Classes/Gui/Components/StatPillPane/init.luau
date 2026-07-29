--[[
	Author(s): Josh, Claude
	Module: StatPillPane.luau
]]

-- Services
local TextService = game:GetService("TextService")

-- Modules

local GuiStyles = shared("GuiStyles") ---@module GuiStyles

local GuiPane = shared("GuiPane") ---@module GuiPane
local StatPillPane = setmetatable({}, GuiPane)
StatPillPane.__index = StatPillPane
StatPillPane.ClassName = "StatPillPane"

-- Types

export type StatPillPaneOptions = {
	Icon: string?,
	Text: string?,
	Accent: Color3?,
}

export type StatPillPane = GuiPane.GuiPane & {
	SetIcon: (self: StatPillPane, icon: string) -> (),
	SetText: (self: StatPillPane, text: string) -> (),
	SetTextColor: (self: StatPillPane, textColor: Color3) -> (),
	SetAccent: (self: StatPillPane, accent: Color3) -> (),
	SetFill: (self: StatPillPane, fillRatio: number?) -> (),
	Pop: (self: StatPillPane) -> (),
}

-- Constants

local FILL_SPRING = { t = 0, s = 20, d = 1 }
local POP_SPRING = { t = 0, s = 30, d = 0.4 }
local POP_IMPULSE = 8
local POP_SCALE = 0.5
local FILL_TRACK_TRANSPARENCY = 0.35

--	Pill width follows the text so long values (e.g. "Rebirths: 12 (cash x26)") never overflow.
local TEXT_LEFT_OFFSET = 50
local TEXT_RIGHT_PADDING = 18
local MIN_PILL_WIDTH = 150
local TEXT_MEASURE_BOUNDS = Vector2.new(1000, 100)

-- Public functions

function StatPillPane:SetIcon(icon: string)
	self._iconLabel.Text = icon
end

function StatPillPane:SetText(text: string)
	self._textLabel.Text = text
	local textBounds = TextService:GetTextSize(text, self._textLabel.TextSize, self._textLabel.Font, TEXT_MEASURE_BOUNDS)
	local pillWidth = math.max(MIN_PILL_WIDTH, TEXT_LEFT_OFFSET + math.ceil(textBounds.X) + TEXT_RIGHT_PADDING)
	self.Gui.Size = UDim2.fromOffset(pillWidth, self.Gui.Size.Y.Offset)
end

function StatPillPane:SetTextColor(textColor: Color3)
	self._textLabel.TextColor3 = textColor
end

function StatPillPane:SetAccent(accent: Color3)
	self._accent = accent
	self._fillBar.BackgroundColor3 = accent
end

function StatPillPane:SetFill(fillRatio: number?)
	if fillRatio == nil then
		self._fillTrack.Visible = false
		return
	end
	self._fillTrack.Visible = true
	self._springSet:SetTarget("Fill", math.clamp(fillRatio, 0, 1))
end

function StatPillPane:Pop()
	self._springSet:Impulse("Pop", POP_IMPULSE)
end

-- Private functions

function StatPillPane:_updateGui(values: { Alpha: number, Fill: number, Pop: number })
	local shownAmount = 1 - values.Alpha
	local popScale = 1 + POP_SCALE * values.Pop
	local designScale = shownAmount * popScale

	self._design.Size = UDim2.fromScale(designScale, designScale)
	self._design.BackgroundTransparency = values.Alpha
	self._designStroke.Transparency = values.Alpha
	self._iconLabel.TextTransparency = values.Alpha
	self._textLabel.TextTransparency = values.Alpha
	self._fillTrack.BackgroundTransparency = FILL_TRACK_TRANSPARENCY + (1 - FILL_TRACK_TRANSPARENCY) * values.Alpha
	self._fillBar.BackgroundTransparency = values.Alpha
	self._fillBar.Size = UDim2.fromScale(math.clamp(values.Fill, 0, 1), 1)
	self.Gui.Visible = shownAmount > 0.001
end

-- Constructor

function StatPillPane.new(options: StatPillPaneOptions?): StatPillPane
	local paneOptions: StatPillPaneOptions = options or {}
	local self = setmetatable(
		GuiPane.new({
			Template = "StatPillPaneTemplate",
			Instances = {
				_design = "PillDesign",
				_designStroke = "PillStroke",
				_iconLabel = "PillIcon",
				_textLabel = "PillText",
				_fillTrack = "PillFillTrack",
				_fillBar = "PillFill",
			},
		}),
		StatPillPane
	)

	self:SetAlphaEnabled(true)

	self._springSet:AddMany({
		Fill = FILL_SPRING,
		Pop = POP_SPRING,
	})

	self._accent = paneOptions.Accent or GuiStyles.Colors.Green
	self._fillBar.BackgroundColor3 = self._accent
	self._fillTrack.Visible = false

	if paneOptions.Icon ~= nil then
		self:SetIcon(paneOptions.Icon)
	end
	if paneOptions.Text ~= nil then
		self:SetText(paneOptions.Text)
	end

	self:_guiPaneReady()

	return self
end

return StatPillPane
