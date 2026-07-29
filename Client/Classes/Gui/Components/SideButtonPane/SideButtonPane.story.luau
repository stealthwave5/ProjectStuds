--[[
	Author(s): Josh, Claude
	Module: SideButtonPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local FormatUtil = shared("FormatUtil") ---@module FormatUtil
local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local Maid = shared("Maid") ---@module Maid
local SideButtonPane = shared("SideButtonPane") ---@module SideButtonPane

local StoryMaid = Maid.new()

local function create(target)
	local pane = SideButtonPane.new({
		Icon = "⭐",
		Title = "Rebirth",
		Accent = GuiStyles.Colors.Buttons.Purple,
		CostLineEnabled = true,
	})
	pane:_guiPaneStory(target)
	pane:_guiPaneStorySignals()
	StoryMaid:Add(pane)

	pane:SetCostText(FormatUtil:FormatCash(10000))
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
