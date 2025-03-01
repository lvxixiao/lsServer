local skynet = require "skynet"
local gateserver = require "snax.gateserver"

local server = {}

function server.start(conf)
    local handler = {}

    local CMD = {
        login = assert(conf.login_handler)
    }

    function handler.connect(fd, ipaddr)
        print("有客户端连接 connect fd", fd, "ipaddr", ipaddr)
    end

    function handler.disconnect(fd)
        print("客户端断开连接")
    end

    function handler.message(fd, msg, sz)
        print("有新的数据, 一个完整包 message, fd = ", fd, "msg=", msg, ", sz = ", sz)
    end

    function handler.error(fd, msg)
        print("error fd", fd, msg)
    end

    function handler.command(cmd, source, ...)
        local f = assert(CMD[cmd], cmd)
		return f(...)
    end
    -- todo: zf

    gateserver.start(handler)
end

return server