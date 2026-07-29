--[[
	Author(s): Josh, Claude
	Module: TopHudPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local Maid = shared("Maid") ---@module Maid
local TopHudPane = shared("TopHudPane") ---@module TopHudPane

local StoryMaid = Maid.new()

local function create(target)
	local pane = TopHudPane.new()
	pane:_guiPaneStory(target)
	pane:_guiPaneStorySignals()
	StoryMaid:Add(pane)

	pane:SetMoney(1234)
	pane:SetBackpack(7, 10)
	pane:SetRebirths(2, 3)

	--	Simulate pickups until full, then a sell.
	StoryMaid:Add(task.spawn(function()
		local carried = 7
		local money = 1234
		while true do
			task.wait(1.5)
			carried += 1
			if carried > 10 then
				carried = 0
				money += 245
				pane:SetMoney(money)
				pane:PopMoney()
			end
			pane:SetBackpack(carried, 10)
			pane:PopBackpack()
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
