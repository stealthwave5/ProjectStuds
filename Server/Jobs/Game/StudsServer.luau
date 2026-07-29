--[[
	Author(s): Josh, Claude
	Module: StudsServer.luau
--]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Modules
local BackpackServer = shared("BackpackServer") ---@module BackpackServer
local GameConfig = shared("GameConfig") ---@module GameConfig
local RandomObject = shared("RandomObject") ---@module RandomObject
local StudObject = shared("StudObject") ---@module StudObject

-- Constants
local STUDS_FOLDER_NAME = "Studs"
local SPAWN_ZONES_NAME = "SpawnZones"
local SELL_PAD_NAME = "SellPad"
local SPAWN_LOCATION_NAME = "SpawnLocation"
local SPAWN_HEIGHT_OFFSET = 2
local SPAWN_RETRIES = 8
local RAYCAST_DISTANCE = 500
local FALLBACK_SPAWN_HEIGHT = 2

local StudsServer = {}

-- Variables
local StudsFolder: Folder

-- Private functions

function StudsServer:_getSpawnZones(): { BasePart }
	local zones: { BasePart } = {}
	local zonesFolder = Workspace:FindFirstChild(SPAWN_ZONES_NAME)
	if zonesFolder then
		for _, child in zonesFolder:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(zones, child)
			end
		end
	end
	return zones
end

function StudsServer:_getZoneWeight(zone: BasePart): number
	local weight = zone:GetAttribute("Weight")
	if type(weight) == "number" and weight > 0 then
		return weight
	end
	return zone.Size.X * zone.Size.Z
end

function StudsServer:_pickZone(): BasePart?
	local zones = self:_getSpawnZones()
	if #zones == 0 then
		return nil
	end
	local totalWeight = 0
	for _, zone in zones do
		totalWeight += self:_getZoneWeight(zone)
	end
	local roll = RandomObject:NextNumber() * totalWeight
	for _, zone in zones do
		roll -= self:_getZoneWeight(zone)
		if roll <= 0 then
			return zone
		end
	end
	return zones[#zones]
end

function StudsServer:_hideZones()
	for _, zone in self:_getSpawnZones() do
		zone.Transparency = 1
		zone.CanCollide = false
		zone.CanTouch = false
		zone.CanQuery = false
	end
end

function StudsServer:_getRaycastParams(): RaycastParams
	local excludeList: { Instance } = { StudsFolder }
	local zonesFolder = Workspace:FindFirstChild(SPAWN_ZONES_NAME)
	if zonesFolder then
		table.insert(excludeList, zonesFolder)
	end
	local sellPad = Workspace:FindFirstChild(SELL_PAD_NAME)
	if sellPad then
		table.insert(excludeList, sellPad)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(excludeList, player.Character)
		end
	end
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = excludeList
	return raycastParams
end

---Rotation-aware random point in the zone footprint, raycast down onto
---whatever geometry is below. Retries when a point hangs over the void.
function StudsServer:_pickPositionInZone(zone: BasePart): Vector3?
	for _ = 1, SPAWN_RETRIES do
		local offsetX = RandomObject:NextNumber(-zone.Size.X / 2, zone.Size.X / 2)
		local offsetZ = RandomObject:NextNumber(-zone.Size.Z / 2, zone.Size.Z / 2)
		local worldPoint = (zone.CFrame * CFrame.new(offsetX, 0, offsetZ)).Position
		local raycastResult =
			Workspace:Raycast(worldPoint, Vector3.new(0, -RAYCAST_DISTANCE, 0), self:_getRaycastParams())
		if raycastResult then
			return raycastResult.Position + Vector3.new(0, SPAWN_HEIGHT_OFFSET, 0)
		end
	end
	return nil
end

---Open-range fallback used when there are no zones (or a zone point failed).
function StudsServer:_pickOpenPosition(): Vector3
	local mapRange = GameConfig.MapRange
	local positionX = RandomObject:NextNumber(-mapRange, mapRange)
	local positionZ = RandomObject:NextNumber(-mapRange, mapRange)
	local raycastResult = Workspace:Raycast(
		Vector3.new(positionX, 100, positionZ),
		Vector3.new(0, -RAYCAST_DISTANCE, 0),
		self:_getRaycastParams()
	)
	if raycastResult then
		return raycastResult.Position + Vector3.new(0, SPAWN_HEIGHT_OFFSET, 0)
	end
	return Vector3.new(positionX, FALLBACK_SPAWN_HEIGHT, positionZ)
end

function StudsServer:_getSpawnDistance(position: Vector3): number
	local spawnLocation = Workspace:FindFirstChild(SPAWN_LOCATION_NAME)
	local center = if spawnLocation and spawnLocation:IsA("BasePart") then spawnLocation.Position else Vector3.zero
	local offset = position - center
	return Vector3.new(offset.X, 0, offset.Z).Magnitude
end

function StudsServer:_pickStudType(zone: BasePart?, position: Vector3): string
	if zone then
		local forcedType = zone:GetAttribute("StudType")
		if type(forcedType) == "string" and GameConfig.getStudType(forcedType) then
			return forcedType
		end
	end
	local distance = self:_getSpawnDistance(position)
	return GameConfig.getStudTypeForDistance(distance, RandomObject).name
end

---Spawns one stud. When zone is nil a fresh weighted zone is picked, so
---respawns stay in the zone their stud was collected from.
function StudsServer:_spawnStud(zone: BasePart?)
	local spawnZone = zone
	if spawnZone == nil or spawnZone.Parent == nil then
		spawnZone = self:_pickZone()
	end

	local position: Vector3?
	if spawnZone then
		position = self:_pickPositionInZone(spawnZone)
	end
	if position == nil then
		position = self:_pickOpenPosition()
	end

	local studTypeName = self:_pickStudType(spawnZone, position :: Vector3)
	local mutationConfig = GameConfig.rollMutation(RandomObject)

	local stud = StudObject.new({
		StudType = studTypeName,
		Mutation = if mutationConfig then mutationConfig.name else nil,
		CFrame = CFrame.new(position :: Vector3) * CFrame.Angles(0, RandomObject:NextNumber() * math.pi * 2, 0),
		Parent = StudsFolder,
	})
	stud.PickedUp:Connect(function(player: Player)
		if BackpackServer:TryPickup(player, stud) then
			stud:Collect(player)
			task.delay(GameConfig.CoinRespawnTime, function()
				self:_spawnStud(spawnZone)
			end)
		end
	end)
end

-- Start

function StudsServer:Init()
	StudsFolder = Workspace:FindFirstChild(STUDS_FOLDER_NAME)
	if StudsFolder == nil then
		StudsFolder = Instance.new("Folder")
		StudsFolder.Name = STUDS_FOLDER_NAME
		StudsFolder.Parent = Workspace
	end
end

function StudsServer:Run()
	self:_hideZones()
	for _ = 1, GameConfig.CoinCount do
		self:_spawnStud(nil)
	end
end

return StudsServer
