--[[
	Author(s): Gory
	Module: GuiUtils.luau
--]]

local GuiPane ---@module GuiPane
local GuiStyles = shared("GuiStyles") ---@module GuiStyles

local GuiUtils = {}

local RandomObject = Random.new()

function GuiUtils:ConnectGuiEnabled(gui: ScreenGui, pane: GuiPane.GuiPane)
	pane.Dumpster:Add(pane.SpringSet.Updated:Connect(function(values)
		local alpha = values.Alpha
		if alpha then
			gui.Enabled = alpha < 1
		end
	end))
	gui.Enabled = pane.SpringSet:GetPosition("Alpha") < 1
end

function GuiUtils:StyleButton(
	button: {
		_base: ImageLabel,
		_bevelStroke: UIStroke,
		_color: Color3,
		_iconLabel: ImageLabel,
		_spotlight: ImageLabel,
		_textLabel: TextLabel,
		_textLabelStroek: UIStroke,
		_top: Frame,
		_topBase: ImageLabel,
	},
	values: {
		Alpha: number,
		Chosen: number,
		Enabled: number,
		Highlight: number,
		Press: number,
	}
)
	local disabled = 1 - values.Enabled
	local highlightNotPress = values.Highlight - values.Press
	local alphaOrDisabled = math.max(values.Alpha, disabled)

	button._base.ImageTransparency = values.Alpha
	button._bevelStroke.Transparency = 0.8 + 0.2 * values.Alpha
	button._topBase.ImageTransparency = values.Alpha
	button._iconLabel.ImageTransparency = values.Alpha + 0.66 * disabled
	button._textLabel.TextTransparency = values.Alpha + 0.66 * disabled
	button._textLabelStroke.Transparency = alphaOrDisabled

	button._spotlight.ImageTransparency = 0.85 + 0.15 * values.Alpha - 0.12 * highlightNotPress - 0.4 * values.Chosen

	button._top.Position = UDim2.fromOffset(0, -2 * highlightNotPress + 4 * values.Press)
	button._topBase.ImageColor3 =
		button._color:Lerp(GuiStyles.Colors.Black, 0.2 * values.Press):Lerp(GuiStyles.Colors.Disabled, disabled)
end

function GuiUtils:RandomRadialPosition(offsetMin: number?, offsetMax: number?): UDim2
	offsetMin = offsetMin or 0
	offsetMax = offsetMax or 0.5
	local angle = RandomObject:NextNumber(0, 2 * math.pi)
	local offset = RandomObject:NextNumber(offsetMin, offsetMax)
	local position = UDim2.fromScale(0.5 + math.cos(angle) * offset, 0.5 + math.sin(angle) * offset)
	return position
end

function GuiUtils:MergeAlpha(...: number): number
	local opacity = 1
	for index, alpha in { ... } do
		opacity *= (1 - alpha)
	end
	return 1 - opacity
end

return GuiUtils
