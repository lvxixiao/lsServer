local skynet = require "skynet"
local cluster = require "skynet.cluster"

local function initLuaService(selfNodeName)

    SM.InitServer.req.initClusterNode(selfNodeName)

    cluster.open(selfNodeName)

    SM.MonitorSubscribe.req.connectMasterAndPush(selfNodeName)
end

skynet.start(function() 
    local selfNodeName = skynet.getenv("clusternode") .. skynet.getenv("serverid")
    LOG_INFO("login_server启动", selfNodeName)
    --init lua server
    initLuaService(selfNodeName)

    --init login gate
    skynet.uniqueservice("Logind")

    skynet.exit()
end)