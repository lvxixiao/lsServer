local skynet = require "skynet"
local cluster = require "skynet.cluster"

function response.initClusterNode(nodeName)
    local f = assert(io.open(skynet.getenv("cluster"),"w+"))
    f:write("__nowaiting = true\n")
    
    local clusterName = nodeName
    local clusterIp = skynet.getenv("clusterip")
    local clusterPort = skynet.getenv("clusterport")

    local config = clusterName.."=\""..clusterIp..":"..clusterPort.."\"\n"

    local masterName = skynet.getenv("masternode")
    if masterName ~= clusterName then
        local masterIp = skynet.getenv("masterip")
        local masterPort = skynet.getenv("masterport")
        config = config .. masterName.."=\"" ..masterIp..":"..masterPort.."\"\n"
    end

    f:write(config)
    
    f:close()

    cluster.reload()
end