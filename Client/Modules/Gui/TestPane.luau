--[[
	Author(s): Gory
	Module: TestPane.luau
]]

local GuiPane = shared("GuiPane") ---@module GuiPane
local TestPane = setmetatable({}, GuiPane)
TestPane.__index = TestPane
TestPane.ClassName = "TestPane"

export type TestPane = GuiPane.GuiPane & {
	-- Type
}

function TestPane.new(): TestPane
	local self = setmetatable(
		GuiPane.new({
			Template = "TestPane",
			InstanceKeys = {
				-- Instances
			},
		}),
		TestPane
	)

	self:_guiPaneReady()

	return self
end

function TestPane:_updateGui(values: { Alpha: number })
	self.Gui.BackgroundTransparency = values.Alpha
end

return TestPane
