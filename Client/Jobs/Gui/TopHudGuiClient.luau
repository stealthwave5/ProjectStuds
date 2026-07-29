--[[
	Author(s): Josh, Claude
	Module: TopHudGuiClient.luau
]]

-- Services

local Players = game:GetService("Players")

-- Modules

local DataClient = shared("DataClient") ---@module DataClient
local GameConfig = shared("GameConfig") ---@module GameConfig
local ScreenGuisClient = shared("ScreenGuisClient") ---@module ScreenGuisClient
local TopHudPane = shared("TopHudPane") ---@module TopHudPane
local UIStateManager = shared("UIStateManager") ---@module UIStateManager

-- Constants

local HUD_DISPLAY_ORDER = 10

-- Variables

local TopHudGuiClient = {}

local Pane: TopHudPane.TopHudPane? = nil

-- Public functions

---Returns the live TopHudPane (nil until Run has created it). Used by
---NotificationsGuiClient to anchor +$ floats to the money pill.
function TopHudGuiClient:GetPane(): TopHudPane.TopHudPane?
	return Pane
end

-- Start

function TopHudGuiClient:Run()
	local screenGui = ScreenGuisClient:Create({
		Name = "Hud",
		DisplayOrder = HUD_DISPLAY_ORDER,
		Enabled = true,
	})

	local pane = TopHudPane.new()
	pane:SetGuiProperties({ Parent = screenGui })
	Pane = pane

	UIStateManager:RegisterComponent("HUD_TopHud", pane)

	local replica = DataClient:WaitForReplica()
	local localPlayer = Players.LocalPlayer

	local function refreshMoney()
		pane:SetMoney(replica.Data.Money)
	end

	local function refreshBackpack()
		local capacity = GameConfig.getCapacity(replica.Data.Upgrades.Capacity)
		pane:SetBackpack(replica.Data.Carried, capacity)
	end

	local function refreshRebirths()
		local rebirths = replica.Data.Rebirths
		local hasDoubleCash = localPlayer:GetAttribute("HasDoubleCash") == true
		local cashMultiplier = (1 + rebirths) * (if hasDoubleCash then 2 else 1)
		pane:SetRebirths(rebirths, cashMultiplier)
	end

	refreshMoney()
	refreshBackpack()
	refreshRebirths()

	replica:ListenToChange({ "Money" }, refreshMoney)
	replica:ListenToChange({ "Carried" }, function(newCarried: number, oldCarried: number?)
		refreshBackpack()
		if oldCarried ~= nil and newCarried > oldCarried then
			pane:PopBackpack()
		end
	end)
	replica:ListenToChange({ "Upgrades", "Capacity" }, refreshBackpack)
	replica:ListenToChange({ "Rebirths" }, refreshRebirths)
	localPlayer:GetAttributeChangedSignal("HasDoubleCash"):Connect(refreshRebirths)
end

return TopHudGuiClient
