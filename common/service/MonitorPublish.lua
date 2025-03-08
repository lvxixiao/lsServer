--[[
    监控服务, 心跳检测, 接受节点注册, 同步节点集群配置
]]
local skynet = require "skynet"
local snax = require "skynet.snax"
local cluster = require "skynet.cluster"
local thisNodeName
local clusterInfo = {}

function init(selfNodeName)
    snax.enablecluster()
    cluster.register(SERVICE_NAME)
    thisNodeName = selfNodeName
    local ip = skynet.getenv("clusterip")
    local port = skynet.getenv("clusterport")
    clusterInfo[thisNodeName] = {ip = ip, port = tonumber(port)}

    -- todo: zf 开启定时心跳检查, 需要一个定时器
end

local function checkNodeAlive(nodeName)
    local ok, address = pcall(cluster.query, nodeName, "MonitorSubscribe")
    return ok and address
end

local function broadcastClusterInfo()
    for nodeName, _ in pairs(clusterInfo) do
        if nodeName ~= thisNodeName then
            LOG_INFO("broadcastClusterInfo", nodeName)
            SnaxUtil.remoteCall(nodeName, "MonitorSubscribe", "syncClusterInfo", clusterInfo)
        end
    end

    -- todo: zf 缺失败重试机制
end

function response.sync(remoteName, remoteIp, remotePort)
    LOG_INFO("节点开始注册", remoteName, remoteIp, remotePort)
    local tmpClusterInfo = table.simpleCopy(clusterInfo)
    tmpClusterInfo[remoteName] = {ip = remoteIp, port = tonumber(remotePort)}

    Common.updateClusterConfig(tmpClusterInfo)
    if checkNodeAlive(remoteName) then
        LOG_INFO("节点注册成功", remoteName, remoteIp, remotePort)
        clusterInfo[remoteName] = {ip = remoteIp, port = tonumber(remotePort)}
        -- 同步cluster配置到所有节点
        broadcastClusterInfo()
    else
        LOG_INFO("节点注册失败", remoteName, remoteIp, remotePort)
        Common.updateClusterConfig(tmpClusterInfo)
    end
end

--@comment 集群健康度检查
local function clusterHold()

end