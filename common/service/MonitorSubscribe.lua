--[[
    接收集群配置修改、心跳请求、连接 master 服务
]]
local skynet = require "skynet"
local snax = require "skynet.snax"
local cluster = require "skynet.cluster"
local masterNodeName
local clusterInfo

function init()
    snax.enablecluster()
    cluster.register(SERVICE_NAME)
    masterNodeName = skynet.getenv("masternode")
end

function response.connectMasterAndPush(selfNodeName)
    -- 把自己的节点信息发到 master 节点
    local ip = skynet.getenv("clusterip")
    local port = skynet.getenv("clusterport")
    LOG_INFO("通知 master ip port", ip, port)
    -- cluster.snax(masterNodeName, "MonitorPublish")
    SnaxUtil.remoteCall(masterNodeName, "MonitorPublish", "sync", selfNodeName, ip, port)

    -- todo: zf 缺失败重试
end

function response.syncClusterInfo(info)
    -- todo: zf 这个逻辑重复了
    LOG_INFO("收到了节点的集群配置", table.dump(info))
    Common.updateClusterConfig(info)
    clusterInfo = info
end

-- 检查节点的配置是否存在
function response.NodeIsExist(nodeName)
    LOG_INFO("response.NodeIsExist", clusterInfo[nodeName], nodeName)
    if clusterInfo and clusterInfo[nodeName] then
        return true
    end
    
    return false
end