--[[
	Author(s): Josh, Claude
	Module: UpgradeRowPane.luau
]]

-- Modules

local BuyButtonPane = shared("BuyButtonPane") ---@module BuyButtonPane
local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local Signal = shared("Signal") ---@module Signal

local GuiPane = shared("GuiPane") ---@module GuiPane
local UpgradeRowPane = setmetatable({}, GuiPane)
UpgradeRowPane.__index = UpgradeRowPane
UpgradeRowPane.ClassName = "UpgradeRowPane"

-- Types

export type UpgradeRowPaneOptions = {
	UpgradeName: string,
	DisplayName: string,
	Icon: string,
	Accent: Color3?,
}

export type UpgradeRowPane = GuiPane.GuiPane & {
	UpgradeName: string,
	BuyActivated: Signal.Signal<string>,
	SetLevel: (self: UpgradeRowPane, level: number, maxLevel: number) -> (),
	SetCost: (self: UpgradeRowPane, cost: number?, canAfford: boolean?) -> (),
}

-- Constants

local PROGRESS_SPRING = { t = 0, s = 20, d = 1 }
local PROGRESS_TRACK_TRANSPARENCY = 0.35

-- Public functions

function UpgradeRowPane:SetLevel(level: number, maxLevel: number)
	self._levelLabel.Text = `Lv {level}/{maxLevel}`
	local progressRatio = if maxLevel > 0 then math.clamp(level / maxLevel, 0, 1) else 0
	self._springSet:SetTarget("Progress", progressRatio)
end

---Sets the buy button cost. Pass nil for the maxed (gray MAX) state.
function UpgradeRowPane:SetCost(cost: number?, canAfford: boolean?)
	self._buyButton:SetCost(cost)
	self._buyButton:SetEnabled(cost ~= nil and canAfford ~= false)
end

-- Private functions

function UpgradeRowPane:_updateGui(values: { Alpha: number, Progress: number })
	local shownAmount = 1 - values.Alpha

	self.Gui.BackgroundTransparency = values.Alpha
	self._iconBadge.BackgroundTransparency = values.Alpha
	self._iconLabel.TextTransparency = values.Alpha
	self._nameLabel.TextTransparency = values.Alpha
	self._levelLabel.TextTransparency = values.Alpha
	self._progressTrack.BackgroundTransparency = PROGRESS_TRACK_TRANSPARENCY
		+ (1 - PROGRESS_TRACK_TRANSPARENCY) * values.Alpha
	self._progressFill.BackgroundTransparency = values.Alpha
	self._progressFill.Size = UDim2.fromScale(math.clamp(values.Progress, 0, 1), 1)
	self.Gui.Visible = shownAmount > 0.001
end

-- Constructor

function UpgradeRowPane.new(options: UpgradeRowPaneOptions): UpgradeRowPane
	local self = setmetatable(
		GuiPane.new({
			Template = "UpgradeRowPaneTemplate",
			Instances = {
				_iconBadge = "RowIconBadge",
				_iconLabel = "RowIcon",
				_nameLabel = "RowName",
				_levelLabel = "RowLevel",
				_progressTrack = "RowProgressTrack",
				_progressFill = "RowProgressFill",
				_buySlot = "RowBuySlot",
			},
		}),
		UpgradeRowPane
	)

	self:SetAlphaEnabled(true)

	self.UpgradeName = options.UpgradeName
	self.BuyActivated = self.Maid:Add(Signal.new()) :: Signal.Signal<string>

	self._springSet:AddSpring("Progress", PROGRESS_SPRING)

	local accent = options.Accent or GuiStyles.Colors.Blue
	self._iconBadge.BackgroundColor3 = accent
	self._progressFill.BackgroundColor3 = accent
	self._iconLabel.Text = options.Icon
	self._nameLabel.Text = options.DisplayName

	self._buyButton = self.Maid:Add(BuyButtonPane.new()) :: BuyButtonPane.BuyButtonPane
	self._buyButton:SetGuiProperties({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Parent = self._buySlot,
	})

	self.Maid:Add(self._buyButton.Activated:Connect(function()
		self.BuyActivated:Fire(self.UpgradeName)
	end))
	self.Maid:Add(self.VisibleChanged:Connect(function(visible: boolean, doNotAnimate: boolean?)
		self._buyButton:SetVisible(visible, doNotAnimate)
	end))

	self:_guiPaneReady()

	return self
end

return UpgradeRowPane
