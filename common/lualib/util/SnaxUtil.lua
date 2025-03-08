local SnaxUtil = {}

function SnaxUtil.getRemoteSrv(node, svrname)
    local cluster = require "skynet.cluster"
    local ok, address, snaxObj
    ok, address = pcall(cluster.query, node, svrname)
    if not ok then
		LOG_ERROR("cluster query node(%s) svrname(%s) fail:%s", node, svrname, address)
		return nil
	end
	ok,snaxObj = pcall(cluster.snax, node, svrname, address)
	if not ok then
		LOG_ERROR("cluster snax node(%s) svrname(%s) fail:%s", node, svrname, snaxObj)
		return nil
	end

	if snaxObj then
		return snaxObj
	else
		LOG_SKYNET("Common.getRemoteSvr,snax remote node:%s svr:%s fail", node, svrname)
        return nil
    end
end

function SnaxUtil.remoteCall(node, svrname, method, ...)
    local snaxObj = SnaxUtil.getRemoteSrv(node, svrname)
	if not snaxObj then
		LOG_ERROR("SnaxUtil remoteCall, fail, node(%s), svrname(%s) method(%s)", node, svrname, method)
		return nil
	end

	return snaxObj.req[method](...)
end

return SnaxUtil