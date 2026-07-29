--[[
	Author(s): Gory
	Module: GamepadUtils.luau
--]]

local GuiService = game:GetService("GuiService")

local GuiButtonPane ---@module GuiButtonPane
local LastInputClient = shared("LastInputClient") ---@module LastInputClient

local GamepadUtils = {}

local function surfaceOf(button: GuiButtonPane.GuiButtonPane): ImageButton
	return if button then button.ButtonSurface else nil
end

function GamepadUtils:ConnectHighlightToActivated(button: GuiButtonPane.GuiButtonPane)
	button.Dumpster:Add(button.HighlightedChanged:Connect(function(highlighted)
		if highlighted and button:IsEnabled() and LastInputClient:IsGamepad() then
			button.Activated:Fire()
		end
	end))
end

function GamepadUtils:SelectIfPreferred(gui: Instance)
	if LastInputClient:IsGamepad() then
		task.defer(self.SelectGui, self, gui)
		-- self:SelectGui(gui)
	end
end

function GamepadUtils:SelectGui(gui: Instance)
	GuiService:Select(gui)
end

function GamepadUtils:SelectButtonPane(button: GuiButtonPane.GuiButtonPane)
	GuiService:Select(button.ButtonSurface)
end

function GamepadUtils:LinkButtonPaneGrid(grid: { { GuiButtonPane.GuiButtonPane } })
	for i, row in grid do
		for j, button in row do
			local upButton = if grid[i - 1] then grid[i - 1][j] else nil
			local downButton = if grid[i + 1] then grid[i + 1][j] else nil
			local leftButton = row[j - 1]
			local rightButton = row[j + 1]

			button.ButtonSurface.NextSelectionLeft = surfaceOf(leftButton)
			button.ButtonSurface.NextSelectionRight = surfaceOf(rightButton)
			button.ButtonSurface.NextSelectionUp = surfaceOf(upButton)
			button.ButtonSurface.NextSelectionDown = surfaceOf(downButton)
		end
	end
end

function GamepadUtils:LinkButtonPaneListHorizontal(buttons: { GuiButtonPane.GuiButtonPane })
	for i, button in buttons do
		local prevButton = buttons[i - 1]
		local nextButton = buttons[i + 1]
		button.ButtonSurface.NextSelectionLeft = surfaceOf(prevButton)
		button.ButtonSurface.NextSelectionRight = surfaceOf(nextButton)
	end
end

function GamepadUtils:LinkButtonPaneListVertical(buttons: { GuiButtonPane.GuiButtonPane })
	for i, button in buttons do
		local prevButton = buttons[i - 1]
		local nextButton = buttons[i + 1]
		button.ButtonSurface.NextSelectionUp = surfaceOf(prevButton)
		button.ButtonSurface.NextSelectionDown = surfaceOf(nextButton)
	end
end

return GamepadUtils
