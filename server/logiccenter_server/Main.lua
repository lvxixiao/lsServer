--[[
    全局逻辑进程, 全集群唯一
    负责:
        1.记录登录状态, 防止重复登录
]]
local skynet = require "skynet"
local cluster = require "skynet.cluster"

local function initLuaService(selfNodeName)

    SM.InitServer.req.initClusterNode(selfNodeName)

    cluster.open(selfNodeName)

    SM.MonitorSubscribe.req.connectMasterAndPush(selfNodeName)

end

skynet.start(function() 
    local selfNodeName = skynet.getenv("clusternode")
    LOG_INFO("logiccenter 启动", selfNodeName)
    --init lua server
    initLuaService(selfNodeName)

    skynet.exit()
end)