--[[
	Author(s): Josh, Claude
	Module: ShopItemButtonPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local Maid = shared("Maid") ---@module Maid
local ShopItemButtonPane = shared("ShopItemButtonPane") ---@module ShopItemButtonPane

local StoryMaid = Maid.new()

local function create(target)
	local pane = ShopItemButtonPane.new({
		Title = "2x Cash",
		Subtitle = "Double every sell, forever!",
		Accent = GuiStyles.Colors.Buttons.Purple,
	})
	pane:_guiPaneStory(target)
	pane:_guiPaneStorySignals()
	StoryMaid:Add(pane)

	--	Toggle owned state to preview both looks.
	StoryMaid:Add(task.spawn(function()
		local owned = false
		while true do
			task.wait(3)
			owned = not owned
			pane:SetOwned(owned)
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
