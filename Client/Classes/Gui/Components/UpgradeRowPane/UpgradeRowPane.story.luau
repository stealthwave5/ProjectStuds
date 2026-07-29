--[[
	Author(s): Josh, Claude
	Module: UpgradeRowPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local Maid = shared("Maid") ---@module Maid
local UpgradeRowPane = shared("UpgradeRowPane") ---@module UpgradeRowPane

local StoryMaid = Maid.new()

local function create(target)
	local pane = UpgradeRowPane.new({
		UpgradeName = "Speed",
		DisplayName = "Speed",
		Icon = "⚡",
		Accent = GuiStyles.Colors.Gold,
	})
	pane:_guiPaneStory(target)
	pane:_guiPaneStorySignals()
	StoryMaid:Add(pane)

	pane:SetLevel(3, 10)
	pane:SetCost(410, true)

	--	Step levels to preview the progress spring and the MAX state.
	StoryMaid:Add(task.spawn(function()
		local level = 3
		while true do
			task.wait(2)
			level += 1
			if level > 10 then
				level = 0
			end
			pane:SetLevel(level, 10)
			if level >= 10 then
				pane:SetCost(nil)
			else
				pane:SetCost(100 * (level + 1), level % 2 == 0)
			end
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
