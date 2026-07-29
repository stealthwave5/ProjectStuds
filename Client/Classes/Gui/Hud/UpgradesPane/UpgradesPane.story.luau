--[[
	Author(s): Josh, Claude
	Module: UpgradesPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local Maid = shared("Maid") ---@module Maid
local UpgradesPane = shared("UpgradesPane") ---@module UpgradesPane

local StoryMaid = Maid.new()

local function create(target)
	local pane = UpgradesPane.new()
	pane:_guiPaneStory(target)
	pane:_guiPaneStorySignals()
	StoryMaid:Add(pane)

	pane:SetUpgrade("Speed", { Level = 3, MaxLevel = 10, Cost = 410, CanAfford = true })
	pane:SetUpgrade("Value", { Level = 5, MaxLevel = 25, Cost = 3550, CanAfford = false })
	pane:SetUpgrade("Capacity", { Level = 20, MaxLevel = 20, Cost = nil })

	StoryMaid:Add(pane.BuyActivated:Connect(function(upgradeName)
		pane:SetMessage(`{upgradeName} upgraded!`, true)
	end))
	StoryMaid:Add(pane.CloseActivated:Connect(function()
		pane:SetMessage("Close pressed (toggle V to reopen)", false)
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
