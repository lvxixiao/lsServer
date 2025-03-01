local Common = {}

function Common.getSelfNodeName()
    -- todo: zf 返回节点名字
end

function Common.updateClusterConfig(clusterInfo)
    local skynet = require "skynet"
    local cluster = require "skynet.cluster"
    local f = io.open(skynet.getenv("cluster"),"w+")
	f:write("__nowaiting = true\n")
	local clusterNodeKey = {}
	for nodeName in pairs(clusterInfo) do
		table.insert( clusterNodeKey, nodeName )
	end
	table.sort( clusterNodeKey, function (a, b)
		return a < b
	end)

	for _, nodeName in pairs(clusterNodeKey) do
		local str = nodeName.."=\""..clusterInfo[nodeName].ip..":"..clusterInfo[nodeName].port.."\"\n"
		f:write(str)
	end

	f:close()
	cluster.reload()
end

return Common