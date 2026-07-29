--[[
	Author(s): Gory
	Module: GuiPane.luau
]]

local UserInputService = game:GetService("UserInputService")

local AccelTween = shared("AccelTween") ---@module AccelTween
local Assets = shared("Assets") ---@module Assets
local Maid = shared("Maid") ---@module Maid
local Signal = shared("Signal") ---@module Signal
local SpringSet = shared("SpringSet") ---@module SpringSet

local Pane = shared("Pane") ---@module Pane
local GuiPane = setmetatable({}, Pane)
GuiPane.__index = GuiPane
GuiPane.ClassName = "GuiPane"

export type GuiPane = {
	Destroy: (self: GuiPane) -> (),
	IsAlphaEnabled: (self: GuiPane) -> boolean,
	IsVisible: (self: GuiPane) -> boolean,
	SetAlphaEnabled: (self: GuiPane, alphaEnabled: boolean) -> (),
	SetVisible: (self: GuiPane, visible: boolean, doNotAnimate: boolean?) -> (),
	SetGuiProperties: (self: GuiPane, properties: { [string]: any }) -> (),
	Toggle: (self: GuiPane, doNotAnimate: boolean?) -> (),
	_updateGui: (
		self: GuiPane,
		values: { Alpha: number, [string]: number },
		velocities: { Alpha: number, [string]: number }
	) -> (),
	VisibleChanged: Signal.Signal<boolean>,
	Maid: Maid.Maid,
	Gui: GuiBase2d,
	SpringSet: SpringSet.SpringSet,
	_visible: boolean,
	_springSet: SpringSet.SpringSet,
}

export type GuiPaneOptions = {
	Template: Instance | string,
	Instances: {
		[string]: string,
	}?,
	AllInstances: boolean?,
}

function GuiPane.new(options: GuiPaneOptions)
	local self = setmetatable({}, GuiPane)

	self.Maid = Maid.new()

	self.VisibleChanged = Signal.new() :: Signal.Signal<boolean, boolean?, Maid.Maid>
	self.Maid:Add(self.VisibleChanged)
	self._visible = false

	self.AlphaEnabledChanged = Signal.new() :: Signal.Signal<boolean>
	self.Maid:Add(self.AlphaEnabledChanged)
	self._alphaEnabled = true

	--[[
		Get Gui
	]]

	local gui: Instance
	if type(options.Template) == "string" then
		gui = Assets:Clone(options.Template)
		self.Maid:Add(gui)
	elseif typeof(options.Template) == "Instance" then
		gui = options.Template
	else
		error(`[{self.ClassName}.new]: Bad template. Got {typeof(options.Template)}.`)
	end
	self.Gui = gui

	--[[
		Index Instances
	]]

	if options.Instances ~= nil then
		local revInstances = {}
		for key, name in options.Instances do
			revInstances[name] = key
		end
		for _, instance in self.Gui:GetDescendants() do
			local name = instance.Name
			local key = revInstances[name]
			if key ~= nil then
				self[key] = instance
				revInstances[name] = nil
			end
		end
		if next(revInstances) ~= nil then
			local errorLines = {}
			for missingName, missingKey in revInstances do
				table.insert(errorLines, `{missingKey} = "{missingName}",`)
			end
			error(`[{self.ClassName}.new]: No instance\n{table.concat(errorLines, "\n")}`)
		end
	end

	--[[
		Index all instances
	]]

	if options.AllInstances then
		self.Instances = {} :: { [string]: GuiBase2d | Instance }
		for _, instance in self.Gui:GetDescendants() do
			self.Instances[instance.Name] = instance
		end
	end

	--[[
		Setup
	]]

	self._springSet = SpringSet.new({
		Alpha = AccelTween.new(200, 1),
	})
	self.SpringSet = self._springSet
	self.Maid:Add(self._springSet)

	self._guiObject = self.Gui:IsA("GuiObject")
	if self._guiObject then
		self.Gui.Interactable = false
	end

	self.Maid:Add(self.VisibleChanged:Connect(function(visible, doNotAnimate)
		self:_guiPaneOnVisibleChanged(visible, doNotAnimate)
	end))

	return self
end

function GuiPane:IsAlphaEnabled(): boolean
	return self._alphaEnabled == true
end

function GuiPane:IsVisible(): boolean
	return self._visible == true
end

function GuiPane:SetAlphaEnabled(alphaEnabled: boolean)
	if self._alphaEnabled == alphaEnabled then
		return
	end
	self._alphaEnabled = alphaEnabled
	local alpha = if self._visible or self._alphaEnabled == false then 0 else 1
	self._springSet:SetTarget("Alpha", alpha, true)
	self.AlphaEnabledChanged:Fire(alphaEnabled)
end

function GuiPane:SetGuiProperties(properties: { [string]: any })
	local parent = properties.Parent
	properties.Parent = nil
	for property, value in properties do
		self.Gui[property] = value
	end
	if parent ~= nil then -- Parent last.
		self.Gui.Parent = parent
	end
end

function GuiPane:SetVisible(visible: boolean, doNotAnimate: boolean?)
	assert(type(visible) == "boolean", "Type visible boolean.")
	assert(doNotAnimate == nil or type(doNotAnimate) == "boolean", "Type doNotAnimate boolean.")
	if self._visible == visible then
		return
	end
	local visibleMaid = Maid.new()
	self.Maid.VisibleMaid = visibleMaid
	self._visible = visible
	if self._alphaEnabled == true then
		self._springSet:SetTarget("Alpha", if visible == true then 0 else 1, doNotAnimate)
	else
		self:_updateAutoVisible()
	end
	self.VisibleChanged:Fire(visible, doNotAnimate, visibleMaid)
end

function GuiPane:Toggle(doNotAnimate: boolean?)
	self:SetVisible(not self._visible, doNotAnimate)
end

function GuiPane:Show(doNotAnimate: boolean?)
	self:SetVisible(true, doNotAnimate)
end

function GuiPane:Hide(doNotAnimate: boolean?)
	self:SetVisible(false, doNotAnimate)
end

function GuiPane:_guiPaneOnVisibleChanged(visible: boolean, doNotAnimate: boolean?)
	if self._alphaEnabled == true then
		self._springSet:SetTarget("Alpha", if visible == true then 0 else 1, doNotAnimate)
	end
	if self._guiObject then
		self.Gui.Interactable = visible
	end
end

function GuiPane:_guiPaneReady()
	self.Maid:Add(self._springSet.Updated:Connect(function(positions, velocities)
		self:_updateGui(positions, velocities)
	end))
	self._springSet:Update()
end

function GuiPane:_guiPaneStory(target: Frame)
	self:SetVisible(true)
	self.Maid:Add(UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.V then
			self:Toggle()
		end
	end))
	self:SetGuiProperties({
		-- AnchorPoint = Vector2.new(0.5, 0.5),
		-- Position = UDim2.fromScale(0.5, 0.5),
		Parent = target,
	})
end

function GuiPane:_guiPaneStorySignals()
	for key, signal in self do
		if Signal.Is(signal) then
			self.Maid:Add(signal:Connect(function(...)
				print(`[{self.ClassName}]: {key}`, ...)
			end))
		end
	end
end

function GuiPane:_updateGui(
	values: { Alpha: number, [string]: number },
	velocities: { Alpha: number, [string]: number }
)
end

function GuiPane:Destroy()
	self.Maid:Destroy()
end

return GuiPane
