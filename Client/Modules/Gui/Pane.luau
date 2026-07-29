--[[
	Author(s): Josh, Claude
	Module: Pane.luau

	Base class for all panes. GuiPane extends this; it only provides the
	inheritance root and class-name introspection.
]]

local Pane = {}
Pane.__index = Pane
Pane.ClassName = "Pane"

export type Pane = typeof(setmetatable({}, Pane))

function Pane.new(): Pane
	return setmetatable({}, Pane)
end

---Walks the metatable chain so `pane:IsA("GuiPane")` works for subclasses.
function Pane:IsA(className: string): boolean
	local classTable = getmetatable(self)
	while classTable ~= nil do
		if classTable.ClassName == className then
			return true
		end
		classTable = getmetatable(classTable)
	end
	return false
end

return Pane
