--[[
	Author(s): Gory
	Module: GetBranches.luau

	Return an array of places in this game using GetGamePlacesAsync.

	```lua
	--	Print all branches in this game.
	local branches = GetBranches()
	for index, branch in branches do
		print(`Branch "{branch.Name}" PlaceId: {branch.PlaceId}`)
	end
	```
--]]

local AssetService = game:GetService("AssetService")

local Signal = shared("Signal") ---@module Signal

export type Branch = {
	DisplayName: string, -- Original name.
	Main: boolean,
	Name: string, -- Name with symbols removed, for admin usage.
	PlaceId: number,
}

local Branches: { Branch }
local FetchingSignal: Signal.Signal

---Get branches in this game.
local function GetBranches(): { Branch }
	if Branches then
		return Branches -- This function ran already.
	end
	if FetchingSignal then
		-- 	This prevents doing the same thing twice if called.
		return FetchingSignal:Wait()
	end
	FetchingSignal = Signal.new()

	--	Collect all places from pages into an array.
	local allPlaces: { Branch } = {}
	local placePages: StandardPages = AssetService:GetGamePlacesAsync()

	while true do
		for index, placeInfo in placePages:GetCurrentPage() do
			table.insert(allPlaces, placeInfo)
		end
		if placePages.IsFinished then
			break
		end
		placePages:AdvanceToNextPageAsync()
	end

	for index, placeInfo in allPlaces do
		--	Removes non-alphnumeric characters, "Gory's Branch" -> "GorysBranch"
		--	Makes typing and autocompleting names easier.
		placeInfo.DisplayName = placeInfo.Name
		placeInfo.Name = string.gsub(placeInfo.Name, "[^%w]", "")
		-- placeInfo.Main = index == 1 -- First place is the starter place, guaranteed.
	end

	Branches = allPlaces
	FetchingSignal:Fire(Branches)
	return Branches
end

return GetBranches
