local socket = require "skynet.socket"
local skynet = require "skynet"

local coroutine = coroutine
local error = error
local tostring = tostring

local readbytes = socket.read
local writebytes = socket.write

local sockethelper = {}
local socket_error = setmetatable({} , { 
	__tostring = function(self)
		local info = self.err_info
		self.err_info = nil
		return info or "[Socket Error]"
	end,

	__call = function (self, info)
		self.err_info = "[Socket Error] : " .. tostring(info)
		return self
	end
})

sockethelper.socket_error = socket_error

local function preread(fd, str)
	return function (sz)
		if str then
			if sz == #str or sz == nil then
				local ret = str
				str = nil
				return ret
			else
				if sz < #str then
					local ret = str:sub(1,sz)
					str = str:sub(sz + 1)
					return ret
				else
					sz = sz - #str
					local ret = readbytes(fd, sz)
					if ret then
						return str .. ret
					else
						error(socket_error("read failed fd = " .. fd))
					end
				end
			end
		else
			local ret = readbytes(fd, sz)
			if ret then
				return ret
			else
				error(socket_error("read failed fd = " .. fd))
			end
		end
	end
end

function sockethelper.readfunc(fd, pre)
	if pre then
		return preread(fd, pre)
	end
	return function (sz)
		local ret = readbytes(fd, sz)
		if ret then
			return ret
		else
			error(socket_error("read failed fd = " .. fd))
		end
	end
end

sockethelper.readall = socket.readall

function sockethelper.writefunc(fd)
	return function(content)
		local ok = writebytes(fd, content)
		if not ok then
			error(socket_error("write failed fd = " .. fd))
		end
	end
end

function sockethelper.connect(host, port, timeout)
	local fd, err
	local is_time_out = false
	if timeout then
		is_time_out = true
		local drop_fd
		local co = coroutine.running()
		-- asynchronous connect
		skynet.fork(function()
			fd, err = socket.open(host, port)
			if drop_fd then
				-- sockethelper.connect already return, and raise socket_error
				socket.close(fd)
			else
				-- socket.open before sleep, wakeup.
				is_time_out = false
				skynet.wakeup(co)
			end
		end)
		skynet.sleep(timeout)
		if not fd then
			-- not connect yet
			drop_fd = true
		end
	else
		is_time_out = false
		-- block connect
		fd = socket.open(host, port)
	end
	if fd then
		return fd
	end
	error(socket_error("connect failed host = " .. host .. ' port = '.. port .. ' timeout = ' .. tostring(timeout) .. ' err = ' .. tostring(err) .. ' is_time_out = '.. tostring(is_time_out)))
end

function sockethelper.close(fd)
	socket.close(fd)
end

function sockethelper.shutdown(fd)
	socket.shutdown(fd)
end

return sockethelper
