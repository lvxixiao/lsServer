--[[
    监控服务, 心跳检测, 接受节点注册, 同步节点集群配置
]]
local skynet = require "skynet"
local snax = require "skynet.snax"
local cluster = require "skynet.cluster"
local Timer = require "Timer"
local thisNodeName
local clusterInfo = {}

local function broadcastClusterInfo()
    local syncAgain = false
    local timeout, ret
    for nodeName, nodeInfo in pairs(clusterInfo) do
        if nodeName ~= thisNodeName then
            timeout, ret = Common.runTimeout(2, SnaxUtil.remoteCall, nodeName, "MonitorSubscribe", "syncClusterInfo", clusterInfo)
            if timeout or not ret then --同步失败
                syncAgain = true
                clusterInfo[nodeName] = nil
            end
        end
    end

    Common.updateClusterConfig(clusterInfo)

    if syncAgain then
        broadcastClusterInfo()
    end
end

--comment 集群健康检查
local function clusterHold()
    local sync = false
    local now = os.time()
    for node, nodeInfo in pairs(clusterInfo) do
        if node ~= thisNodeName and nodeInfo.last + 6 < now then
            sync = true
            clusterInfo[node] = nil
            LOG_INFO(string.format("node(%s) not alive or can't connect, delete from cluster", node))
        end
    end

    if sync then
        broadcastClusterInfo()
    end
end

function init(selfNodeName)
    snax.enablecluster()
    cluster.register(SERVICE_NAME)
    thisNodeName = selfNodeName
    local ip = skynet.getenv("clusterip")
    local port = skynet.getenv("clusterport")
    clusterInfo[thisNodeName] = {ip = ip, port = tonumber(port)}

    Timer.runInterval(300, clusterHold)
end

local function checkNodeAlive(nodeName)
    local ok, address = pcall(cluster.query, nodeName, "MonitorSubscribe")
    return ok and address
end

function response.sync(remoteName, remoteIp, remotePort)
    LOG_INFO("节点开始注册", remoteName, remoteIp, remotePort)
    local tmpClusterInfo = table.simpleCopy(clusterInfo)
    tmpClusterInfo[remoteName] = {ip = remoteIp, port = tonumber(remotePort)}

    Common.updateClusterConfig(tmpClusterInfo)
    if checkNodeAlive(remoteName) then
        LOG_INFO("节点注册成功", remoteName, remoteIp, remotePort)
        clusterInfo[remoteName] = {ip = remoteIp, port = tonumber(remotePort), last = os.time()}
        -- 同步cluster配置到所有节点
        broadcastClusterInfo()
        return true
    else
        LOG_INFO("节点注册失败", remoteName, remoteIp, remotePort)
        Common.updateClusterConfig(clusterInfo)
        return false
    end
end

function response.heartbeat(remoteName)
    if not clusterInfo[remoteName] then
        return false
    end

    clusterInfo[remoteName].last = os.time()

    return true
end