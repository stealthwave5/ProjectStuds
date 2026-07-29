--[[
	Author(s): Josh, Claude
	Module: CloseButtonPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local CloseButtonPane = shared("CloseButtonPane") ---@module CloseButtonPane
local Maid = shared("Maid") ---@module Maid

local StoryMaid = Maid.new()

local function create(target)
	local pane = CloseButtonPane.new()
	pane:_guiPaneStory(target)
	pane:_guiPaneStorySignals()
	StoryMaid:Add(pane)
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
