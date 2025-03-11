local Common = {}

function Common.getSelfNodeName()
    -- todo: zf 返回节点名字, master 节点会特殊点
	local skynet = require "skynet"
	local selfNodeName = skynet.getenv("clusternode")
	if selfNodeName ~= "master" then
		return selfNodeName .. skynet.getenv("serverid")
	else
		return selfNodeName
	end
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

--comment 执行函数,进行超时判断
--@param timeout integer 超时秒数
--@param f function 执行的函数
--@param ... any 参数列表
--@return boolean true 为超时, 其他为非超时
function Common.runTimeout(timeout, f, ...)
	local co = coroutine.running()
    local ret, data
    local skynet = require "skynet"
    local funcArg = { ... }
    skynet.fork(function ()
        ret, data = pcall(f, table.unpack(funcArg))
        if co then skynet.wakeup(co) end
    end)

    skynet.sleep(timeout * 100)
    co = nil -- prevent wakeup after call
    if ret ~= nil then
        return nil,data
    end
    return true
end

return Common