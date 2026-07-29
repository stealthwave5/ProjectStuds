--[[
	Author(s): Josh, Claude
	Module: GuiStyles.luau
]]

-- Constants

local GuiStyles = {}

--	Simulator palette. Panes take ALL shared colors from here - never hardcode.
GuiStyles.Colors = {
	--	Core.
	Black = Color3.fromRGB(0, 0, 0),
	White = Color3.fromRGB(255, 255, 255),
	TextWhite = Color3.fromRGB(255, 255, 255),
	TextDark = Color3.fromRGB(44, 56, 86),
	Stroke = Color3.fromRGB(34, 44, 72),
	Disabled = Color3.fromRGB(158, 164, 176),

	--	Panels.
	Panel = Color3.fromRGB(247, 243, 234),
	PanelAlt = Color3.fromRGB(255, 255, 255),
	FillTrack = Color3.fromRGB(226, 220, 208),

	--	Accents.
	Green = Color3.fromRGB(86, 196, 72),
	Red = Color3.fromRGB(232, 72, 66),
	Blue = Color3.fromRGB(64, 156, 255),
	Orange = Color3.fromRGB(255, 146, 52),
	Purple = Color3.fromRGB(170, 96, 242),
	Gold = Color3.fromRGB(255, 200, 64),

	--	Button accents (referenced by button pane constructors).
	Buttons = {
		Green = Color3.fromRGB(86, 196, 72),
		Red = Color3.fromRGB(232, 72, 66),
		Blue = Color3.fromRGB(64, 156, 255),
		Orange = Color3.fromRGB(255, 146, 52),
		Purple = Color3.fromRGB(170, 96, 242),
		Gold = Color3.fromRGB(255, 200, 64),
	},
}

GuiStyles.Fonts = {
	Title = Enum.Font.FredokaOne,
	Icon = Enum.Font.GothamBlack,
	Number = Enum.Font.GothamBlack,
	Text = Enum.Font.GothamBold,
}

GuiStyles.Unicodes = {
	Robux = utf8.char(0xE002),
}

-- Public functions

---Returns the message color for an ok/fail result line.
function GuiStyles.GetMessageColor(ok: boolean): Color3
	return if ok then GuiStyles.Colors.Green else GuiStyles.Colors.Red
end

-- Types

export type GuiStyles = typeof(GuiStyles)

return GuiStyles
