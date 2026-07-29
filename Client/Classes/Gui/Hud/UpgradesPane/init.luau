--[[
	Author(s): Josh, Claude
	Module: UpgradesPane.luau
]]

-- Modules

local CloseButtonPane = shared("CloseButtonPane") ---@module CloseButtonPane
local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local Signal = shared("Signal") ---@module Signal
local UpgradeRowPane = shared("UpgradeRowPane") ---@module UpgradeRowPane

local GuiPane = shared("GuiPane") ---@module GuiPane
local UpgradesPane = setmetatable({}, GuiPane)
UpgradesPane.__index = UpgradesPane
UpgradesPane.ClassName = "UpgradesPane"

-- Types

export type UpgradeInfo = {
	Level: number,
	MaxLevel: number,
	Cost: number?,
	CanAfford: boolean?,
}

export type UpgradesPane = GuiPane.GuiPane & {
	CloseActivated: Signal.Signal,
	BuyActivated: Signal.Signal<string>,
	SetUpgrade: (self: UpgradesPane, upgradeName: string, info: UpgradeInfo) -> (),
	SetMessage: (self: UpgradesPane, messageText: string, ok: boolean) -> (),
}

-- Constants

local MESSAGE_CLEAR_SECONDS = 2.5
local SCALE_SPRING = { t = 0, s = 18, d = 0.55 }
local ROW_DEFINITIONS = {
	{ UpgradeName = "Speed", DisplayName = "Walk Speed", Icon = "⚡", AccentName = "Gold", LayoutOrder = 1 },
	{ UpgradeName = "Value", DisplayName = "Coin Value", Icon = "💎", AccentName = "Blue", LayoutOrder = 2 },
	{ UpgradeName = "Capacity", DisplayName = "Backpack", Icon = "🎒", AccentName = "Orange", LayoutOrder = 3 },
}

-- Public functions

function UpgradesPane:SetUpgrade(upgradeName: string, info: UpgradeInfo)
	local rowPane = self._rows[upgradeName]
	if rowPane == nil then
		warn(`[UpgradesPane] No row for upgrade "{upgradeName}".`)
		return
	end
	rowPane:SetLevel(info.Level, info.MaxLevel)
	rowPane:SetCost(info.Cost, info.CanAfford)
end

function UpgradesPane:SetMessage(messageText: string, ok: boolean)
	self._messageLabel.Text = messageText
	self._messageLabel.TextColor3 = GuiStyles.GetMessageColor(ok)
	self.Maid._messageClear = task.delay(MESSAGE_CLEAR_SECONDS, function()
		self._messageLabel.Text = ""
	end)
end

-- Private functions

function UpgradesPane:_updateGui(values: { Alpha: number, Scale: number })
	local shownAmount = 1 - values.Alpha
	local panelScale = math.max(values.Scale, 0)

	self._panel.Size = UDim2.fromScale(panelScale, panelScale)
	self._panel.BackgroundTransparency = values.Alpha
	self._panelStroke.Transparency = values.Alpha
	self._titleBar.BackgroundTransparency = values.Alpha
	self._titleLabel.TextTransparency = values.Alpha
	self._messageLabel.TextTransparency = values.Alpha
	self.Gui.Visible = shownAmount > 0.001
end

-- Constructor

function UpgradesPane.new(): UpgradesPane
	local self = setmetatable(
		GuiPane.new({
			Template = "UpgradesPaneTemplate",
			Instances = {
				_panel = "UpgradesPanel",
				_panelStroke = "UpgradesStroke",
				_titleBar = "UpgradesTitleBar",
				_titleLabel = "UpgradesTitle",
				_closeSlot = "UpgradesCloseSlot",
				_rowList = "UpgradesRowList",
				_messageLabel = "UpgradesMessage",
			},
		}),
		UpgradesPane
	)

	self:SetAlphaEnabled(true)

	self.CloseActivated = self.Maid:Add(Signal.new()) :: Signal.Signal
	self.BuyActivated = self.Maid:Add(Signal.new()) :: Signal.Signal<string>

	--	Underdamped scale spring gives the panel its springy open/close pop.
	self._springSet:AddSpring("Scale", SCALE_SPRING)

	self._closeButton = self.Maid:Add(CloseButtonPane.new()) :: CloseButtonPane.CloseButtonPane
	self._closeButton:SetGuiProperties({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Parent = self._closeSlot,
	})
	self.Maid:Add(self._closeButton.Activated:Connect(function()
		self.CloseActivated:Fire()
	end))

	self._rows = {} :: { [string]: UpgradeRowPane.UpgradeRowPane }
	for _, rowDefinition in ROW_DEFINITIONS do
		local rowPane = self.Maid:Add(UpgradeRowPane.new({
			UpgradeName = rowDefinition.UpgradeName,
			DisplayName = rowDefinition.DisplayName,
			Icon = rowDefinition.Icon,
			Accent = GuiStyles.Colors[rowDefinition.AccentName],
		})) :: UpgradeRowPane.UpgradeRowPane
		rowPane:SetGuiProperties({
			Size = UDim2.new(1, 0, 0, 72),
			LayoutOrder = rowDefinition.LayoutOrder,
			Parent = self._rowList,
		})
		self.Maid:Add(rowPane.BuyActivated:Connect(function(upgradeName: string)
			self.BuyActivated:Fire(upgradeName)
		end))
		self._rows[rowDefinition.UpgradeName] = rowPane
	end

	self.Maid:Add(self.VisibleChanged:Connect(function(visible: boolean, doNotAnimate: boolean?)
		self._springSet:SetTarget("Scale", if visible then 1 else 0, doNotAnimate)
		self._closeButton:SetVisible(visible, doNotAnimate)
		for _, rowPane in self._rows do
			rowPane:SetVisible(visible, doNotAnimate)
		end
		if not visible then
			self._messageLabel.Text = ""
		end
	end))

	self:_guiPaneReady()

	return self
end

return UpgradesPane
