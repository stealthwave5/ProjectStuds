--[[
	Author(s): Josh, Claude
	Module: ShopGuiClient.luau
]]

-- Services

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- Modules

local FormatUtil = shared("FormatUtil") ---@module FormatUtil
local GameConfig = shared("GameConfig") ---@module GameConfig
local ScreenGuisClient = shared("ScreenGuisClient") ---@module ScreenGuisClient
local ShopPane = shared("ShopPane") ---@module ShopPane
local UIStateManager = shared("UIStateManager") ---@module UIStateManager

-- Types

type NormalizedProduct = {
	Id: number,
	Title: string,
	Subtitle: string,
}

-- Constants

local HUD_DISPLAY_ORDER = 10
local PASS_TITLE = "2x Cash"
local PASS_SUBTITLE = "Double every sell, forever!"
local NOT_SETUP_MESSAGE = "Not for sale yet - check back soon!"

-- Variables

local ShopGuiClient = {}

local NormalizedProducts: { NormalizedProduct } = {}

-- Private functions

local function normalizeProduct(productIndex: number, productConfig: GameConfig.CashProductConfig): NormalizedProduct
	local cashAmount = productConfig.amount
	local productName = productConfig.displayName or `Cash Pack {productIndex}`
	local subtitle = if cashAmount ~= nil then `+{FormatUtil:FormatLongCash(cashAmount)}` else ""
	return {
		Id = productConfig.productId or 0,
		Title = productName,
		Subtitle = subtitle,
	}
end

-- Start

function ShopGuiClient:Run()
	local screenGui = ScreenGuisClient:Create({
		Name = "Hud",
		DisplayOrder = HUD_DISPLAY_ORDER,
		Enabled = true,
	})

	local pane = ShopPane.new()
	pane:SetGuiProperties({ Parent = screenGui })

	UIStateManager:RegisterComponent("Panel_Shop", pane)

	local localPlayer = Players.LocalPlayer

	--	Featured 2x Cash pass.
	pane:SetPassInfo(PASS_TITLE, PASS_SUBTITLE)

	local function refreshPassOwned()
		pane:SetPassOwned(localPlayer:GetAttribute("HasDoubleCash") == true)
	end
	refreshPassOwned()
	pane.Maid:Add(localPlayer:GetAttributeChangedSignal("HasDoubleCash"):Connect(refreshPassOwned))

	--	Cash packs from GameConfig.
	NormalizedProducts = {}
	local productInfos = {} :: { ShopPane.ShopProductInfo }
	for productIndex, productConfig in GameConfig.CashProducts do
		local normalizedProduct = normalizeProduct(productIndex, productConfig)
		table.insert(NormalizedProducts, normalizedProduct)
		table.insert(productInfos, {
			Title = normalizedProduct.Title,
			Subtitle = normalizedProduct.Subtitle,
		})
	end
	pane:SetProducts(productInfos)

	pane.Maid:Add(pane.CloseActivated:Connect(function()
		UIStateManager:SetDefault()
	end))

	pane.Maid:Add(pane.PassActivated:Connect(function()
		local gamePassId = GameConfig.DoubleCashGamePassId
		if gamePassId == 0 then
			pane:SetMessage(NOT_SETUP_MESSAGE, false)
			return
		end
		MarketplaceService:PromptGamePassPurchase(localPlayer, gamePassId)
	end))

	pane.Maid:Add(pane.ProductActivated:Connect(function(productIndex: number)
		local normalizedProduct = NormalizedProducts[productIndex]
		if normalizedProduct == nil then
			return
		end
		if normalizedProduct.Id == 0 then
			pane:SetMessage(NOT_SETUP_MESSAGE, false)
			return
		end
		MarketplaceService:PromptProductPurchase(localPlayer, normalizedProduct.Id)
	end))
end

return ShopGuiClient
