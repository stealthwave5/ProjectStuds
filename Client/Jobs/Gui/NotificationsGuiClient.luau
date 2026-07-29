--[[
	Author(s): Josh, Claude
	Module: NotificationsGuiClient.luau
]]

-- Services

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Modules

local DataClient = shared("DataClient") ---@module DataClient
local FormatUtil = shared("FormatUtil") ---@module FormatUtil
local GetRemote = shared("GetRemote") ---@module GetRemote
local GuiStyles = shared("GuiStyles") ---@module GuiStyles
local ScreenGuisClient = shared("ScreenGuisClient") ---@module ScreenGuisClient
local ToastPane = shared("ToastPane") ---@module ToastPane
local TopHudGuiClient = shared("TopHudGuiClient") ---@module TopHudGuiClient

-- Constants

local HUD_DISPLAY_ORDER = 10
local BLOCKED_SOUND_ID = "rbxasset://sounds/button.wav"
local BLOCKED_SOUND_SPEED = 0.55
local COLLECT_SOUND_ID = "rbxasset://sounds/electronicpingshort.wav"
local SNAP_SOUND_ID = "rbxasset://sounds/snap.mp3"
local SOUND_VOLUME = 0.5
local FLOAT_TEXT_SIZE = 26
local FLOAT_DRIFT_PIXELS = 60
local FLOAT_SECONDS = 0.9
local FLOAT_JITTER_PIXELS = 18

-- Variables

local NotificationsGuiClient = {}

local PickupBlockedRemote = GetRemote("BackpackServer:PickupBlocked")
local RebirthResultRemote = GetRemote("RebirthServer:RebirthResult")
local SoldRemote = GetRemote("SellServer:Sold")

local HudScreenGui: ScreenGui? = nil
local Toast: ToastPane.ToastPane? = nil
local RandomObject = Random.new()

-- Private functions

local function playSound(soundId: string, playbackSpeed: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.Volume = SOUND_VOLUME
	sound.PlayOnRemove = true
	sound.Parent = SoundService
	sound:Destroy()
end

local function showToast(text: string, color: Color3)
	Toast:SetText(text)
	Toast:SetColor(color)
	Toast:Play()
end

---Spawns a green "+$X" TextLabel near the money pill that drifts up and fades.
local function createMoneyFloat(amount: number)
	local floatLabel = Instance.new("TextLabel")
	floatLabel.Name = "MoneyFloat"
	floatLabel.BackgroundTransparency = 1
	floatLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	floatLabel.Size = UDim2.fromOffset(200, 32)
	floatLabel.Font = GuiStyles.Fonts.Number
	floatLabel.TextSize = FLOAT_TEXT_SIZE
	floatLabel.TextColor3 = GuiStyles.Colors.Green
	floatLabel.Text = `+{FormatUtil:FormatLongCash(amount)}`
	floatLabel.ZIndex = 20

	local floatStroke = Instance.new("UIStroke")
	floatStroke.Color = GuiStyles.Colors.Stroke
	floatStroke.Thickness = 2
	floatStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	floatStroke.Parent = floatLabel

	--	Anchor under the money pill when available, otherwise top-center.
	local jitter = RandomObject:NextNumber(-FLOAT_JITTER_PIXELS, FLOAT_JITTER_PIXELS)
	local basePosition = UDim2.new(0.5, jitter, 0, 120)
	local topHudPane = TopHudGuiClient:GetPane()
	if topHudPane ~= nil then
		local moneyPillGui = topHudPane:GetMoneyPill().Gui :: GuiObject
		local pillPosition = moneyPillGui.AbsolutePosition
		local pillSize = moneyPillGui.AbsoluteSize
		basePosition = UDim2.fromOffset(
			pillPosition.X + pillSize.X * 0.5 + jitter,
			pillPosition.Y + pillSize.Y + FLOAT_TEXT_SIZE
		)
	end
	floatLabel.Position = basePosition
	floatLabel.Parent = HudScreenGui

	local floatTween = TweenService:Create(
		floatLabel,
		TweenInfo.new(FLOAT_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = basePosition + UDim2.fromOffset(0, -FLOAT_DRIFT_PIXELS),
			TextTransparency = 1,
		}
	)
	floatTween:Play()
	task.delay(FLOAT_SECONDS + 0.1, function()
		floatLabel:Destroy()
	end)
end

-- Start

function NotificationsGuiClient:Run()
	HudScreenGui = ScreenGuisClient:Create({
		Name = "Hud",
		DisplayOrder = HUD_DISPLAY_ORDER,
		Enabled = true,
	})

	Toast = ToastPane.new()
	Toast:SetGuiProperties({ Parent = HudScreenGui })

	RebirthResultRemote:OnClientEvent(function(result: { ok: boolean, msg: string })
		showToast(result.msg, GuiStyles.GetMessageColor(result.ok))
	end)

	PickupBlockedRemote:OnClientEvent(function()
		showToast("Backpack full! Go sell!", GuiStyles.Colors.Red)
		playSound(BLOCKED_SOUND_ID, BLOCKED_SOUND_SPEED)
	end)

	SoldRemote:OnClientEvent(function(info: { total: number, units: number, baseValue: number, multiplier: number })
		showToast(
			`Sold {info.units} studs for {FormatUtil:FormatLongCash(info.total)} (x{info.multiplier})!`,
			GuiStyles.Colors.Green
		)
	end)

	local replica = DataClient:WaitForReplica()

	replica:ListenToChange({ "Money" }, function(newMoney: number, oldMoney: number?)
		if oldMoney ~= nil and newMoney > oldMoney then
			createMoneyFloat(newMoney - oldMoney)
			playSound(COLLECT_SOUND_ID)
		end
	end)

	replica:ListenToChange({ "Carried" }, function(newCarried: number, oldCarried: number?)
		if oldCarried ~= nil and newCarried > oldCarried then
			playSound(SNAP_SOUND_ID)
		end
	end)
end

return NotificationsGuiClient
