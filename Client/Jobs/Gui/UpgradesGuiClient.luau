--[[
	Author(s): Josh, Claude
	Module: UpgradesGuiClient.luau
]]

-- Modules

local DataClient = shared("DataClient") ---@module DataClient
local GameConfig = shared("GameConfig") ---@module GameConfig
local GetRemote = shared("GetRemote") ---@module GetRemote
local ScreenGuisClient = shared("ScreenGuisClient") ---@module ScreenGuisClient
local UIStateManager = shared("UIStateManager") ---@module UIStateManager
local UpgradesPane = shared("UpgradesPane") ---@module UpgradesPane

-- Constants

local HUD_DISPLAY_ORDER = 10
local UPGRADE_NAMES = { "Speed", "Value", "Capacity" }

-- Variables

local UpgradesGuiClient = {}

local BuyRemote = GetRemote("UpgradesServer:Buy")
local BuyResultRemote = GetRemote("UpgradesServer:BuyResult")

-- Start

function UpgradesGuiClient:Run()
	local screenGui = ScreenGuisClient:Create({
		Name = "Hud",
		DisplayOrder = HUD_DISPLAY_ORDER,
		Enabled = true,
	})

	local pane = UpgradesPane.new()
	pane:SetGuiProperties({ Parent = screenGui })

	UIStateManager:RegisterComponent("Panel_Upgrades", pane)

	pane.Maid:Add(pane.CloseActivated:Connect(function()
		UIStateManager:SetDefault()
	end))
	pane.Maid:Add(pane.BuyActivated:Connect(function(upgradeName: string)
		BuyRemote:FireServer(upgradeName)
	end))

	BuyResultRemote:OnClientEvent(function(result: { ok: boolean, msg: string, upgradeName: string? })
		pane:SetMessage(result.msg, result.ok)
	end)

	local replica = DataClient:WaitForReplica()

	local function refreshUpgrade(upgradeName: string)
		local upgradeConfig = GameConfig.Upgrades[upgradeName]
		if upgradeConfig == nil then
			warn(`[UpgradesGuiClient] No GameConfig.Upgrades entry for "{upgradeName}".`)
			return
		end
		local level = replica.Data.Upgrades[upgradeName]
		local maxLevel = upgradeConfig.maxLevel
		local isMaxed = level >= maxLevel
		local cost = if isMaxed then nil else GameConfig.getUpgradeCost(upgradeName, level)
		local canAfford = cost ~= nil and replica.Data.Money >= cost
		pane:SetUpgrade(upgradeName, {
			Level = level,
			MaxLevel = maxLevel,
			Cost = cost,
			CanAfford = canAfford,
		})
	end

	local function refreshAllUpgrades()
		for _, upgradeName in UPGRADE_NAMES do
			refreshUpgrade(upgradeName)
		end
	end

	refreshAllUpgrades()

	for _, upgradeName in UPGRADE_NAMES do
		replica:ListenToChange({ "Upgrades", upgradeName }, function()
			refreshUpgrade(upgradeName)
		end)
	end
	replica:ListenToChange({ "Money" }, refreshAllUpgrades)
end

return UpgradesGuiClient
