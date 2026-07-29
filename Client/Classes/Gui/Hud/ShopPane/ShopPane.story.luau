--[[
	Author(s): Josh, Claude
	Module: ShopPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local Maid = shared("Maid") ---@module Maid
local ShopPane = shared("ShopPane") ---@module ShopPane

local StoryMaid = Maid.new()

local function create(target)
	local pane = ShopPane.new()
	pane:_guiPaneStory(target)
	pane:_guiPaneStorySignals()
	StoryMaid:Add(pane)

	pane:SetPassInfo("2x Cash", "Double every sell, forever!")
	pane:SetProducts({
		{ Title = "Small Cash Pack", Subtitle = "+$10,000" },
		{ Title = "Medium Cash Pack", Subtitle = "+$60,000" },
		{ Title = "Huge Cash Pack", Subtitle = "+$250,000" },
	})

	StoryMaid:Add(pane.PassActivated:Connect(function()
		pane:SetPassOwned(true)
		pane:SetMessage("2x Cash pass purchased!", true)
	end))
	StoryMaid:Add(pane.ProductActivated:Connect(function(productIndex)
		pane:SetMessage(`Product {productIndex} not for sale yet - check back soon!`, false)
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
