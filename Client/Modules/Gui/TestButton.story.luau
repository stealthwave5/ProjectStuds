--[[
	Author(s): Gory
	Module: TestButton.story.luau
]]

require(game.ReplicatedStorage.Kit)

local Maid = shared("Maid") ---@module Maid
local TestButton = shared("TestButton") ---@module TestButton

local StoryMaid = Maid.new()

local function Create(target)
	local pane = TestButton.new()
	pane:_guiPaneStory(target)
	StoryMaid:Add(pane)
end

local function Destroy()
	StoryMaid:Destroy()
end

return function(target)
	task.spawn(Create, target)
	return function()
		task.spawn(Destroy)
	end
end
