--[[
	Author(s): Gory
	Module: Retry.lua
--]]

local function retry(options, callback, ...)
	local doWarn = options.Warn ~= false
	local retryDelay = options.Delay
	local retryLimit = options.Limit or 3
	local retries = 0
	local packed = {}
	while true do
		if retryLimit and retries >= retryLimit then
			return false
		end
		packed = { pcall(callback, ...) }
		if packed[1] == true then
			break
		end
		if doWarn then
			warn(packed[2])
		end

		retries += 1
		if retryDelay then
			task.wait(retryDelay)
		end
	end
	return unpack(packed)
end

local function Retry<A..., R...>(
	options: {
		Async: boolean?,
		Delay: number?,
		Limit: number?,
		Warn: boolean?,
	},
	callback: (A...) -> R...,
	...: A...
)
	if options.Async == true then
		task.spawn(retry, options, callback, ...)
	else
		return retry(options, callback, ...)
	end
end

return Retry
