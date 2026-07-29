--[[
	Author(s): Josh, Claude
	Module: ShopPane.luau
]]

-- Modules

local CloseButtonPane = shared("CloseButtonPane") ---@module CloseButtonPane
local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local Maid = shared("Maid") ---@module Maid
local ShopItemButtonPane = shared("ShopItemButtonPane") ---@module ShopItemButtonPane
local Signal = shared("Signal") ---@module Signal

local GuiPane = shared("GuiPane") ---@module GuiPane
local ShopPane = setmetatable({}, GuiPane)
ShopPane.__index = ShopPane
ShopPane.ClassName = "ShopPane"

-- Types

export type ShopProductInfo = {
	Title: string,
	Subtitle: string,
}

export type ShopPane = GuiPane.GuiPane & {
	CloseActivated: Signal.Signal,
	PassActivated: Signal.Signal,
	ProductActivated: Signal.Signal<number>,
	SetPassInfo: (self: ShopPane, title: string, subtitle: string) -> (),
	SetPassOwned: (self: ShopPane, owned: boolean) -> (),
	SetProducts: (self: ShopPane, products: { ShopProductInfo }) -> (),
	SetMessage: (self: ShopPane, messageText: string, ok: boolean) -> (),
}

-- Constants

local MESSAGE_CLEAR_SECONDS = 2.5
local SCALE_SPRING = { t = 0, s = 18, d = 0.55 }

-- Public functions

function ShopPane:SetPassInfo(title: string, subtitle: string)
	self._passButton:SetTitle(title)
	if not self._passButton:IsOwned() then
		self._passButton:SetSubtitle(subtitle)
	end
end

function ShopPane:SetPassOwned(owned: boolean)
	self._passButton:SetOwned(owned)
end

---Rebuilds the product buttons. Fires ProductActivated(productIndex) on press.
function ShopPane:SetProducts(products: { ShopProductInfo })
	local productsMaid = Maid.new()
	self.Maid._productsMaid = productsMaid
	self._productButtons = {}

	for productIndex, productInfo in products do
		local productButton = productsMaid:Add(ShopItemButtonPane.new({
			Title = productInfo.Title,
			Subtitle = productInfo.Subtitle,
			Accent = GuiStyles.Colors.Buttons.Green,
		})) :: ShopItemButtonPane.ShopItemButtonPane
		productButton:SetGuiProperties({
			LayoutOrder = productIndex,
			Parent = self._productRow,
		})
		productsMaid:Add(productButton.Activated:Connect(function()
			self.ProductActivated:Fire(productIndex)
		end))
		productButton:SetVisible(self:IsVisible(), true)
		table.insert(self._productButtons, productButton)
	end
end

function ShopPane:SetMessage(messageText: string, ok: boolean)
	self._messageLabel.Text = messageText
	self._messageLabel.TextColor3 = GuiStyles.GetMessageColor(ok)
	self.Maid._messageClear = task.delay(MESSAGE_CLEAR_SECONDS, function()
		self._messageLabel.Text = ""
	end)
end

-- Private functions

function ShopPane:_updateGui(values: { Alpha: number, Scale: number })
	local shownAmount = 1 - values.Alpha
	local panelScale = math.max(values.Scale, 0)

	self._panel.Size = UDim2.fromScale(panelScale, panelScale)
	self._panel.BackgroundTransparency = values.Alpha
	self._panelStroke.Transparency = values.Alpha
	self._titleBar.BackgroundTransparency = values.Alpha
	self._titleLabel.TextTransparency = values.Alpha
	self._sectionLabel.TextTransparency = values.Alpha
	self._messageLabel.TextTransparency = values.Alpha
	self.Gui.Visible = shownAmount > 0.001
end

-- Constructor

function ShopPane.new(): ShopPane
	local self = setmetatable(
		GuiPane.new({
			Template = "ShopPaneTemplate",
			Instances = {
				_panel = "ShopPanel",
				_panelStroke = "ShopStroke",
				_titleBar = "ShopTitleBar",
				_titleLabel = "ShopTitle",
				_closeSlot = "ShopCloseSlot",
				_featuredSlot = "ShopFeaturedSlot",
				_sectionLabel = "ShopSectionLabel",
				_productRow = "ShopProductRow",
				_messageLabel = "ShopMessage",
			},
		}),
		ShopPane
	)

	self:SetAlphaEnabled(true)

	self.CloseActivated = self.Maid:Add(Signal.new()) :: Signal.Signal
	self.PassActivated = self.Maid:Add(Signal.new()) :: Signal.Signal
	self.ProductActivated = self.Maid:Add(Signal.new()) :: Signal.Signal<number>

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

	self._passButton = self.Maid:Add(ShopItemButtonPane.new({
		Accent = GuiStyles.Colors.Buttons.Purple,
	})) :: ShopItemButtonPane.ShopItemButtonPane
	self._passButton:SetGuiProperties({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Parent = self._featuredSlot,
	})
	self.Maid:Add(self._passButton.Activated:Connect(function()
		self.PassActivated:Fire()
	end))

	self._productButtons = {} :: { ShopItemButtonPane.ShopItemButtonPane }

	self.Maid:Add(self.VisibleChanged:Connect(function(visible: boolean, doNotAnimate: boolean?)
		self._springSet:SetTarget("Scale", if visible then 1 else 0, doNotAnimate)
		self._closeButton:SetVisible(visible, doNotAnimate)
		self._passButton:SetVisible(visible, doNotAnimate)
		for _, productButton in self._productButtons do
			productButton:SetVisible(visible, doNotAnimate)
		end
		if not visible then
			self._messageLabel.Text = ""
		end
	end))

	self:_guiPaneReady()

	return self
end

return ShopPane
