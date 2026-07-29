--!strict
--[=[
	@class RoundingBehaviourTypes
]=]

export type RoundingBehaviourType = "roundToClosest" | "truncate" | "None"

export type RoundingBehaviourTypeMap = {
	ROUND_TO_CLOSEST: "roundToClosest",
	TRUNCATE: "truncate",
	NONE: "none",
}

return table.freeze({
	ROUND_TO_CLOSEST = "roundToClosest",
	TRUNCATE = "truncate",
	NONE = "none",
} :: RoundingBehaviourTypeMap)
