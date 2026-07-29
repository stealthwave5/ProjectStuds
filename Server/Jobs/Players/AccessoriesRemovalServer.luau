--
--            AccessoriesRemovalServer            - ScottFaber
--
--

local AccessoriesRemovalServer = {}

-- Services
local Players = game:GetService("Players")

-- Modules
local PlayerAddedUtil = shared("PlayerAddedUtil") ---@module PlayerAddedUtil

-- Types

-- Constants
local BACK_ATTACHMENTS = {
	BodyBackAttachment = true,
	WaistBackAttachment = true,
}

-- Variables

-- Private functions
local function isBackAccessory(accessory: Accessory): boolean
	if not accessory:IsA("Accessory") then
		return false
	end

	if accessory.AccessoryType == Enum.AccessoryType.Back then
		return true
	end

	local handle = accessory:FindFirstChild("Handle")
	if handle then
		for _, child in handle:GetChildren() do
			if child:IsA("Attachment") and BACK_ATTACHMENTS[child.Name] then
				return true
			end
		end
	end

	return false
end

local function onCharacterAdded(character: Model)
	print("Removing back accessories from character: ", character.Name, character:QueryDescendants("Accessory"))
	for _, accessory: Accessory in character:QueryDescendants("Accessory") do
		if isBackAccessory(accessory) == false then
			continue
		end

		accessory:Destroy()
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Accessory") and isBackAccessory(child) then
			child:Destroy()
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

-- Public functions

-- Start
function AccessoriesRemovalServer:Run()
	PlayerAddedUtil:Connect({
		Added = onPlayerAdded,
	})
end

return AccessoriesRemovalServer
