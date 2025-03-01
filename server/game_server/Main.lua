local skynet = require "skynet"
local cluster = require "skynet.cluster"

local function initLuaService(selfNodeName)

    SM.InitServer.req.initClusterNode(selfNodeName)

    cluster.open(selfNodeName)

    SM.MonitorSubscribe.req.connectMasterAndPush(selfNodeName)
end

skynet.start(function() 
    local selfNodeName = skynet.getenv("clusternode") .. skynet.getenv("serverid")
    LOG_INFO("game_server启动", selfNodeName)
    --init lua server
    initLuaService(selfNodeName)

    -- init gate(begin listen)
    local Gamed = skynet.uniqueservice("Gamed")
    skynet.call(Gamed, "lua", "open", {
        maxclient = tonumber(skynet.getenv("maxclient")) or 1024,
        port = tonumber(skynet.getenv("port")) or 8888,
    })

    skynet.exit()
end)

-- todo: zf 好像需要一个 master