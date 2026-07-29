--[[
	Author(s): Josh, Claude
	Module: HudSideButtonsPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local FormatUtil = shared("FormatUtil") ---@module FormatUtil
local HudSideButtonsPane = shared("HudSideButtonsPane") ---@module HudSideButtonsPane
local Maid = shared("Maid") ---@module Maid

local StoryMaid = Maid.new()

local function create(target)
	local pane = HudSideButtonsPane.new()
	pane:_guiPaneStory(target)
	pane:_guiPaneStorySignals()
	StoryMaid:Add(pane)

	pane:SetRebirthCostText(FormatUtil:FormatCash(10000))

	StoryMaid:Add(pane.UpgradesActivated:Connect(function()
		pane:SetUpgradesChosen(true)
		pane:SetShopChosen(false)
	end))
	StoryMaid:Add(pane.ShopActivated:Connect(function()
		pane:SetUpgradesChosen(false)
		pane:SetShopChosen(true)
	end))
	StoryMaid:Add(pane.RebirthActivated:Connect(function()
		pane:SetUpgradesChosen(false)
		pane:SetShopChosen(false)
	end))
end

local function destroy()
	StoryMaid:Destroy()
end

return function(target)
	task.spawn(create, target)
	return function()
		task.spawn(destroy)
	end
end
