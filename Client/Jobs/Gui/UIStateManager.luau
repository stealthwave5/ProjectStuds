--[[
	Author(s): Josh, Claude
	Module: UIStateManager.luau
]]

-- Modules

local Signal = shared("Signal") ---@module Signal

-- Types

export type PaneLike = {
	SetVisible: (self: PaneLike, visible: boolean, doNotAnimate: boolean?) -> (),
}

export type StateDefinition = {
	Shows: { string }?,
	Hides: { string }?,
}

-- Constants

local DEFAULT_STATE = "Gameplay"

-- Variables

local UIStateManager = {}
UIStateManager.StateChanged = Signal.new() :: Signal.Signal<string, string?>

local States: { [string]: StateDefinition } = {}
local Components: { [string]: PaneLike } = {}
local CurrentState: string? = nil
local DefaultState: string? = nil

-- Private functions

local function shouldComponentShow(state: StateDefinition, componentName: string): boolean
	if state.Shows ~= nil and table.find(state.Shows, componentName) ~= nil then
		return true
	end
	--	Components not listed in Shows are hidden (Hides is accepted but redundant).
	return false
end

local function applyStateToComponent(state: StateDefinition, componentName: string, doNotAnimate: boolean?)
	local component = Components[componentName]
	if component == nil then
		return
	end
	component:SetVisible(shouldComponentShow(state, componentName), doNotAnimate)
end

-- Public functions

function UIStateManager:RegisterState(stateName: string, definition: StateDefinition)
	if States[stateName] ~= nil then
		warn(`[UIStateManager] State "{stateName}" registered twice.`)
	end
	States[stateName] = definition
end

function UIStateManager:RegisterDefaultState(stateName: string)
	assert(States[stateName] ~= nil, `[UIStateManager] Unknown default state "{stateName}".`)
	DefaultState = stateName
end

---Registers a pane-like component and immediately applies the current state to it.
function UIStateManager:RegisterComponent(componentName: string, component: PaneLike)
	if Components[componentName] ~= nil then
		warn(`[UIStateManager] Component "{componentName}" registered twice.`)
	end
	Components[componentName] = component

	local state = if CurrentState ~= nil then States[CurrentState] else nil
	if state ~= nil then
		applyStateToComponent(state, componentName)
	end
end

function UIStateManager:SetState(stateName: string, doNotAnimate: boolean?)
	local state = States[stateName]
	assert(state ~= nil, `[UIStateManager] Unknown state "{stateName}".`)

	local previousState = CurrentState
	if previousState == stateName then
		return
	end
	CurrentState = stateName

	for componentName in Components do
		applyStateToComponent(state, componentName, doNotAnimate)
	end

	self.StateChanged:Fire(stateName, previousState)
end

function UIStateManager:GetState(): string?
	return CurrentState
end

function UIStateManager:SetDefault(doNotAnimate: boolean?)
	assert(DefaultState ~= nil, "[UIStateManager] No default state registered.")
	self:SetState(DefaultState, doNotAnimate)
end

-- Start

function UIStateManager:Init()
	--	States per migration contract §7. HUD components stay visible everywhere;
	--	panel components only show in their own state.
	self:RegisterState("Gameplay", {
		Shows = { "HUD_TopHud", "HUD_SideButtons" },
		Hides = { "Panel_Upgrades", "Panel_Shop" },
	})
	self:RegisterState("Upgrades", {
		Shows = { "HUD_TopHud", "HUD_SideButtons", "Panel_Upgrades" },
		Hides = { "Panel_Shop" },
	})
	self:RegisterState("Shop", {
		Shows = { "HUD_TopHud", "HUD_SideButtons", "Panel_Shop" },
		Hides = { "Panel_Upgrades" },
	})
	self:RegisterDefaultState(DEFAULT_STATE)
	self:SetState(DEFAULT_STATE, true)
end

return UIStateManager
