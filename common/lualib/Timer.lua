local skynet = require "skynet"

local idMap = {}
local idSeed = 0
local function newId()
    idSeed = idSeed + 1
    idMap[idSeed] = true
    return idSeed
end

local function recoverId(timerId)
    idMap[timerId] = nil
end

function Timer.CheckId(timerId)
    return idMap[timerId]
end

--@comment 注册 interval * 10 毫秒后触发, 持续触发
function Timer.runInterval(interval, f, ...)
    local timerid = newId()
	local args = {farg = {...}, timerid = timerid}

	local function run()
		if Timer.CheckId(args.timerid) then
			local ret, error = xpcall(f, debug.traceback, table.unpack(args.farg))
			if not ret then LOG_ERROR("runEvery error:%s", error) end
			skynet.timeout(interval, run)
		else
			recoverId(args.timerid)
		end
	end

	skynet.timeout(interval, run)
	return timerid
end