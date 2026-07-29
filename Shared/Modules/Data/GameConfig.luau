--[[
	Author(s): Josh, Claude
	Module: GameConfig.luau
--]]

-- Types
export type StudTypeConfig = {
	name: string,
	units: number,
	baseValue: number,
	minDistance: number,
	rarity: string,
}

export type MutationConfig = {
	name: string,
	chance: number,
	multiplier: number,
	color: Color3?,
	material: Enum.Material,
	highlight: Color3,
}

export type UpgradeConfig = {
	displayName: string,
	baseCost: number,
	costMult: number,
	maxLevel: number,
	walkSpeedPerLevel: number?,
	capacityPerLevel: number?,
}

export type CashProductConfig = {
	productId: number,
	amount: number,
	displayName: string,
}

local GameConfig = {}

-- Constants
--	Spawn weighting used by the no-zones distance fallback (mirrors zone Weights 30/25/20/15/10/5).
local RARITY_WEIGHTS: { [string]: number } = {
	Common = 30,
	Uncommon = 25,
	Rare = 20,
	Epic = 15,
	Legendary = 10,
	Mythical = 5,
}

--[[
	Tuning values
]]

GameConfig.CoinCount = 80
GameConfig.CoinRespawnTime = 3
GameConfig.CoinBaseValue = 10
GameConfig.MapRange = 90
GameConfig.BaseCapacity = 10

--	How long a collected stud takes to fly onto the player's back. The client flies
--	the ghost stud and the server pops the matching back plate in off the same value.
GameConfig.PickupFlightTime = 0.32

GameConfig.Upgrades = {
	Speed = {
		displayName = "Walk Speed",
		baseCost = 100,
		costMult = 1.6,
		maxLevel = 10,
		walkSpeedPerLevel = 2,
	} :: UpgradeConfig,
	Value = {
		displayName = "Coin Value",
		baseCost = 250,
		costMult = 1.7,
		maxLevel = 25,
	} :: UpgradeConfig,
	Capacity = {
		displayName = "Backpack",
		baseCost = 150,
		costMult = 1.5,
		maxLevel = 20,
		capacityPerLevel = 5,
	} :: UpgradeConfig,
}

GameConfig.StudTypes = {
	{ name = "Stud", units = 1, baseValue = 10, minDistance = 0, rarity = "Common" },
	{ name = "DoubleStud", units = 2, baseValue = 25, minDistance = 40, rarity = "Uncommon" },
	{ name = "QuadStud", units = 4, baseValue = 60, minDistance = 65, rarity = "Rare" },
	{ name = "HexStud", units = 6, baseValue = 140, minDistance = 90, rarity = "Epic" },
	{ name = "GigaStud", units = 9, baseValue = 320, minDistance = 120, rarity = "Legendary" },
	{ name = "OmegaStud", units = 12, baseValue = 700, minDistance = 150, rarity = "Mythical" },
} :: { StudTypeConfig }

GameConfig.RarityColors = {
	Common = Color3.fromRGB(163, 162, 165),
	Uncommon = Color3.fromRGB(75, 151, 75),
	Rare = Color3.fromRGB(13, 105, 172),
	Epic = Color3.fromRGB(107, 50, 124),
	Legendary = Color3.fromRGB(255, 170, 40),
	Mythical = Color3.fromRGB(255, 85, 85),
}

GameConfig.Mutations = {
	{
		name = "Gold",
		chance = 0.07,
		multiplier = 5,
		color = Color3.fromRGB(255, 200, 40),
		material = Enum.Material.Metal,
		highlight = Color3.fromRGB(255, 220, 90),
	},
	{
		name = "Frozen",
		chance = 0.03,
		multiplier = 8,
		color = Color3.fromRGB(150, 220, 255),
		material = Enum.Material.Glass,
		highlight = Color3.fromRGB(180, 230, 255),
	},
	{
		--	Rainbow has no fixed color: the client hue-cycles any part with Mutation == "Rainbow".
		name = "Rainbow",
		chance = 0.01,
		multiplier = 20,
		material = Enum.Material.SmoothPlastic,
		highlight = Color3.fromRGB(255, 255, 255),
	},
} :: { MutationConfig }

GameConfig.RebirthBaseCost = 10_000
GameConfig.RebirthCostMult = 2

GameConfig.DoubleCashGamePassId = 0
GameConfig.CashProducts = {
	{ productId = 0, amount = 10_000, displayName = "10,000 Cash" },
	{ productId = 0, amount = 60_000, displayName = "60,000 Cash" },
	{ productId = 0, amount = 150_000, displayName = "150,000 Cash" },
} :: { CashProductConfig }

-- Public functions

function GameConfig.getStudType(name: string): StudTypeConfig?
	for _, studType in GameConfig.StudTypes do
		if studType.name == name then
			return studType
		end
	end
	return nil
end

--	60% biggest type eligible at this distance, 30% one tier down, 10% two down.
function GameConfig.getStudTypeForDistance(distance: number, rand: Random): StudTypeConfig
	local eligible = 1
	for index, studType in GameConfig.StudTypes do
		if distance >= studType.minDistance then
			eligible = index
		end
	end
	local roll = rand:NextNumber()
	local index
	if roll < 0.6 then
		index = eligible
	elseif roll < 0.9 then
		index = math.max(1, eligible - 1)
	else
		index = math.max(1, eligible - 2)
	end
	return GameConfig.StudTypes[index]
end

function GameConfig.getMutation(name: string): MutationConfig?
	for _, mutation in GameConfig.Mutations do
		if mutation.name == name then
			return mutation
		end
	end
	return nil
end

function GameConfig.rollMutation(rand: Random): MutationConfig?
	local roll = rand:NextNumber()
	local cumulative = 0
	for _, mutation in GameConfig.Mutations do
		cumulative += mutation.chance
		if roll < cumulative then
			return mutation
		end
	end
	return nil
end

function GameConfig.getUpgradeCost(name: string, level: number): number?
	local upgrade = GameConfig.Upgrades[name]
	if upgrade == nil then
		return nil
	end
	return math.floor(upgrade.baseCost * upgrade.costMult ^ level)
end

function GameConfig.getRebirthCost(rebirths: number): number
	return math.floor(GameConfig.RebirthBaseCost * GameConfig.RebirthCostMult ^ rebirths)
end

function GameConfig.getCapacity(capacityLevel: number): number
	local capacityPerLevel = GameConfig.Upgrades.Capacity.capacityPerLevel :: number
	return GameConfig.BaseCapacity + capacityPerLevel * capacityLevel
end

function GameConfig.getSellMultiplier(valueLevel: number, rebirths: number, hasDoubleCash: boolean?): number
	return (1 + valueLevel) * (1 + rebirths) * (if hasDoubleCash then 2 else 1)
end

return GameConfig
