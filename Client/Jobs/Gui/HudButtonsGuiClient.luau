--[[
	Author(s): Josh, Claude
	Module: HudButtonsGuiClient.luau
]]

-- Modules

local DataClient = shared("DataClient") ---@module DataClient
local FormatUtil = shared("FormatUtil") ---@module FormatUtil
local GameConfig = shared("GameConfig") ---@module GameConfig
local GetRemote = shared("GetRemote") ---@module GetRemote
local HudSideButtonsPane = shared("HudSideButtonsPane") ---@module HudSideButtonsPane
local ScreenGuisClient = shared("ScreenGuisClient") ---@module ScreenGuisClient
local UIStateManager = shared("UIStateManager") ---@module UIStateManager

-- Constants

local HUD_DISPLAY_ORDER = 10

-- Variables

local HudButtonsGuiClient = {}

local RebirthRemote = GetRemote("RebirthServer:Rebirth")

-- Private functions

local function toggleState(stateName: string)
	if UIStateManager:GetState() == stateName then
		UIStateManager:SetDefault()
	else
		UIStateManager:SetState(stateName)
	end
end

-- Start

function HudButtonsGuiClient:Run()
	local screenGui = ScreenGuisClient:Create({
		Name = "Hud",
		DisplayOrder = HUD_DISPLAY_ORDER,
		Enabled = true,
	})

	local pane = HudSideButtonsPane.new()
	pane:SetGuiProperties({ Parent = screenGui })

	UIStateManager:RegisterComponent("HUD_SideButtons", pane)

	pane.Maid:Add(pane.UpgradesActivated:Connect(function()
		toggleState("Upgrades")
	end))
	pane.Maid:Add(pane.ShopActivated:Connect(function()
		toggleState("Shop")
	end))
	pane.Maid:Add(pane.RebirthActivated:Connect(function()
		RebirthRemote:FireServer()
	end))

	pane.Maid:Add(UIStateManager.StateChanged:Connect(function(stateName: string)
		pane:SetUpgradesChosen(stateName == "Upgrades")
		pane:SetShopChosen(stateName == "Shop")
	end))

	local replica = DataClient:WaitForReplica()

	local function refreshRebirthCost()
		local rebirthCost = GameConfig.getRebirthCost(replica.Data.Rebirths)
		pane:SetRebirthCostText(FormatUtil:FormatCash(rebirthCost))
	end

	refreshRebirthCost()
	replica:ListenToChange({ "Rebirths" }, refreshRebirthCost)
end

return HudButtonsGuiClient
