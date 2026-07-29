--[[
	Author(s): Gory
	Module: TouchUtil.luau
--]]

local Players = game:GetService("Players")

local Springer = shared("Springer") ---@module Springer

local TouchUtil = {}

local LocalPlayer = Players.LocalPlayer

function TouchUtil:ConnectLocal(part: BasePart, debounce: number, callback: (hit: Instance) -> ()): RBXScriptConnection
	local debounced = false
	local connection = part.Touched:Connect(function(hit)
		if hit.Parent ~= LocalPlayer.Character then
			return
		end
		if debounced then
			return
		end
		debounced = true
		task.spawn(callback, hit)
		task.wait(debounce)
		debounced = false
	end)
	return connection
end

function TouchUtil:ImpulsePart(part)
	Springer.impulse(part, { Speed = 10, Damper = 0.6 }, {
		Color = Color3.new(10, 10, 10),
		Size = Vector3.new(-10, -20, -10),
	})
end

function TouchUtil:ImpulseCylinder(part)
	Springer.impulse(part, { Speed = 10, Damper = 0.6 }, {
		Color = Color3.new(10, 10, 10),
		Size = Vector3.new(-20, -10, -10),
	})
end

function TouchUtil:Run() end

return TouchUtil
