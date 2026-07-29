--[[
	Author(s): Gory
	Module: GuiButtonPane.luau
]]

local UserInputService = game:GetService("UserInputService")

local AccelTween = shared("AccelTween") ---@module AccelTween
local ButtonModel = shared("ButtonModel") ---@module ButtonModel
local Signal = shared("Signal") ---@module Signal

local GuiPane = shared("GuiPane") ---@module GuiPane
local GuiButtonPane = setmetatable({}, GuiPane)
GuiButtonPane.__index = GuiButtonPane
GuiButtonPane.ClassName = "GuiButtonPane"

export type GuiButtonPane = GuiPane.GuiPane & {
	-- Type
	IsChosen: (self: GuiButtonPane) -> boolean,
	IsEnabled: (self: GuiButtonPane) -> boolean,
	IsHighlighted: (self: GuiButtonPane) -> boolean,
	IsPressed: (self: GuiButtonPane) -> boolean,
	ResetButton: (self: GuiButtonPane, doNotAnimate: boolean?) -> (),
	SetButtonSurfaceProperties: (self: GuiButtonPane, properties: { [string]: any }) -> (),
	SetButtonSounds: (
		self: GuiButtonPane,
		soundNames: {
			Highlighted: string?,
			HighlightedVolume: number?,
			Pressed: string?,
			PressedVolume: number?,
		}
	) -> (),
	SetChosen: (self: GuiButtonPane, chosen: boolean, doNotAnimate: boolean?) -> (),
	SetEnabled: (self: GuiButtonPane, enabled: boolean, doNotAnimate: boolean?) -> (),
	SetKeyPressed: (self: GuiButtonPane, keyPressed: boolean, doNotAnimate: boolean?) -> (),
	SetInteractionEnabled: (self: GuiButtonPane, interactionEnabled: boolean, doNotAnimate: boolean?) -> (),
	_updateGui: (
		self: GuiButtonPane,
		values: { Alpha: number, Enabled: number, Highlight: number, Press: number },
		velocities: { Alpha: number, Enabled: number, Highlight: number, Press: number }
	) -> (),

	Activated: Signal.Signal,
	ChosenChanged: Signal.Signal<boolean, boolean?>,
	EnabledChanged: Signal.Signal<boolean, boolean?>,
	HighlightedChanged: Signal.Signal<boolean, boolean?>,
	PressedChanged: Signal.Signal<boolean, boolean?>,

	ButtonSurface: ImageButton,
	_buttonModel: ButtonModel.ButtonModel,
	_buttonSoundHighlighted: string?,
	_buttonSoundPressed: string?,
}

function GuiButtonPane.new(options: GuiPane.GuiPaneOptions & {
	MinimumSizeEnabled: boolean,
}): GuiButtonPane
	local self = setmetatable(GuiPane.new(options), GuiButtonPane)

	self._buttonChosen = false
	self._buttonEnabled = true
	self._buttonInteractionEnabled = true

	self._buttonSoundHighlighted = "UI.Hover"
	self._buttonSoundVolumeHighlighted = 0.125
	self._buttonSoundPressed = "UI.Click"
	self._buttonSoundVolumePressed = 0.2
	self._buttonModel = self.Maid:Add(ButtonModel.new({
		Gui = self.Gui,
		MinimumSizeEnabled = options.MinimumSizeEnabled,
	})) :: ButtonModel.ButtonModel
	self.ButtonSurface = self._buttonModel.ButtonSurface

	self.Activated = self._buttonModel.Activated
	self.ChosenChanged = self.Maid:Add(Signal.new()) :: Signal.Signal<boolean, boolean?>
	self.EnabledChanged = self.Maid:Add(Signal.new()) :: Signal.Signal<boolean, boolean?>
	self.HighlightedChanged = self._buttonModel.HighlightedChanged
	self.PressedChanged = self._buttonModel.PressedChanged

	self.Maid:Add(self.HighlightedChanged:Connect(function(highlighted: boolean, doNotAnimate: boolean?)
		self:_buttonHighlighted(highlighted, doNotAnimate)
	end))
	self.Maid:Add(self.PressedChanged:Connect(function(pressed: boolean, doNotAnimate: boolean?)
		self:_buttonPressed(pressed, doNotAnimate)
	end))
	self.Maid:Add(self.VisibleChanged:Connect(function(visible: boolean, doNotAnimate: boolean?)
		self:_updateButtonInteractionEnabled(true)
	end))
	self:_updateButtonInteractionEnabled()

	self._springSet:AddMany({
		Chosen = AccelTween.new(200, 0),
		Enabled = AccelTween.new(200, 1),
		Highlight = AccelTween.new(400, 0),
		Press = AccelTween.new(1_000, 0),
	})

	return self
