--[[
	Author(s): Gory
	Module: FormatUtil.luau
--]]

local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local NumberLocalizationUtils = shared("NumberLocalizationUtils") ---@module NumberLocalizationUtils
local RoundingBehaviourTypes = shared("RoundingBehaviourTypes") ---@module RoundingBehaviourTypes
local String = shared("String") ---@module String
local TranslateClient = shared("TranslateClient") ---@module TranslateClient

local FormatUtil = {}

local ROUNDING = RoundingBehaviourTypes.TRUNCATE

function FormatUtil:FormatCash(cash: number): string
	local locale = TranslateClient:GetLocale()
	local format = NumberLocalizationUtils.abbreviate(cash, locale, ROUNDING, 3)
	return `${format}`
end

function FormatUtil:FormatLongCash(cash: number)
	return `${String.addCommas(cash, ",")}`
end

function FormatUtil:FormatIncome(income: number): string
	return `{self:FormatCash(income)}/s`
end

function FormatUtil:FormatTime(seconds: number)
	if seconds > 60 then
		local minutes = seconds // 60
		seconds %= 60
		if seconds == 0 then
			return string.format("%im", minutes)
		end
		return string.format("%im %02is", minutes, seconds)
	end
	return `{seconds}s`
end

function FormatUtil:FormatLongTimer(seconds: number): string
	local days = seconds // 86400
	seconds %= 86400

	local hours = seconds // 3600
	seconds %= 3600

	local minutes = seconds // 60
	seconds %= 60

	if days > 0 then
		return string.format("%id %ih %im %is", days, hours, minutes, seconds)
	elseif hours > 0 then
		return string.format("%ih %im %is", hours, minutes, seconds)
	elseif minutes > 0 then
		return string.format("%im %is", minutes, seconds)
	else
		return string.format("%is", seconds)
	end
end

function FormatUtil:FormatTimer(seconds: number)
	if seconds >= 60 then
		local minutes = seconds // 60
		seconds %= 60
		return string.format("%i:%02i", minutes, seconds)
	end
	return tostring(seconds)
end

function FormatUtil:FormatRobux(robux: number)
	if robux == nil then
		return `{GuiStyles.Unicodes.Robux} ?`
	end
	return `{GuiStyles.Unicodes.Robux}{String.addCommas(robux, ",")}`
end

function FormatUtil:FormatNumber(number: number)
	local locale = TranslateClient:GetLocale()
	local format = NumberLocalizationUtils.abbreviate(number, locale, ROUNDING, 3)
	return format
end

function FormatUtil:FormatNumberWithSpaces(number: number)
	return String.addCommas(number, " ")
end

function FormatUtil:FormatNumberWithCommas(number: number)
	return String.addCommas(number, ",")
end

return FormatUtil
