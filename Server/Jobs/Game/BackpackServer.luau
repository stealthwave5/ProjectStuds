--[[
	Author(s): Josh, Claude
	Module: BackpackServer.luau
--]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Modules
local Assets = shared("Assets") ---@module Assets
local GameConfig = shared("GameConfig") ---@module GameConfig
local GetRemote = shared("GetRemote") ---@module GetRemote
local Maid = shared("Maid") ---@module Maid
local PlayerAddedUtil = shared("PlayerAddedUtil") ---@module PlayerAddedUtil
local PlayerDataServer = shared("PlayerDataServer") ---@module PlayerDataServer
local RandomObject = shared("RandomObject") ---@module RandomObject
local StudObject = shared("StudObject") ---@module StudObject

-- Types
export type Pickup = {
	StudType: string,
	Mutation: string?,
	Worth: number,
	Value: number,
}

-- Constants
local STACK_FOLDER_NAME = "CoinStack"
local STUDS_FOLDER_NAME = "Studs"
local MAX_STACK_PLATES = 40
local PLATE_THICKNESS = 0.5
local STACK_YAW_JITTER_DEGREES = 10
local PICKUP_BLOCKED_THROTTLE = 1
--	The plate materialises as the client's flying stud reaches the player's back.
local PLATE_POP_TIME = 0.18
local PLATE_POP_SCALE = 0.25
local DROP_NAME = "DroppedStud"
local DROP_DESPAWN_TIME = 60
local DROP_TWEEN_TIME = 0.45
local DROP_BASE_DISTANCE = 4
local DROP_RING_DISTANCE = 4
local DROPS_PER_RING = 8
local DROP_RAYCAST_HEIGHT = 20
local RAYCAST_DISTANCE = 500

local BackpackServer = {}

-- Variables
local PickupBlockedRemote = GetRemote("BackpackServer:PickupBlocked")
local PlayerMaids: { [Player]: Maid.Maid } = {}
local LastBlockedTicks: { [Player]: number } = {}

-- Private functions

function BackpackServer:_getStudsFolder(): Folder
	local folder = Workspace:FindFirstChild(STUDS_FOLDER_NAME)
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = STUDS_FOLDER_NAME
		folder.Parent = Workspace
	end
	return folder
end

function BackpackServer:_getRaycastParams(): RaycastParams
	local excludeList: { Instance } = { self:_getStudsFolder() }
	local spawnZones = Workspace:FindFirstChild("SpawnZones")
	if spawnZones then
		table.insert(excludeList, spawnZones)
	end
	local sellPad = Workspace:FindFirstChild("SellPad")
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

function BackpackServer:_firePickupBlocked(player: Player, needed: number, free: number)
	local now = os.clock()
	local lastTick = LastBlockedTicks[player]
	if lastTick and now - lastTick < PICKUP_BLOCKED_THROTTLE then
		return
	end
	LastBlockedTicks[player] = now
	PickupBlockedRemote:FireClient(player, { needed = needed, free = free })
end

---Fades and scales a freshly stacked plate in, timed to land with the flying stud
---the client is animating toward the player's back.
function BackpackServer:_popPlateIn(plate: BasePart)
	local fullSize = plate.Size
	plate.Size = Vector3.new(fullSize.X * PLATE_POP_SCALE, fullSize.Y, fullSize.Z * PLATE_POP_SCALE)
	plate.Transparency = 1

	task.delay(GameConfig.PickupFlightTime, function()
		if plate.Parent == nil then
			return
		end
		local popTween = TweenService:Create(
			plate,
			TweenInfo.new(PLATE_POP_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = fullSize, Transparency = 0 }
		)
		popTween:Play()
	end)
end

function BackpackServer:_addStackPlate(player: Player, studType: string, mutationName: string?, animate: boolean?)
	local character = player.Character
	if character == nil then
		return
	end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if torso == nil or not torso:IsA("BasePart") then
		return
	end

	local stackFolder = character:FindFirstChild(STACK_FOLDER_NAME)
	if stackFolder == nil then
		stackFolder = Instance.new("Folder")
		stackFolder.Name = STACK_FOLDER_NAME
		stackFolder:SetAttribute("PileHeight", 0)
		stackFolder.Parent = character
	end
	if #stackFolder:GetChildren() >= MAX_STACK_PLATES then
		return
	end

	local template = Assets:Get(studType) :: BasePart
	local mutationConfig = if mutationName then GameConfig.getMutation(mutationName) else nil

	local plate = Instance.new("Part")
	plate.Name = "StackPlate"
	plate.Size = Vector3.new(template.Size.X, PLATE_THICKNESS, template.Size.Z)
	plate.Color = if mutationConfig and mutationConfig.color then mutationConfig.color else template.Color
	plate.Material = if mutationConfig then mutationConfig.material else template.Material
	plate.TopSurface = Enum.SurfaceType.Studs
	plate.Massless = true
	plate.CanCollide = false
	plate.CanQuery = false
	plate.CanTouch = false

	local pileHeight = stackFolder:GetAttribute("PileHeight") or 0
	local yaw = math.rad(RandomObject:NextNumber(-STACK_YAW_JITTER_DEGREES, STACK_YAW_JITTER_DEGREES))
	plate.CFrame = torso.CFrame
		* CFrame.new(0, -torso.Size.Y / 2 + PLATE_THICKNESS / 2 + pileHeight, torso.Size.Z / 2 + plate.Size.Z / 2)
		* CFrame.Angles(0, yaw, 0)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = plate
	weld.Part1 = torso
	weld.Parent = plate

	plate.Parent = stackFolder
	stackFolder:SetAttribute("PileHeight", pileHeight + PLATE_THICKNESS)

	if animate then
		self:_popPlateIn(plate)
	end
end

function BackpackServer:_clearStack(player: Player)
	local character = player.Character
	if character == nil then
		return
	end
	local stackFolder = character:FindFirstChild(STACK_FOLDER_NAME)
	if stackFolder then
		stackFolder:Destroy()
	end
end

function BackpackServer:_rebuildStack(player: Player)
	local replica = PlayerDataServer:WaitForReplica(player, 30)
	if replica == nil then
		return
	end
	self:_clearStack(player)
	for _, item in replica.Data.CarriedItems do
		self:_addStackPlate(player, item.Type, item.Mutation, false)
	end
end

function BackpackServer:_scatterDrop(index: number, origin: Vector3, item: { Type: string, Mutation: string? })
	local ring = math.floor((index - 1) / DROPS_PER_RING)
	local angle = ((index - 1) % DROPS_PER_RING) / DROPS_PER_RING * math.pi * 2 + RandomObject:NextNumber() * 0.5
	local distance = DROP_BASE_DISTANCE + ring * DROP_RING_DISTANCE + RandomObject:NextNumber() * 2

	local landingPosition = origin + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
	local raycastResult = Workspace:Raycast(
		landingPosition + Vector3.new(0, DROP_RAYCAST_HEIGHT, 0),
		Vector3.new(0, -RAYCAST_DISTANCE, 0),
		self:_getRaycastParams()
	)
	if raycastResult then
		landingPosition = raycastResult.Position + Vector3.new(0, 2, 0)
	end

	local stud = StudObject.new({
		StudType = item.Type,
		Mutation = item.Mutation,
		CFrame = CFrame.new(origin + Vector3.new(0, 2, 0))
			* CFrame.Angles(0, RandomObject:NextNumber() * math.pi * 2, 0),
		Parent = self:_getStudsFolder(),
		Name = DROP_NAME,
		Locked = true,
		Tagged = false,
	})
	stud.PickedUp:Connect(function(picker: Player)
		if self:TryPickup(picker, stud) then
			stud:Collect(picker)
		end
	end)

	local landingCFrame = CFrame.new(landingPosition) * CFrame.Angles(0, RandomObject:NextNumber() * math.pi * 2, 0)
	local tween = TweenService:Create(
		stud.Part,
		TweenInfo.new(DROP_TWEEN_TIME, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{ CFrame = landingCFrame }
	)
	tween.Completed:Once(function()
		--	Only lootable once landed.
		if stud:IsActive() then
			stud:AddTag()
			stud:SetLocked(false)
		end
	end)
	tween:Play()

	task.delay(DROP_DESPAWN_TIME, function()
		if stud:IsActive() then
			stud:Destroy()
		end
	end)
end

function BackpackServer:_onCharacterAdded(player: Player, character: Model)
	local playerMaid = PlayerMaids[player]
	if playerMaid == nil then
		return
	end
	local characterMaid = Maid.new()
	playerMaid["Character"] = characterMaid

	characterMaid:Add(task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			characterMaid:Add(humanoid.Died:Once(function()
				self:DropCarried(player)
			end))
		end
		self:_rebuildStack(player)
	end))
end

function BackpackServer:_onPlayerAdded(player: Player)
	local playerMaid = Maid.new()
	PlayerMaids[player] = playerMaid

	--	Carried studs never persist between sessions (the profile may have
	--	autosaved mid-session, e.g. before a crash or shutdown).
	local replica = PlayerDataServer:WaitForReplica(player, 30)
	if replica then
		replica:SetValue({ "Carried" }, 0)
		replica:SetValue({ "CarriedValue" }, 0)
		replica:SetValue({ "CarriedItems" }, {})
	end
	if PlayerMaids[player] ~= playerMaid then
		--	Player left while waiting for their replica.
		return
	end

	playerMaid:Add(player.CharacterAdded:Connect(function(character: Model)
		self:_onCharacterAdded(player, character)
	end))
	if player.Character then
		self:_onCharacterAdded(player, player.Character)
	end
end

function BackpackServer:_onPlayerRemoving(player: Player)
	self:DropCarried(player)
	local playerMaid = PlayerMaids[player]
	if playerMaid then
		playerMaid:Destroy()
		PlayerMaids[player] = nil
	end
	LastBlockedTicks[player] = nil
end

-- Public functions

---Attempts to add one stud to the player's backpack. Fires PickupBlocked
---(throttled) and returns false when there is not enough free capacity.
function BackpackServer:TryPickup(player: Player, pickup: Pickup): boolean
	local replica = PlayerDataServer:GetReplica(player)
	if replica == nil then
		return false
	end
	local capacity = GameConfig.getCapacity(replica.Data.Upgrades.Capacity)
	local free = capacity - replica.Data.Carried
	if pickup.Worth > free then
		self:_firePickupBlocked(player, pickup.Worth, free)
		return false
	end

	replica:ArrayInsert({ "CarriedItems" }, { Type = pickup.StudType, Mutation = pickup.Mutation })
	replica:SetValue({ "Carried" }, replica.Data.Carried + pickup.Worth)
	replica:SetValue({ "CarriedValue" }, replica.Data.CarriedValue + pickup.Value)
	self:_addStackPlate(player, pickup.StudType, pickup.Mutation, true)
	return true
end

---Zeroes Carried/CarriedValue/CarriedItems and clears the back stack.
---Returns the units and base value that were held (for SellServer).
function BackpackServer:TakeAll(player: Player): (number, number)
	local replica = PlayerDataServer:GetReplica(player)
	if replica == nil then
		return 0, 0
	end
	local units = replica.Data.Carried
	local value = replica.Data.CarriedValue
	replica:SetValue({ "Carried" }, 0)
	replica:SetValue({ "CarriedValue" }, 0)
	replica:SetValue({ "CarriedItems" }, {})
	self:_clearStack(player)
	return units, value
end

---Clears all carried state without granting anything (rebirth).
function BackpackServer:Clear(player: Player)
	self:TakeAll(player)
end

---Drops everything the player carries as exact stud clones scattered around
---them (bat robbery, death and leaving the game). Drops are uncollectable
---until landed and despawn after 60 seconds.
function BackpackServer:DropCarried(player: Player)
	local replica = PlayerDataServer:GetReplica(player)
	if replica == nil then
		return
	end
	local items = replica.Data.CarriedItems
	self:TakeAll(player)
	if #items == 0 then
		return
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart == nil or not rootPart:IsA("BasePart") then
		return
	end
	local origin = rootPart.Position

	for index, item in items do
		self:_scatterDrop(index, origin, item)
	end
end

-- Start

function BackpackServer:Run()
	PlayerAddedUtil:Connect({
		Added = function(player: Player)
			self:_onPlayerAdded(player)
		end,
		Removing = function(player: Player)
			self:_onPlayerRemoving(player)
		end,
	})
end

return BackpackServer
