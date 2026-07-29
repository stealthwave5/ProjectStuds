--[[
	Author(s): Josh, Claude
	Module: StudAnimatorClient.luau
]]

-- Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Modules
local DataClient = shared("DataClient") ---@module DataClient
local GameConfig = shared("GameConfig") ---@module GameConfig

-- Types
type StudEntry = {
	Part: BasePart,
	BaseCFrame: CFrame,
	PhaseOffset: number,
	IsFrozen: boolean,
	IsRainbow: boolean,
	Units: number?,
	NameLabel: TextLabel?,
	SlotLabel: TextLabel?,
}

-- Constants
local STUD_TAG = "Coin"

local BOB_HEIGHT = 0.5
local BOB_SPEED = 2
local WOBBLE_SPEED_MULTIPLIER = 1.7
local WOBBLE_ANGLE = math.rad(8)
local SPIN_SPEED = math.rad(120)
local FROZEN_SPEED_MULTIPLIER = 0.4

local RAINBOW_HUE_SPEED = 0.5
local RAINBOW_SATURATION = 0.8
local RAINBOW_BRIGHTNESS = 1

local LABEL_NAME = "StudLabel"
local LABEL_SIZE = UDim2.fromOffset(170, 60)
local LABEL_OFFSET_EXTRA = 1.8
local LABEL_MAX_DISTANCE = 80
local LABEL_FONT = Enum.Font.FredokaOne

local NAME_TEXT_SIZE = 20
local NAME_POSITION_Y = 0
local NAME_HEIGHT = 24
local NAME_STROKE_TRANSPARENCY = 0.2

local RARITY_TEXT_SIZE = 14
local RARITY_POSITION_Y = 24
local RARITY_HEIGHT = 16
local RARITY_STROKE_TRANSPARENCY = 0.4

local SLOT_TEXT_SIZE = 13
local SLOT_POSITION_Y = 40
local SLOT_HEIGHT = 16
local SLOT_STROKE_TRANSPARENCY = 0.4

local SLOT_AVAILABLE_COLOR = Color3.fromRGB(130, 255, 150)
local SLOT_BLOCKED_COLOR = Color3.fromRGB(255, 90, 90)
local WHITE_COLOR = Color3.new(1, 1, 1)

local COLLECTED_BY_ATTRIBUTE = "CollectedBy"
local STUD_TYPE_ATTRIBUTE = "StudType"
local MUTATION_ATTRIBUTE = "Mutation"

