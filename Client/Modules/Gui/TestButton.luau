--[[
	Author(s): Gory
	Module: TestButton.luau
]]

local GuiButtonPane = shared("GuiButtonPane") ---@module GuiButtonPane
local TestButton = setmetatable({}, GuiButtonPane)
TestButton.__index = TestButton
TestButton.ClassName = "TestButton"

export type TestButton = GuiButtonPane.GuiButtonPane & {
	-- Type
}

function TestButton.new(): TestButton
	local self = setmetatable(
		GuiButtonPane.new({
			Template = "TestPane",
			InstanceKeys = {
				-- Instances
			},
		}),
		TestButton
	)

	self:_guiPaneReady()

	return self
end

function TestButton:_updateGui(values: {
	Alpha: number,
	Chosen: number,
	Enabled: number,
	Highlight: number,
	Press: number,
})
	-- Control alpha.
end

return TestButton
