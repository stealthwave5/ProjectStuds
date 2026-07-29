--[[
	Author(s): Josh, Claude
	Module: SellPadClient.luau
]]

-- Services
local TweenService = game:GetService("TweenService")

-- Constants
local SELL_PAD_NAME = "SellPad"
local SELL_PAD_TIMEOUT = 10
local PULSE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local PULSE_TRANSPARENCY = 0.45

-- Variables
local SellPadClient = {}

-- Start
function SellPadClient:Run()
	local sellPad = workspace:WaitForChild(SELL_PAD_NAME, SELL_PAD_TIMEOUT)
	if not sellPad then
		warn(`[SellPadClient] {SELL_PAD_NAME} not found in Workspace`)
		return
	end
	if not sellPad:IsA("BasePart") then
		warn(`[SellPadClient] {SELL_PAD_NAME} is not a BasePart`)
		return
	end

	local pulseTween = TweenService:Create(sellPad, PULSE_TWEEN_INFO, {
		Transparency = PULSE_TRANSPARENCY,
	})
	pulseTween:Play()
end

return SellPadClient