end

function GuiButtonPane:IsChosen()
	return self._buttonChosen == true
end

function GuiButtonPane:IsEnabled(): boolean
	return self._buttonEnabled == true
end

function GuiButtonPane:IsHighlighted()
	return self._buttonModel:IsHighlighted()
end

function GuiButtonPane:IsPressed()
	return self._buttonModel:IsPressed()
end

function GuiButtonPane:ResetButton(doNotAnimate: boolean?)
	self._buttonModel:ResetButton(doNotAnimate)
end

function GuiButtonPane:SetButtonSurfaceProperties(properties: { [string]: any })
	for property, value in properties do
		self.ButtonSurface[property] = value
	end
end

function GuiButtonPane:SetButtonSounds(soundNames: {
	Highlighted: string?,
	HighlightedVolume: number?,
	Pressed: string?,
	PressedVolume: number?,
})
	if soundNames.Highlighted ~= nil then
		self._buttonSoundHighlighted = soundNames.Highlighted
	end
	if soundNames.HighlightedVolume ~= nil then
		self._buttonSoundVolumeHighlighted = soundNames.HighlightedVolume
	end
	if soundNames.Pressed ~= nil then
		self._buttonSoundPressed = soundNames.Pressed
	end
	if soundNames.PressedVolume ~= nil then
		self._buttonSoundVolumePressed = soundNames.PressedVolume
	end
end

function GuiButtonPane:SetChosen(chosen: boolean, doNotAnimate: boolean?)
	if self._buttonChosen == chosen then
		return
	end
	self._buttonChosen = chosen
	self._springSet:SetTarget("Chosen", chosen, doNotAnimate or self._visible == false)
	self.ChosenChanged:Fire(chosen, doNotAnimate)
end

function GuiButtonPane:SetEnabled(enabled: boolean, doNotAnimate: boolean?)
	if self._buttonEnabled == enabled then
		return
	end
	self._buttonEnabled = enabled
	self._springSet:SetTarget("Enabled", enabled, doNotAnimate or self._visible == false)
	self:_updateButtonInteractionEnabled(doNotAnimate)
	self.EnabledChanged:Fire(enabled, doNotAnimate)
end

function GuiButtonPane:SetKeyPressed(keyPressed: boolean, doNotAnimate: boolean?)
	self._buttonModel:SetKeyPressed(keyPressed)
end

function GuiButtonPane:SetInteractionEnabled(interactionEnabled: boolean, doNotAnimate: boolean?)
	self._buttonInteractionEnabled = interactionEnabled
	self:_updateButtonInteractionEnabled(doNotAnimate)
end

function GuiButtonPane:_buttonHighlighted(highlighted: boolean, doNotAnimate: boolean?)
	if self._buttonSoundHighlighted and highlighted and doNotAnimate ~= false then
		-- ClientSound:PlayOnce(self._buttonSoundHighlighted, {
		-- 	SoundGroup = SoundGroups:Get("Gui"),
		-- 	Volume = self._buttonSoundVolumeHighlighted,
		-- })
	end
	self._springSet:SetTarget("Highlight", highlighted, doNotAnimate)
end

function GuiButtonPane:_buttonPressed(pressed: boolean, doNotAnimate: boolean?)
	if self._buttonSoundPressed and pressed and doNotAnimate ~= false then
		-- ClientSound:PlayOnce(self._buttonSoundPressed, {
		-- 	SoundGroup = SoundGroups:Get("Gui"),
		-- 	Volume = self._buttonSoundVolumePressed,
		-- })
	end
	self._springSet:SetTarget("Press", pressed, doNotAnimate)
end

function GuiButtonPane:_updateButtonInteractionEnabled(doNotAnimate: boolean?)
	self._buttonModel:SetInteractionEnabled(
		self._visible and self._buttonEnabled and self._buttonInteractionEnabled,
		doNotAnimate
	)
end

function GuiButtonPane:_updateGui(values: {
	Alpha: number,
	Chosen: number,
	Enabled: number,
	Highlight: number,
	Press: number,
}) end

function GuiButtonPane:_guiPaneStory(target: Frame)
	self.Maid:Add(UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.B then
			self:SetEnabled(not self:IsEnabled())
		elseif input.KeyCode == Enum.KeyCode.N then
			self:SetChosen(not self:IsChosen())
		end
	end))
	GuiPane._guiPaneStory(self, target)
end

return GuiButtonPane
