--[[
	Author(s): Josh, Claude
	Module: BuyButtonPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local BuyButtonPane = shared("BuyButtonPane") ---@module BuyButtonPane
local Maid = shared("Maid") ---@module Maid

local StoryMaid = Maid.new()

local function create(target)
	local pane = BuyButtonPane.new()
	pane:_guiPaneStory(target)
	pane:_guiPaneStorySignals()
	StoryMaid:Add(pane)

	pane:SetCost(1250)

	--	Cycle cost → MAX to preview both states (B toggles Enabled, per GuiButtonPane story keys).
	StoryMaid:Add(task.spawn(function()
		while true do
			task.wait(3)
			pane:SetCost(nil)
			pane:SetEnabled(false)
			task.wait(3)
			pane:SetCost(1250)
			pane:SetEnabled(true)
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
