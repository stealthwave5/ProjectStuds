--[[
	Author(s): Josh, Claude
	Module: TransactionsServer.luau
--]]

-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- Modules
local GameConfig = shared("GameConfig") ---@module GameConfig
local PlayerAddedUtil = shared("PlayerAddedUtil") ---@module PlayerAddedUtil
local PlayerDataServer = shared("PlayerDataServer") ---@module PlayerDataServer

-- Constants
local RECEIPT_REPLICA_TIMEOUT = 10

local TransactionsServer = {}

-- Private functions

function TransactionsServer:_getCashProduct(productId: number): GameConfig.CashProductConfig?
	for _, product in GameConfig.CashProducts do
		if product.productId == productId then
			return product
		end
	end
	return nil
end

function TransactionsServer:_processReceipt(
	receiptInfo: { PlayerId: number, ProductId: number }
): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local product = self:_getCashProduct(receiptInfo.ProductId)
	if product == nil then
		warn(`[TransactionsServer]: Unknown product id {receiptInfo.ProductId}.`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local replica = PlayerDataServer:WaitForReplica(player, RECEIPT_REPLICA_TIMEOUT)
	if replica == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	replica:SetValue({ "Money" }, replica.Data.Money + product.amount)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function TransactionsServer:_onGamePassPurchaseFinished(player: Player, gamePassId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end
	if gamePassId == GameConfig.DoubleCashGamePassId then
		player:SetAttribute("HasDoubleCash", true)
	end
end

function TransactionsServer:_checkGamePassOwnership(player: Player)
	player:SetAttribute("HasDoubleCash", false)
	if GameConfig.DoubleCashGamePassId == 0 then
		return
	end
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.DoubleCashGamePassId)
	end)
	if success and owns == true then
		player:SetAttribute("HasDoubleCash", true)
	end
end

-- Start

function TransactionsServer:Run()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:_processReceipt(receiptInfo)
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, gamePassId: number, wasPurchased: boolean)
			self:_onGamePassPurchaseFinished(player, gamePassId, wasPurchased)
		end
	)
	PlayerAddedUtil:Connect({
		Added = function(player: Player)
			self:_checkGamePassOwnership(player)
		end,
	})
end

return TransactionsServer
