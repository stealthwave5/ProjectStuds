--[[
	Author(s): Gory
	Module: KitModuleRef.luau
]]

local KitTimer = require(script.Parent.KitTimer) ---@module KitTimer

local KitModuleRef = {}
KitModuleRef.__index = KitModuleRef
KitModuleRef.ClassName = "KitModuleRef"

export type KitModuleRef = {
	GetDeferredRef: (self: KitModuleRef) -> any,
	GetModule: (self: KitModuleRef) -> any,
	GetName: (self: KitModuleRef) -> string,
	GetParent: (self: KitModuleRef) -> Instance,
	HasRequired: (self: KitModuleRef) -> boolean,
	IsRequiring: (self: KitModuleRef) -> boolean,
}

local function ThrowDeferredRefNotReady()
	error("Deferred Ref can't be used till module is loaded.")
end
local DeferredRefNotReadyMetatable = {
	__index = ThrowDeferredRefNotReady,
	__newindex = ThrowDeferredRefNotReady,
}

function KitModuleRef.new(moduleScript: ModuleScript): KitModuleRef
	local self = setmetatable({
		_moduleScript = moduleScript,
		_module = nil,
	}, KitModuleRef)
	return self
end

function KitModuleRef.fromLoaded(module: {}): KitModuleRef
	local self = setmetatable({
		_moduleScript = nil,
		_module = module,
	}, KitModuleRef)
	return self
end

function KitModuleRef:IsRequiring(): boolean?
	return self._requiring
end

function KitModuleRef:GetDeferredRef()
	if self._module then
		return self._module
	end
	if self._deferredRef then
		return self._deferredRef
	end
	self._deferredRef = setmetatable({}, DeferredRefNotReadyMetatable)
	return self._deferredRef
end

function KitModuleRef:GetName(): string
	return self._moduleScript.Name
end

function KitModuleRef:GetParent(): Instance
	return self._moduleScript.Parent
end

function KitModuleRef:GetModule(): any
	if self._module ~= nil then
		return self._module
	end
	self._requiring = true -- Locked.
	local module = KitTimer:Time(`require({self:GetName()})`, 0.01, require, self._moduleScript)
	self._requiring = false -- Unlocked.
	self._module = module
	if self._deferredRef then
		setmetatable(self._deferredRef, {
			__index = self._module,
			__newindex = self._module,
		})
		self._deferredRef = nil
	end
	return module
end

function KitModuleRef:HasRequired()
	return self._module ~= nil
end

function KitModuleRef.is(moduleRef: KitModuleRef)
	return type(moduleRef) == "table" and getmetatable(moduleRef) == KitModuleRef
end

return KitModuleRef
