--[[
    中心进程, 全集群唯一
    负责
        1.集群的健康度检查
        2.有节点上线时通知其他节点
]]
local skynet = require "skynet"
local snax = require "skynet.snax"
local cluster = require "skynet.cluster"

local function initLuaService(selfNodeName)

    SM.InitServer.req.initClusterNode(selfNodeName)

    cluster.open(selfNodeName)

    snax.uniqueservice("MonitorPublish", selfNodeName)
end

skynet.start(function() 
    LOG_INFO("master_server启动")
    local selfNodeName = skynet.getenv("clusternode")

    --init lua server
    initLuaService(selfNodeName)

    skynet.exit()
end)