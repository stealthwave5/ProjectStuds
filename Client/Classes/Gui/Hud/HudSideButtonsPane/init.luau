--[[
	Author(s): Josh, Claude
	Module: HudSideButtonsPane.luau
]]

-- Modules

local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local SideButtonPane = shared("SideButtonPane") ---@module SideButtonPane
local Signal = shared("Signal") ---@module Signal

local GuiPane = shared("GuiPane") ---@module GuiPane
local HudSideButtonsPane = setmetatable({}, GuiPane)
HudSideButtonsPane.__index = HudSideButtonsPane
HudSideButtonsPane.ClassName = "HudSideButtonsPane"

-- Types

export type HudSideButtonsPane = GuiPane.GuiPane & {
	UpgradesActivated: Signal.Signal,
	ShopActivated: Signal.Signal,
	RebirthActivated: Signal.Signal,
	SetRebirthCostText: (self: HudSideButtonsPane, costText: string?) -> (),
	SetUpgradesChosen: (self: HudSideButtonsPane, chosen: boolean) -> (),
	SetShopChosen: (self: HudSideButtonsPane, chosen: boolean) -> (),
}

-- Constants

local SLIDE_OFFSET = 64

-- Public functions

function HudSideButtonsPane:SetRebirthCostText(costText: string?)
	self._rebirthButton:SetCostText(costText)
end

function HudSideButtonsPane:SetUpgradesChosen(chosen: boolean)
	self._upgradesButton:SetChosen(chosen)
end

function HudSideButtonsPane:SetShopChosen(chosen: boolean)
	self._shopButton:SetChosen(chosen)
end

-- Private functions

function HudSideButtonsPane:_updateGui(values: { Alpha: number })
	local shownAmount = 1 - values.Alpha
	self.Gui.Position = self._basePosition + UDim2.fromOffset(-SLIDE_OFFSET * values.Alpha, 0)
	self.Gui.Visible = shownAmount > 0.001
end

-- Constructor

function HudSideButtonsPane.new(): HudSideButtonsPane
	local self = setmetatable(
		GuiPane.new({
			Template = "HudSideButtonsPaneTemplate",
			Instances = {
				_buttonList = "SideButtonList",
			},
		}),
		HudSideButtonsPane
	)

	self:SetAlphaEnabled(true)

	self._basePosition = self.Gui.Position

	self.UpgradesActivated = self.Maid:Add(Signal.new()) :: Signal.Signal
	self.ShopActivated = self.Maid:Add(Signal.new()) :: Signal.Signal
	self.RebirthActivated = self.Maid:Add(Signal.new()) :: Signal.Signal

	self._upgradesButton = self.Maid:Add(SideButtonPane.new({
		Icon = "📈",
		Title = "Upgrades",
		Accent = GuiStyles.Colors.Buttons.Blue,
	})) :: SideButtonPane.SideButtonPane
	self._upgradesButton:SetGuiProperties({
		LayoutOrder = 1,
		Parent = self._buttonList,
	})

	self._shopButton = self.Maid:Add(SideButtonPane.new({
		Icon = "🛒",
		Title = "Shop",
		Accent = GuiStyles.Colors.Buttons.Orange,
	})) :: SideButtonPane.SideButtonPane
	self._shopButton:SetGuiProperties({
		LayoutOrder = 2,
		Parent = self._buttonList,
	})

	self._rebirthButton = self.Maid:Add(SideButtonPane.new({
		Icon = "⭐",
		Title = "Rebirth",
		Accent = GuiStyles.Colors.Buttons.Purple,
		CostLineEnabled = true,
	})) :: SideButtonPane.SideButtonPane
	self._rebirthButton:SetGuiProperties({
		LayoutOrder = 3,
		Parent = self._buttonList,
	})

	self.Maid:Add(self._upgradesButton.Activated:Connect(function()
		self.UpgradesActivated:Fire()
	end))
	self.Maid:Add(self._shopButton.Activated:Connect(function()
		self.ShopActivated:Fire()
	end))
	self.Maid:Add(self._rebirthButton.Activated:Connect(function()
		self.RebirthActivated:Fire()
	end))

	self.Maid:Add(self.VisibleChanged:Connect(function(visible: boolean, doNotAnimate: boolean?)
		self._upgradesButton:SetVisible(visible, doNotAnimate)
		self._shopButton:SetVisible(visible, doNotAnimate)
		self._rebirthButton:SetVisible(visible, doNotAnimate)
	end))

	self:_guiPaneReady()

	return self
end

return HudSideButtonsPane
