--[[
	Author(s): Gory
	Module: SpringSet.luau
	Created: 01/12/2024
	Version: 0.7.1

	Spring controller to fire a signal with all spring
	positions, while any spring is animating.
--]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local AccelTween = shared("AccelTween") ---@module AccelTween
local Maid = shared("Maid") ---@module Maid
local Signal = shared("Signal") ---@module Signal
local Spring = shared("Spring") ---@module Spring

type NewSpringAttributes = { t: number, s: number, d: number }
type SpringLike = AccelTween.AccelTween | Spring.Spring
type Springable = Spring.Springable

local EPSILON = 0.001

local SpringSet = {}
SpringSet.__index = SpringSet
SpringSet.ClassName = "SpringSet"

export type SpringSet = {
	AddSpring: (self: SpringSet, name: string, spring: SpringLike | NewSpringAttributes) -> SpringLike,
	AddMany: (self: SpringSet, springs: {
		[string]: SpringLike | NewSpringAttributes,
	}) -> (),
	Bind: (self: SpringSet, fn: (positions: {}, velocities: {}) -> ()) -> Signal.Connection,
	GetPosition: (self: SpringSet, name: string) -> Springable,
	GetVelocity: (self: SpringSet, name: string) -> Springable,
	SetTarget: (self: SpringSet, name: string, target: Springable, doSnap: boolean?) -> (),
	Snap: (self: SpringSet, name: string, position: Springable?) -> (),
	SetPosition: (self: SpringSet, name: string, position: Springable) -> (),
	SetMaxAcceleration: (self: SpringSet, name: string, maxAccel: number) -> (),
	Destroy: (self: SpringSet) -> (),
	Positions: {},
	Velocities: {},
	Updated: Signal.Signal,
}

---Creates a new instance of SpringSet.
---
--[[**Example:**
```lua

local springSet = SpringSet.new({
	Visible = { t = 0, s = 30, d = 1},
})
springSet.Updated:Connect(function(values)
	print(values.Visible)
end)
springSet:SetTarget("Visible", 1)

-- 0.04
-- 0.06
-- ...
-- 0.98
-- 1
```
]]
---@param springs table Dictionary of springs, acceltweens and new spring attributes.
---@return table self New springset instance.
function SpringSet.new(springs: { [string]: SpringLike | NewSpringAttributes }): SpringSet
	local self = setmetatable({}, SpringSet)

	self._bindName = `SpringSet-{HttpService:GenerateGUID()}`
	self._bound = false
	self._maid = Maid.new()

	self.Updated = self._maid:Add(Signal.new()) :: Signal.Signal<{ [string]: Springable }, { [string]: Springable }>

	self.Positions = {} :: { [string]: Springable }
	self.Velocities = {} :: { [string]: Springable }
	self._springs = {} :: { [string]: SpringLike }
	if springs then
		for name, spring in springs do
			self:AddSpring(name, spring)
		end
	end
	return self
end

---Add a new spring.
---@param name string Spring name.
---@param spring table Spring, AccelTween or new spring attributes.
function SpringSet:AddSpring(name: string, spring: SpringLike | NewSpringAttributes): SpringLike
	if not (AccelTween.Is(spring) or Spring.Is(spring)) then
		assert(
			type(spring) == "table",
			"Spring must be Spring or AccelTween or NewSpringAttributes: " .. `Got {name}, typeof {typeof(spring)}`
		)
		local springObject = Spring.new(spring.Position or spring.p or spring.t or spring.Target or nil)
		for k, v in spring do
			springObject[k] = v
		end
		spring = springObject
	end
	self.Positions[name] = spring.p
	self.Velocities[name] = spring.v
	self._springs[name] = spring
	return spring
end

function SpringSet:AddMany(springs: {
	[string]: SpringLike | NewSpringAttributes,
})
	for name, spring in springs do
		self:AddSpring(name, spring)
	end
end

-- TODO: These bind methods break conventions, but are idiomic and quick: discuss

-- function SpringSet:Bind(fn: (positions: {}, velocities: {}) -> ())
-- 	return self.Updated:Connect(fn)
-- end

---Get a spring position.
---@param name string Spring name.
---@return any position Position of spring.
function SpringSet:GetPosition(name: string): Springable
	return assert(self.Positions[name], `No spring "{name}".`)
end

---Get a spring velocity.
---@param name string Spring name.
---@return any velocity Velocity of spring.
function SpringSet:GetVelocity(name: string): Springable
	return assert(self.Velocities[name], `No spring "{name}".`)
end

function SpringSet:Impulse(name: string, force)
	local spring = self:_getSpring(name)
	spring:Impulse(force)
	self:_bind()
end

---Set a spring position and target. To 'snap' a spring straight to a position without animation.
---@param name string Spring name.
---@param position any Spring new position and target.
function SpringSet:Snap(name: string, position: Springable?)
	if type(position) == "boolean" then
		position = if position then 1 else 0
	end
	local spring = self:_getSpring(name)
	self:_snapSpring(spring, position)
	self:_bind()
end

function SpringSet:SnapAll()
	for _name, spring in self._springs do
		self:_snapSpring(spring)
	end
	self:_bind()
end

function SpringSet:_snapSpring(spring, position)
	position = position or spring.t
	if AccelTween.Is(spring) then
		spring.pt = position
	else
		spring.Target = position
		spring.Position = position
	end
end

---Set a spring damper.
---@param name string Spring name.
---@param damper number Spring new damper.
function SpringSet:SetDamper(name: string, damper: number)
	self:_setSpringAttribute(name, "Damper", damper)
end

---Set a spring position.
---The springset callback will run this frame and every frame until all springs are not animating.
---@param name string Spring name.
---@param position any Spring new position.
function SpringSet:SetPosition(name: string, position: Springable)
	if type(position) == "boolean" then
		position = if position then 1 else 0
	end
	self:_setSpringAttribute(name, "p", position)
	self:_bind()
end

---Set a spring speed.
---@param name string Spring name.
---@param speed number Spring new speed.
function SpringSet:SetSpeed(name: string, speed: number)
	self:_setSpringAttribute(name, "Speed", speed)
end

function SpringSet:SetMaxAcceleration(name: string, maxAccel: number)
	self:_setSpringAttribute(name, "a", maxAccel)
end

---Set a spring target.
---The springset callback will run this frame and every frame until all springs are not animating.
---@param name string Spring name.
---@param target any Spring new target.
---@param doSnap boolean | nil Optional. Set the position too, skipping animation.
--[[**Example**
```lua
local visible = true
local doNotAnimate = false

springSet:SetTarget("Visible", if visible then 1 else 0, doNotAnimate)
```
]]
function SpringSet:SetTarget(name: string, target: Springable, doSnap: boolean?)
	assert(target ~= nil, "No target.")
	if doSnap then
		self:Snap(name, target)
		return
	end
	if type(target) == "boolean" then
		target = if target then 1 else 0
	end
	self:_setSpringAttribute(name, "t", target)
	self:_bind()
end

function SpringSet:_setSpringAttribute(name: string, attribute: string, value: Springable)
	self:_getSpring(name)[attribute] = value
end

function SpringSet:_getSpring(name: string)
	local spring = self._springs[name]
	assert(spring, `No spring "{name}".`)
	return spring
end

function SpringSet:_update(): boolean
	local anyAnimating = false
	local animating: boolean
	local position: Springable
	local velocity: Springable
	for name: string, spring: SpringLike in self._springs do
		animating, position = spring:IsAnimating(EPSILON)
		velocity = spring.v
		if animating then
			anyAnimating = true
		end
		self.Positions[name] = position
		self.Velocities[name] = velocity
	end
	debug.profilebegin("SpringSetUpdate")
	self.Updated:Fire(self.Positions, self.Velocities)
	debug.profileend()
	return anyAnimating
end

function SpringSet:_step()
	local anyAnimating = self:_update()
	if not anyAnimating then
		self:_unbind()
	end
end

function SpringSet:_bind()
	if self._bound == true then
		return
	end
	local anyAnimating = self:_update()
	if not anyAnimating then
		return
	end
	--	RenderPriority not important.
	self._bound = true
	RunService:BindToRenderStep(self._bindName, Enum.RenderPriority.Last.Value, function()
		self:_step()
	end)
end

function SpringSet:_unbind()
	if self._bound == false then
		return
	end
	RunService:UnbindFromRenderStep(self._bindName)
	self._bound = false
end

SpringSet.SetPositionAndTarget = SpringSet.Snap
SpringSet.Update = SpringSet._update

function SpringSet:Destroy()
	self:_unbind()
	self._maid:Destroy()
	self._destroyed = true
end

return SpringSet
