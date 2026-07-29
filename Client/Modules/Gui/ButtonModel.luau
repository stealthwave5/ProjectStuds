--[[
	Author(s): Gory
	Module: ButtonModel.luau
--]]

local GuiService = game:GetService("GuiService")

local Maid = shared("Maid") ---@module Maid
local Signal = shared("Signal") ---@module Signal

local ButtonModel = {}
ButtonModel.__index = ButtonModel
ButtonModel.ClassName = "ButtonModel"

export type ButtonModel = {
	IsHighlighted: (self: ButtonModel) -> boolean,
	IsInteractionEnabled: (self: ButtonModel) -> boolean,
	IsPressed: (self: ButtonModel) -> boolean,
	ResetButton: (self: ButtonModel, doNotAnimate: boolean?) -> (),
	SetInteractionEnabled: (self: ButtonModel, interactionEnabled: boolean, doNotAnimate: boolean?) -> (),
	SetKeyPressed: (self: ButtonModel, keyPressed: boolean, doNotAnimate: boolean?) -> (),
	Activated: Signal.Signal,
	ButtonSurface: ImageButton,
	SurfaceActive: boolean,
	TouchInsEnabled: boolean,
	EnabledChanged: Signal.Signal<boolean, boolean?>,
	PressedChanged: Signal.Signal<boolean, boolean?>,
	HighlightedChanged: Signal.Signal<boolean, boolean?>,
}

function ButtonModel.new(options: {
	Gui: GuiBase2d,
	DeferredActivated: boolean?,
	MinimumSizeEnabled: boolean?,
	TouchInsEnabled: boolean?,
	TouchOutsEnabled: boolean?,
}): ButtonModel
	local self = setmetatable({}, ButtonModel)

	self._maid = Maid.new()
	self._interactionEnabled = false

	self.SurfaceActive = true
	self.TouchOutsEnabled = options.TouchOutsEnabled == true
	self.TouchInsEnabled = options.TouchInsEnabled == true
	self._numberTouches = 0
	self._touchMaids = {}

	self.Activated = self._maid:Add(Signal.new()) :: Signal.Signal
	self.HighlightedChanged = self._maid:Add(Signal.new()) :: Signal.Signal<boolean, boolean?>
	self.PressedChanged = self._maid:Add(Signal.new()) :: Signal.Signal<boolean, boolean?>

	self:ResetButton(true)

	self._buttonSurface = self._maid:Add(Instance.new("ImageButton")) :: ImageButton
	self._buttonSurface.Name = "ButtonSurface"
	self._buttonSurface.AutoButtonColor = false
	self._buttonSurface.Active = false
	self._buttonSurface.Visible = true
	self._buttonSurface.Interactable = false
	self._buttonSurface.Selectable = false
	self._buttonSurface.BackgroundTransparency = 1
	self._buttonSurface.ImageTransparency = 1
	self._buttonSurface.Image = ""
	self._buttonSurface.AnchorPoint = Vector2.new(0.5, 0.5)
	self._buttonSurface.Position = UDim2.fromScale(0.5, 0.5)
	self._buttonSurface.Size = UDim2.fromScale(1, 1)
	self._buttonSurface.ZIndex = 8
	--	M3 minimum surface size.
	if options.MinimumSizeEnabled == true then
		self._sizeConstraint = self._maid:Add(Instance.new("UISizeConstraint"))
		self._sizeConstraint.MinSize = Vector2.new(48, 48)
		self._sizeConstraint.Parent = self._buttonSurface
	end
	self._buttonSurface.Parent = options.Gui
	self.ButtonSurface = self._buttonSurface
	self._deferredActivated = options.DeferredActivated ~= false

	self._maid:Add(self._buttonSurface.InputBegan:Connect(function(input)
		self:_onInputBegan(input)
	end))
	self._maid:Add(self._buttonSurface.InputEnded:Connect(function(input)
		self:_onInputEnded(input)
	end))
	self._maid:Add(self._buttonSurface.SelectionGained:Connect(function()
		self:_onSelectionChanged(true)
	end))
	self._maid:Add(self._buttonSurface.SelectionLost:Connect(function()
		self:_onSelectionChanged(false)
	end))
	self._maid:Add(self._buttonSurface.Activated:Connect(function()
		self:_onActivated()
	end))

	return self
