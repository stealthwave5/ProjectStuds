--[[
	Author(s): Josh, Claude
	Module: TagObjects.luau
--]]

-- Services
local CollectionService = game:GetService("CollectionService")

-- Modules
local Maid = shared("Maid") ---@module Maid
local Signal = shared("Signal") ---@module Signal

-- Types
type Constructor = ((instance: Instance) -> any?) | { new: (instance: Instance) -> any? }

local TagObjects = {}
TagObjects.__index = TagObjects
TagObjects.ClassName = "TagObjects"

export type TagObjects = {
	GetObject: (self: TagObjects, instance: Instance) -> any?,
	Destroy: (self: TagObjects) -> (),
	Objects: { [Instance]: any },
	InstanceAdded: Signal.Signal<Instance, any>,
	InstanceRemoved: Signal.Signal<Instance, any>,
}

-- Constructor

---Binds a constructor (or a class table with .new) to every instance carrying the tag.
---The constructor may return nil to skip an instance. Objects with a Destroy method
---are destroyed when the tag is removed or the binder is destroyed.
function TagObjects.new(tag: string, constructorOrClass: Constructor): TagObjects
	local self = setmetatable({}, TagObjects)

	self._maid = Maid.new()
	self._tag = tag
	self._constructor = constructorOrClass

	self.Objects = {}
	self.InstanceAdded = self._maid:Add(Signal.new()) :: Signal.Signal<Instance, any>
	self.InstanceRemoved = self._maid:Add(Signal.new()) :: Signal.Signal<Instance, any>

	self._maid:Add(CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance: Instance)
		self:_onInstanceAdded(instance)
	end))
	self._maid:Add(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance: Instance)
		self:_onInstanceRemoved(instance)
	end))
	for _, instance in CollectionService:GetTagged(tag) do
		task.spawn(function()
			self:_onInstanceAdded(instance)
		end)
	end

	return self :: any
end

-- Private functions

function TagObjects:_construct(instance: Instance): any?
	local constructor = self._constructor
	if type(constructor) == "table" then
		return constructor.new(instance)
	end
	return constructor(instance)
end

function TagObjects:_onInstanceAdded(instance: Instance)
	if self._destroyed or self.Objects[instance] ~= nil then
		return
	end
	local object = self:_construct(instance)
	if object == nil then
		return
	end
	self.Objects[instance] = object
	self.InstanceAdded:Fire(instance, object)
end

function TagObjects:_onInstanceRemoved(instance: Instance)
	local object = self.Objects[instance]
	if object == nil then
		return
	end
	self.Objects[instance] = nil
	self.InstanceRemoved:Fire(instance, object)
	if type(object) == "table" and type(object.Destroy) == "function" then
		object:Destroy()
	end
end

-- Public functions

function TagObjects:GetObject(instance: Instance): any?
	return self.Objects[instance]
end

function TagObjects:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	for instance, object in self.Objects do
		self.Objects[instance] = nil
		if type(object) == "table" and type(object.Destroy) == "function" then
			object:Destroy()
		end
	end
	self._maid:DoCleaning()
end

return TagObjects
