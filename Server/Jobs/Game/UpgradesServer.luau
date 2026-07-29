--[[
	Author(s): Josh, Claude
	Module: UpgradesServer.luau
--]]

-- Modules
local GameConfig = shared("GameConfig") ---@module GameConfig
local GetRemote = shared("GetRemote") ---@module GetRemote
local PlayerAddedUtil = shared("PlayerAddedUtil") ---@module PlayerAddedUtil
local PlayerDataServer = shared("PlayerDataServer") ---@module PlayerDataServer

-- Constants
local BASE_WALK_SPEED = 16

local UpgradesServer = {}

-- Variables
local BuyRemote = GetRemote("UpgradesServer:Buy")
local BuyResultRemote = GetRemote("UpgradesServer:BuyResult")

-- Private functions

function UpgradesServer:_sendResult(player: Player, ok: boolean, msg: string, upgradeName: string?)
	BuyResultRemote:FireClient(player, { ok = ok, msg = msg, upgradeName = upgradeName })
end

function UpgradesServer:_onBuy(player: Player, upgradeName: any)
	if type(upgradeName) ~= "string" then
		self:_sendResult(player, false, "Invalid upgrade")
		return
	end
	local upgradeConfig = GameConfig.Upgrades[upgradeName]
	if upgradeConfig == nil then
		self:_sendResult(player, false, "Invalid upgrade")
		return
	end
	local replica = PlayerDataServer:GetReplica(player)
	if replica == nil then
		return
	end

	local level = replica.Data.Upgrades[upgradeName]
	if level >= upgradeConfig.maxLevel then
		self:_sendResult(player, false, "Max level reached!", upgradeName)
		return
	end
	local cost = GameConfig.getUpgradeCost(upgradeName, level) :: number
	if replica.Data.Money < cost then
		self:_sendResult(player, false, "Not enough money!", upgradeName)
		return
	end

	replica:SetValue({ "Money" }, replica.Data.Money - cost)
	replica:SetValue({ "Upgrades", upgradeName }, level + 1)
	if upgradeName == "Speed" then
		self:ApplyWalkSpeed(player)
	end
	self:_sendResult(player, true, `{upgradeConfig.displayName} is now level {level + 1}`, upgradeName)
end

function UpgradesServer:_onCharacterAdded(player: Player, character: Model)
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid == nil then
			return
		end
		local replica = PlayerDataServer:WaitForReplica(player, 30)
		if replica == nil then
			return
		end
		self:ApplyWalkSpeed(player)
	end)
end

-- Public functions

---Re-applies WalkSpeed from the Speed upgrade level. Also used by
---RebirthServer after resetting upgrades.
function UpgradesServer:ApplyWalkSpeed(player: Player)
	local replica = PlayerDataServer:GetReplica(player)
	if replica == nil then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end
	local walkSpeedPerLevel = GameConfig.Upgrades.Speed.walkSpeedPerLevel :: number
	humanoid.WalkSpeed = BASE_WALK_SPEED + replica.Data.Upgrades.Speed * walkSpeedPerLevel
end

-- Start

function UpgradesServer:Init()
	BuyRemote:OnServerEvent(function(player: Player, upgradeName: any)
		self:_onBuy(player, upgradeName)
	end)
end

function UpgradesServer:Run()
	PlayerAddedUtil:Connect({
		Added = function(player: Player)
			player.CharacterAdded:Connect(function(character: Model)
				self:_onCharacterAdded(player, character)
			end)
			if player.Character then
				self:_onCharacterAdded(player, player.Character)
			end
		end,
	})
	PlayerDataServer.PlayerReady:Connect(function(player: Player)
		self:ApplyWalkSpeed(player)
	end)
end

return UpgradesServer
