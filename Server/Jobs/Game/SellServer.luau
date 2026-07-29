--[[
	Author(s): Josh, Claude
	Module: SellServer.luau
--]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Modules
local BackpackServer = shared("BackpackServer") ---@module BackpackServer
local GameConfig = shared("GameConfig") ---@module GameConfig
local GetRemote = shared("GetRemote") ---@module GetRemote
local PlayerDataServer = shared("PlayerDataServer") ---@module PlayerDataServer

-- Constants
local SELL_PAD_NAME = "SellPad"
local SELL_PAD_WAIT_TIMEOUT = 30

local SellServer = {}

-- Variables
local SoldRemote = GetRemote("SellServer:Sold")

-- Private functions

function SellServer:_getTouchPart(sellPad: Instance): BasePart?
	if sellPad:IsA("BasePart") then
		return sellPad
	end
	if sellPad:IsA("Model") then
		return sellPad.PrimaryPart or sellPad:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

function SellServer:_onSellPadTouched(otherPart: BasePart)
	local character = otherPart.Parent
	if character == nil then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if player == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then
		return
	end

	local replica = PlayerDataServer:GetReplica(player)
	if replica == nil or replica.Data.Carried <= 0 then
		return
	end

	local multiplier = GameConfig.getSellMultiplier(
		replica.Data.Upgrades.Value,
		replica.Data.Rebirths,
		player:GetAttribute("HasDoubleCash") == true
	)
	local units, baseValue = BackpackServer:TakeAll(player)
	local total = math.floor(baseValue * multiplier + 0.5)

	replica:SetValue({ "Money" }, replica.Data.Money + total)
	SoldRemote:FireClient(player, {
		total = total,
		units = units,
		baseValue = baseValue,
		multiplier = multiplier,
	})
end

-- Start

function SellServer:Run()
	local sellPad = Workspace:WaitForChild(SELL_PAD_NAME, SELL_PAD_WAIT_TIMEOUT)
	if sellPad == nil then
		warn(`[SellServer]: No {SELL_PAD_NAME} found in Workspace.`)
		return
	end
	local touchPart = self:_getTouchPart(sellPad)
	if touchPart == nil then
		warn(`[SellServer]: {SELL_PAD_NAME} has no touchable BasePart.`)
		return
	end
	touchPart.Touched:Connect(function(otherPart: BasePart)
		self:_onSellPadTouched(otherPart)
	end)
end

return SellServer
