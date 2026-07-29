--[[
	Author(s): Josh, Claude
	Module: TopHudPane.luau
]]

-- Modules

local FormatUtil = shared("FormatUtil") ---@module FormatUtil
local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local StatPillPane = shared("StatPillPane") ---@module StatPillPane

local GuiPane = shared("GuiPane") ---@module GuiPane
local TopHudPane = setmetatable({}, GuiPane)
TopHudPane.__index = TopHudPane
TopHudPane.ClassName = "TopHudPane"

-- Types

export type TopHudPane = GuiPane.GuiPane & {
	SetMoney: (self: TopHudPane, money: number) -> (),
	SetBackpack: (self: TopHudPane, carried: number, capacity: number) -> (),
	SetRebirths: (self: TopHudPane, rebirths: number, cashMultiplier: number) -> (),
	PopMoney: (self: TopHudPane) -> (),
	PopBackpack: (self: TopHudPane) -> (),
	GetMoneyPill: (self: TopHudPane) -> StatPillPane.StatPillPane,
}

-- Constants

local MONEY_ICON = "💰"
local BACKPACK_ICON = "🎒"
local REBIRTH_ICON = "⭐"
local SLIDE_OFFSET = 48

-- Public functions

function TopHudPane:SetMoney(money: number)
	self._moneyPill:SetText(FormatUtil:FormatLongCash(money))
end

function TopHudPane:SetBackpack(carried: number, capacity: number)
	local isFull = carried >= capacity
	if isFull then
		self._backpackPill:SetTextColor(GuiStyles.Colors.Red)
		self._backpackPill:SetAccent(GuiStyles.Colors.Red)
	else
		self._backpackPill:SetTextColor(GuiStyles.Colors.TextDark)
		self._backpackPill:SetAccent(GuiStyles.Colors.Green)
	end

	self._backpackPill:SetText(`{carried}/{capacity}`)
	self._backpackPill:SetFill(if capacity > 0 then carried / capacity else 0)
end

function TopHudPane:SetRebirths(rebirths: number, cashMultiplier: number)
	self._rebirthPill:SetText(`Rebirths: {rebirths} (cash x{cashMultiplier})`)
end

function TopHudPane:PopMoney()
	self._moneyPill:Pop()
end

function TopHudPane:PopBackpack()
	self._backpackPill:Pop()
end

---Returns the money pill, used by NotificationsGuiClient to anchor +$ floats.
function TopHudPane:GetMoneyPill(): StatPillPane.StatPillPane
	return self._moneyPill
end

-- Private functions

function TopHudPane:_updateGui(values: { Alpha: number })
	local shownAmount = 1 - values.Alpha
	self.Gui.Position = self._basePosition + UDim2.fromOffset(0, -SLIDE_OFFSET * values.Alpha)
	self.Gui.Visible = shownAmount > 0.001
end

-- Constructor

function TopHudPane.new(): TopHudPane
	local self = setmetatable(
		GuiPane.new({
			Template = "TopHudPaneTemplate",
			Instances = {
				_pillRow = "PillRow",
			},
		}),
		TopHudPane
	)

	self:SetAlphaEnabled(true)

	self._basePosition = self.Gui.Position

	self._moneyPill = self.Maid:Add(StatPillPane.new({
		Icon = MONEY_ICON,
		Text = FormatUtil:FormatLongCash(0),
		Accent = GuiStyles.Colors.Green,
	})) :: StatPillPane.StatPillPane
	self._moneyPill:SetGuiProperties({
		LayoutOrder = 1,
		Parent = self._pillRow,
	})

	self._backpackPill = self.Maid:Add(StatPillPane.new({
		Icon = BACKPACK_ICON,
		Accent = GuiStyles.Colors.Green,
	})) :: StatPillPane.StatPillPane
	self._backpackPill:SetGuiProperties({
		LayoutOrder = 2,
		Parent = self._pillRow,
	})

	self._rebirthPill = self.Maid:Add(StatPillPane.new({
		Icon = REBIRTH_ICON,
		Accent = GuiStyles.Colors.Purple,
	})) :: StatPillPane.StatPillPane
	self._rebirthPill:SetGuiProperties({
		LayoutOrder = 3,
		Parent = self._pillRow,
	})

	self:SetBackpack(0, 10)
	self:SetRebirths(0, 1)

	self.Maid:Add(self.VisibleChanged:Connect(function(visible: boolean, doNotAnimate: boolean?)
		self._moneyPill:SetVisible(visible, doNotAnimate)
		self._backpackPill:SetVisible(visible, doNotAnimate)
		self._rebirthPill:SetVisible(visible, doNotAnimate)
	end))

	self:_guiPaneReady()

	return self
end

return TopHudPane
