--[[
	Author(s): Josh, Claude
	Module: ToastPane.story.luau
]]

require(game.ReplicatedStorage.Kit)

local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local Maid = shared("Maid") ---@module Maid
local ToastPane = shared("ToastPane") ---@module ToastPane

local StoryMaid = Maid.new()

local TOAST_EXAMPLES = {
	{ Text = "Backpack full! Need 4, only 1 free - SELL!", ColorName = "Red" },
	{ Text = "Rebirth! Cash multiplier increased!", ColorName = "Green" },
	{ Text = "You got robbed!", ColorName = "Red" },
}

local function create(target)
	local pane = ToastPane.new()
	pane:SetGuiProperties({ Parent = target })
	pane:_guiPaneStorySignals()
	StoryMaid:Add(pane)

	--	Cycle example toasts.
	StoryMaid:Add(task.spawn(function()
		local exampleIndex = 0
		while true do
			task.wait(2.5)
			exampleIndex = (exampleIndex % #TOAST_EXAMPLES) + 1
			local example = TOAST_EXAMPLES[exampleIndex]
			pane:SetText(example.Text)
			pane:SetColor(GuiStyles.Colors[example.ColorName])
			pane:Play()
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