--	Matches the delay the server waits before popping the back plate in.
local GHOST_TWEEN_INFO = TweenInfo.new(GameConfig.PickupFlightTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local GHOST_SCALE = 0.1
local GHOST_TRANSPARENCY = 0.6

-- Variables
local StudAnimatorClient = {}

local studEntries: { [BasePart]: StudEntry } = {}
local carriedUnits = 0
local capacityLevel = 0
local phaseRandom = Random.new()

-- Private functions
local function getMutationInfo(mutationName: string?)
	if mutationName == nil then
		return nil
	end
	for _, mutationInfo in GameConfig.Mutations do
		if mutationInfo.name == mutationName then
			return mutationInfo
		end
	end
	return nil
end
local function splitCamelCase(rawName: string): string
	return (rawName:gsub("(%l)(%u)", "%1 %2"))
end

local function updateSlotLabel(studEntry: StudEntry)
	local slotLabel = studEntry.SlotLabel
	local studUnits = studEntry.Units
	if not slotLabel or not studUnits then
		return
	end

	local freeCapacity = GameConfig.getCapacity(capacityLevel) - carriedUnits
	if studUnits <= freeCapacity then
		slotLabel.Text = if studUnits == 1 then "1 SLOT" else `{studUnits} SLOTS`
		slotLabel.TextColor3 = SLOT_AVAILABLE_COLOR
	else
		slotLabel.Text = `NEEDS {studUnits} SLOTS`
		slotLabel.TextColor3 = SLOT_BLOCKED_COLOR
	end
end

local function updateAllSlotLabels()
	for _, studEntry in studEntries do
		updateSlotLabel(studEntry)
	end
end

local function createStudLabel(studEntry: StudEntry, studTypeName: string, studTypeInfo: any, mutationName: string?)
	local studPart = studEntry.Part

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = LABEL_NAME
	billboardGui.Size = LABEL_SIZE
	billboardGui.StudsOffset = Vector3.new(0, studPart.Size.Y / 2 + LABEL_OFFSET_EXTRA, 0)
	billboardGui.MaxDistance = LABEL_MAX_DISTANCE
	billboardGui.LightInfluence = 0
	billboardGui.Adornee = studPart

	local mutationInfo = getMutationInfo(mutationName)

	local displayName = splitCamelCase(studTypeName)
	if mutationName then
		displayName = `{mutationName} {displayName}`
	end

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(0, NAME_POSITION_Y)
	nameLabel.Size = UDim2.new(1, 0, 0, NAME_HEIGHT)
	nameLabel.Font = LABEL_FONT
	nameLabel.TextSize = NAME_TEXT_SIZE
	nameLabel.TextStrokeTransparency = NAME_STROKE_TRANSPARENCY
	nameLabel.Text = displayName
	nameLabel.TextColor3 = if mutationInfo then mutationInfo.highlight else WHITE_COLOR
	nameLabel.Parent = billboardGui

	local rarityText = tostring(studTypeInfo.rarity)
	if mutationInfo then
		local oddsDenominator = math.floor(1 / mutationInfo.chance + 0.5)
		rarityText = `{rarityText} • 1 in {oddsDenominator}`
	end

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Position = UDim2.fromOffset(0, RARITY_POSITION_Y)
	rarityLabel.Size = UDim2.new(1, 0, 0, RARITY_HEIGHT)
	rarityLabel.Font = LABEL_FONT
	rarityLabel.TextSize = RARITY_TEXT_SIZE
	rarityLabel.TextStrokeTransparency = RARITY_STROKE_TRANSPARENCY
	rarityLabel.Text = rarityText
	rarityLabel.TextColor3 = GameConfig.RarityColors[studTypeInfo.rarity] or WHITE_COLOR
	rarityLabel.Parent = billboardGui

	local slotLabel = Instance.new("TextLabel")
	slotLabel.Name = "SlotLabel"
	slotLabel.BackgroundTransparency = 1
	slotLabel.Position = UDim2.fromOffset(0, SLOT_POSITION_Y)
	slotLabel.Size = UDim2.new(1, 0, 0, SLOT_HEIGHT)
	slotLabel.Font = LABEL_FONT
	slotLabel.TextSize = SLOT_TEXT_SIZE
	slotLabel.TextStrokeTransparency = SLOT_STROKE_TRANSPARENCY
	slotLabel.TextColor3 = SLOT_AVAILABLE_COLOR
	slotLabel.Parent = billboardGui

	billboardGui.Parent = studPart

	studEntry.NameLabel = nameLabel
	studEntry.SlotLabel = slotLabel
end

local function onStudAdded(studInstance: Instance)
	if not studInstance:IsA("BasePart") then
		return
	end
	if not studInstance:IsDescendantOf(workspace) then
		return
	end
	if studEntries[studInstance] then
		return
	end

	local mutationName = studInstance:GetAttribute(MUTATION_ATTRIBUTE)
	if typeof(mutationName) ~= "string" then
		mutationName = nil
	end

	local studEntry: StudEntry = {
		Part = studInstance,
		BaseCFrame = studInstance.CFrame,
		PhaseOffset = phaseRandom:NextNumber(0, math.pi * 2),
		IsFrozen = mutationName == "Frozen",
		IsRainbow = mutationName == "Rainbow",
	}

	local studTypeName = studInstance:GetAttribute(STUD_TYPE_ATTRIBUTE)
	if typeof(studTypeName) == "string" then
		local studTypeInfo = GameConfig.getStudType(studTypeName)
		if studTypeInfo then
			studEntry.Units = studTypeInfo.units
			createStudLabel(studEntry, studTypeName, studTypeInfo, mutationName)
		end
	end

	studEntries[studInstance] = studEntry
	updateSlotLabel(studEntry)
end

local function spawnCollectEffect(studEntry: StudEntry, collectorUserId: number)
	local collector = Players:GetPlayerByUserId(collectorUserId)
	local collectorCharacter = collector and collector.Character
	if not collectorCharacter then
		return
	end

	local torso = collectorCharacter:FindFirstChild("UpperTorso") or collectorCharacter:FindFirstChild("Torso")
	if not (torso and torso:IsA("BasePart")) then
		return
	end

	local studPart = studEntry.Part

	local ghostPart = Instance.new("Part")
	ghostPart.Name = "StudCollectGhost"
	ghostPart.Anchored = true
	ghostPart.CanCollide = false
	ghostPart.CanQuery = false
	ghostPart.CanTouch = false
	ghostPart.Material = Enum.Material.Neon
	ghostPart.Size = studPart.Size
	ghostPart.Color = studPart.Color
	ghostPart.CFrame = studEntry.BaseCFrame
	ghostPart.Parent = workspace

	local ghostTween = TweenService:Create(ghostPart, GHOST_TWEEN_INFO, {
		CFrame = torso.CFrame,
		Size = studPart.Size * GHOST_SCALE,
		Transparency = GHOST_TRANSPARENCY,
	})
	ghostTween.Completed:Once(function()
		ghostPart:Destroy()
	end)
	ghostTween:Play()
end

local function onStudRemoved(studInstance: Instance)
	if not studInstance:IsA("BasePart") then
		return
	end

	local studEntry = studEntries[studInstance]
	if not studEntry then
		return
	end
	studEntries[studInstance] = nil

	local collectorUserId = studInstance:GetAttribute(COLLECTED_BY_ATTRIBUTE)
	if typeof(collectorUserId) == "number" then
		spawnCollectEffect(studEntry, collectorUserId)
	end
end

local function onHeartbeat()
	local clockTime = os.clock()
	for studPart, studEntry in studEntries do
		local speedFactor = if studEntry.IsFrozen then FROZEN_SPEED_MULTIPLIER else 1
		local animationTime = clockTime + studEntry.PhaseOffset

		local bobOffset = math.sin(animationTime * BOB_SPEED * speedFactor) * BOB_HEIGHT
		local wobbleAngle = math.sin(animationTime * BOB_SPEED * WOBBLE_SPEED_MULTIPLIER * speedFactor) * WOBBLE_ANGLE
		local spinAngle = animationTime * SPIN_SPEED * speedFactor

		studPart.CFrame = studEntry.BaseCFrame
			* CFrame.new(0, bobOffset, 0)
			* CFrame.Angles(wobbleAngle, spinAngle, 0)

		if studEntry.IsRainbow then
			local rainbowColor = Color3.fromHSV(
				(animationTime * RAINBOW_HUE_SPEED) % 1,
				RAINBOW_SATURATION,
				RAINBOW_BRIGHTNESS
			)
			studPart.Color = rainbowColor
			local nameLabel = studEntry.NameLabel
			if nameLabel then
				nameLabel.TextColor3 = rainbowColor
			end
		end
	end
end

-- Start
function StudAnimatorClient:Run()
	CollectionService:GetInstanceAddedSignal(STUD_TAG):Connect(onStudAdded)
	CollectionService:GetInstanceRemovedSignal(STUD_TAG):Connect(onStudRemoved)
	for _, taggedInstance in CollectionService:GetTagged(STUD_TAG) do
		onStudAdded(taggedInstance)
	end

	RunService.Heartbeat:Connect(onHeartbeat)

	local replica = DataClient:WaitForReplica()
	carriedUnits = replica.Data.Carried or 0
	capacityLevel = if replica.Data.Upgrades then replica.Data.Upgrades.Capacity or 0 else 0
	updateAllSlotLabels()

	replica:ListenToChange({ "Carried" }, function(newValue)
		carriedUnits = newValue or 0
		updateAllSlotLabels()
	end)
	replica:ListenToChange({ "Upgrades", "Capacity" }, function(newValue)
		capacityLevel = newValue or 0
		updateAllSlotLabels()
	end)
end

return StudAnimatorClient