end

function ButtonModel:IsHighlighted(): boolean
	return self._highlighted
end

function ButtonModel:IsInteractionEnabled(): boolean
	return self._interactionEnabled
end

function ButtonModel:IsPressed(): boolean
	return self._pressed
end

function ButtonModel:ResetButton(doNotAnimate: boolean?)
	self._mouseHovered = false
	self._mousePressed = false
	self._touchPressed = false
	self._keyPressed = false
	self._selected = false

	if GuiService.SelectedObject == self._buttonSurface then
		GuiService.SelectedObject = nil
	end

	self:_updateState(doNotAnimate)
end

function ButtonModel:SetInteractionEnabled(interactionEnabled: boolean, doNotAnimate: boolean?)
	if self._interactionEnabled == interactionEnabled then
		return
	end
	self._interactionEnabled = interactionEnabled
	if interactionEnabled == false then
		self:ResetButton(doNotAnimate)
	end
	self:_updateSurface()
end

function ButtonModel:SetKeyPressed(isKeyPressed: boolean, doNotAnimate: boolean?)
	if self._keyPressed == isKeyPressed then
		return
	end
	self._keyPressed = isKeyPressed
	self:_updateState(doNotAnimate)

	--	Bring this back if you want key presses to trigger buttons, not just in style.
	-- if isKeyPressed and self._interactionEnabled then
	-- 	self:_onActivated()
	-- end
end

function ButtonModel:_updateState(doNotAnimate: boolean?)
	local isPressed = self._mousePressed or (self._numberTouches > 0) or self._keyPressed
	local isHighlighted = self._selected or self._mouseHovered or isPressed
	if self._highlighted ~= isHighlighted then
		self._highlighted = isHighlighted
		self.HighlightedChanged:Fire(isHighlighted, doNotAnimate)
	end
	if self._pressed ~= isPressed then
		self._pressed = isPressed
		self.PressedChanged:Fire(isPressed, doNotAnimate)
	end
end

function ButtonModel:_updateSurface()
	self._buttonSurface.Interactable = self._interactionEnabled
	self._buttonSurface.Active = self.SurfaceActive and self._interactionEnabled
	self._buttonSurface.Selectable = self._interactionEnabled
end

function ButtonModel:_onActivated()
	if self._deferredActivated then
		self.Activated:FireDeferred()
	else
		self.Activated:Fire()
	end
end

function ButtonModel:_onInputBegan(input: InputObject)
	local inputType = input.UserInputType
	if inputType == Enum.UserInputType.MouseMovement then
		self._mouseHovered = true
	elseif inputType == Enum.UserInputType.MouseButton1 then
		self._mousePressed = true
	elseif inputType == Enum.UserInputType.Touch then
		self:_trackTouch(input)
	else
		return
	end
	self:_updateState()
end

function ButtonModel:_onInputEnded(input: InputObject)
	local inputType = input.UserInputType
	if inputType == Enum.UserInputType.MouseMovement then
		self._mouseHovered = false
	elseif inputType == Enum.UserInputType.MouseButton1 then
		self._mousePressed = false
	elseif inputType == Enum.UserInputType.Touch then
		if self.TouchOutsEnabled ~= true then
			self:_stopTrackingTouch(input)
		end
	else
		return
	end
	self:_updateState()
end

function ButtonModel:_trackTouch(input: InputObject)
	if self.TouchInsEnabled ~= true and input.UserInputState ~= Enum.UserInputState.Begin then
		return
	end
	local touchMaid = Maid.new()
	touchMaid:Add(function()
		if self._destroyed == nil then
			self._numberTouches -= 1
			self:_updateState()
		end
	end)
	touchMaid:Add(input:GetPropertyChangedSignal("UserInputState"):Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			self:_stopTrackingTouch(input)
		end
	end))
	self._maid[input] = touchMaid
	self._numberTouches += 1
end

function ButtonModel:_stopTrackingTouch(input: InputObject)
	self._maid[input] = nil
end

function ButtonModel:_onSelectionChanged(isSelected: boolean)
	self._selected = isSelected
	self:_updateState()
end

function ButtonModel:Destroy()
	self._destroyed = true
	self._maid:Destroy()
end

return ButtonModel
