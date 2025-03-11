--[[
    接收集群配置修改、心跳请求、连接 master 服务
]]
local skynet = require "skynet"
local snax = require "skynet.snax"
local cluster = require "skynet.cluster"
local Timer = require "Timer"
local masterNodeName
local selfNodeName
local clusterInfo

--comment 集群健康检查
local function clusterHold()
    local timeout, ret = Common.runTimeout(5, SnaxUtil.remoteCall, masterNodeName, "MonitorPublish", "heartbeat", selfNodeName)
    if timeout or not ret then
        -- 重连
        snax.self().req.connectMasterAndPush(selfNodeName, true)
    end
end

function init()
    snax.enablecluster()
    cluster.register(SERVICE_NAME)
    masterNodeName = skynet.getenv("masternode")
end

--comment 把自己的节点信息发到 master 节点
function response.connectMasterAndPush(nodeName, reconnect)
    local ip = skynet.getenv("clusterip")
    local port = skynet.getenv("clusterport")
    selfNodeName = nodeName
    local connectRet
    while not connectRet do
        _, connectRet = Common.runTimeout(10, SnaxUtil.remoteCall, masterNodeName, "MonitorPublish", "sync", nodeName, ip, port)
        if not connectRet then
            LOG_ERROR("can't connect master")
            skynet.sleep(100)
        end
    end

    if not reconnect then
        Timer.runInterval(300, clusterHold)
    end
end

function response.syncClusterInfo(info)
    LOG_INFO("收到了节点的集群配置", table.dump(info))
    Common.updateClusterConfig(info)
    clusterInfo = info

    return true
end

-- 检查节点的配置是否存在
function response.NodeIsExist(nodeName)
    if clusterInfo and clusterInfo[nodeName] then
        return true
    end
    
    return false
end