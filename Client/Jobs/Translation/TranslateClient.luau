--[[
	Author(s): Gory
	Module: TranslateClient.luau
--]]

local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NumberLocalizationUtils = shared("NumberLocalizationUtils") ---@module NumberLocalizationUtils
local Retry = shared("Retry") ---@module Retry
local Signal = shared("Signal") ---@module Signal

local TranslateClient = {}
TranslateClient.LocaleChanged = Signal.new() :: Signal.Signal<string>
TranslateClient.TranslatorReady = Signal.new()
TranslateClient.Priority = 100

local DEBUG_MODE = true
local FALLBACK_LOCALE = "en-us"

local Locale = FALLBACK_LOCALE
local Running = RunService:IsRunning()
local Translator: Translator
local Ready = false

--[[
		Public Methods
]]

function TranslateClient:IsReady(): boolean
	return Ready
end

function TranslateClient:AbbreviateNumber(number: number, significantDigits: number?)
	assert(type(number) == "number")
	assert(significantDigits == nil or type(significantDigits) == "number")
	return NumberLocalizationUtils.abbreviate(number, Locale, "roundToClosest", significantDigits)
end

function TranslateClient:AddCommas(number: number)
	return NumberLocalizationUtils.localize(math.floor(number), Locale)
end

function TranslateClient:FormatByKey(key: string, args: {})
	self:_waitForReady()
	return Translator:FormatByKey(key, args)
end

function TranslateClient:FormatCooldown(remainingTime: number): string
	local numberLocale = NumberLocalizationUtils.LocaleInfos[Locale] or NumberLocalizationUtils.LocaleInfos["en-us"]
	local decimalSeparator = numberLocale.decimalSeparator

	local decimal = math.floor((remainingTime * 10) % 10)
	return string.format("%i%s%01i", math.floor(remainingTime), decimalSeparator, decimal)
end

function TranslateClient:FormatNumber(number: number): string
	assert(type(number) == "number")
	local text = NumberLocalizationUtils.localize(number, Locale)
	return text
end

function TranslateClient:GetLocale(): string
	return Locale
end

function TranslateClient:Translate(text: string, context: Instance?)
	assert(type(text) == "string")
	assert(context == nil or typeof(context) == "Instance")
	self:_waitForReady()
	return Translator and Translator:Translate(context or game, text) or text
end

--[[
		Private Methods
]]

function TranslateClient:_updateLocale()
	local locale = Translator.LocaleId
	if Locale == locale then
		return
	end
	Locale = locale
	self.LocaleChanged:Fire(Locale)
	if DEBUG_MODE then
		print(`[TranslateClient]: {locale}`)
	end
end

function TranslateClient:_waitForReady()
	if not self:IsReady() then
		self.TranslatorReady:Wait()
	end
end

--[[
		Setup
]]

function TranslateClient:_setupTranslator()
	local success
	success, Translator = Retry({ Delay = 0, Limit = 3, Warn = Running }, function()
		return LocalizationService:GetTranslatorForPlayerAsync(Players.LocalPlayer)
	end)
	if Translator == nil then
		success, Translator = Retry({ Delay = 0, Limit = 3 }, function()
			return LocalizationService:GetTranslatorForLocaleAsync(FALLBACK_LOCALE)
		end)
	end

	if type(Translator) == "string" then
		warn(`[TranslateClient]: {Translator}`)
		Translator = nil
	end

	if Translator ~= nil then
		Translator:GetPropertyChangedSignal("LocaleId"):Connect(function()
			self:_updateLocale()
		end)
		self:_updateLocale()
	end

	Ready = true
	self.TranslatorReady:Fire()
end

function TranslateClient:Init() -- Must run early, but not stall.
	task.spawn(function()
		self:_setupTranslator()
	end)
end

if not Running then -- Story.
	TranslateClient:Init()
end

return TranslateClient
