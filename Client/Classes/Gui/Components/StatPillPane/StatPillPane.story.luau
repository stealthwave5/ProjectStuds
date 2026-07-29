--[[
	Author(s): Josh, Claude
	Module: StatPillPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local Maid = shared("Maid") ---@module Maid
local StatPillPane = shared("StatPillPane") ---@module StatPillPane

local StoryMaid = Maid.new()

local function create(target)
	local pane = StatPillPane.new({
		Icon = "🎒",
		Text = "7/10  ($245)",
		Accent = GuiStyles.Colors.Green,
	})
	pane:_guiPaneStory(target)
	pane:_guiPaneStorySignals()
	StoryMaid:Add(pane)

	pane:SetFill(0.7)

	--	Pop every couple of seconds to preview the pickup impulse.
	StoryMaid:Add(task.spawn(function()
		while true do
			task.wait(2)
			pane:Pop()
		end
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
