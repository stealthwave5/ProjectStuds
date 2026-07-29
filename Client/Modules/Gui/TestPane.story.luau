--[[
	Author(s): Gory
	Module: TestPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local Maid = shared("Maid") ---@module Maid
local TestPane = shared("TestPane") ---@module TestPane

local StoryMaid = Maid.new()

local function create(target)
	local pane = TestPane.new()
	pane:_guiPaneStory(target)
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
