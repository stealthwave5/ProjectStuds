--[[
	Author(s): Josh, Claude
	Module: StudObject.luau
--]]

-- Services
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- Modules
local Assets = shared("Assets") ---@module Assets
local GameConfig = shared("GameConfig") ---@module GameConfig
local Maid = shared("Maid") ---@module Maid
local Signal = shared("Signal") ---@module Signal

-- Constants
local COIN_TAG = "Coin"

-- Types
export type StudObjectOptions = {
	StudType: string,
	Mutation: string?,
	CFrame: CFrame,
	Parent: Instance,
	Name: string?,
	Locked: boolean?, -- Locked studs ignore touches (airborne drops).
	Tagged: boolean?, -- Default true; drops tag only after landing.
}

local StudObject = {}
StudObject.__index = StudObject
StudObject.ClassName = "StudObject"

export type StudObject = {
	AddTag: (self: StudObject) -> (),
	Collect: (self: StudObject, player: Player) -> (),
	IsActive: (self: StudObject) -> boolean,
	IsLocked: (self: StudObject) -> boolean,
	SetLocked: (self: StudObject, locked: boolean) -> (),
	Destroy: (self: StudObject) -> (),
	Part: BasePart,
	StudType: string,
	Mutation: string?,
	Worth: number,
	Value: number,
	PickedUp: Signal.Signal<Player>,
}

-- Constructor

function StudObject.new(options: StudObjectOptions): StudObject
	local self = setmetatable({}, StudObject)

	local typeConfig = GameConfig.getStudType(options.StudType)
	assert(typeConfig, `[StudObject]: Unknown stud type "{options.StudType}".`)

	local mutationConfig = if options.Mutation then GameConfig.getMutation(options.Mutation) else nil

	self._maid = Maid.new()
	self._destroyed = false
	self._collected = false
	self._locked = options.Locked == true

	self.StudType = options.StudType
	self.Mutation = options.Mutation
	self.Worth = typeConfig.units
	self.Value = typeConfig.baseValue * (if mutationConfig then mutationConfig.multiplier else 1)

	self.PickedUp = self._maid:Add(Signal.new()) :: Signal.Signal<Player>

	local part = Assets:Clone(options.StudType) :: BasePart
	self._maid:Add(part)
	self.Part = part

	part.Name = options.Name or options.StudType
	part.Anchored = true
	part.CanCollide = false
	part:SetAttribute("StudType", self.StudType)
	part:SetAttribute("Worth", self.Worth)
	part:SetAttribute("Value", self.Value)
	if options.Mutation then
		part:SetAttribute("Mutation", options.Mutation)
	end
	if mutationConfig then
		self:_applyMutationVisuals(mutationConfig)
	end

	self._maid:Add(part.Touched:Connect(function(otherPart: BasePart)
		self:_onTouched(otherPart)
	end))

	part.CFrame = options.CFrame
	part.Parent = options.Parent
	if options.Tagged ~= false then
		CollectionService:AddTag(part, COIN_TAG)
	end

	return self :: any
end

-- Private functions

function StudObject:_applyMutationVisuals(mutationConfig: GameConfig.MutationConfig)
	local part = self.Part :: BasePart
	--	Rainbow has no fixed color: the client hue-cycles it.
	if mutationConfig.color then
		part.Color = mutationConfig.color
	end
	part.Material = mutationConfig.material
	local highlight = part:FindFirstChildOfClass("Highlight")
	if highlight then
		highlight.FillColor = mutationConfig.highlight
		highlight.OutlineColor = mutationConfig.highlight
	end
end

function StudObject:_onTouched(otherPart: BasePart)
	if self._destroyed or self._collected or self._locked then
		return
	end
	local character = otherPart.Parent
	if character == nil then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if player == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then
		return
	end
	self.PickedUp:Fire(player)
end

-- Public functions

function StudObject:AddTag()
	if self._destroyed then
		return
	end
	CollectionService:AddTag(self.Part, COIN_TAG)
end

function StudObject:Collect(player: Player)
	if self._destroyed or self._collected then
		return
	end
	self._collected = true
	self.Part:SetAttribute("CollectedBy", player.UserId)
	self:Destroy()
end

function StudObject:IsActive(): boolean
	return not self._destroyed
end

function StudObject:IsLocked(): boolean
	return self._locked
end

function StudObject:SetLocked(locked: boolean)
	self._locked = locked
end

function StudObject:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._maid:DoCleaning()
end

return StudObject
