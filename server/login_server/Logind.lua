local login = require "LoginGate"
local crypt = require "skynet.crypt"
local skynet = require "skynet"
local cluster = require "skynet.cluster"

local server = {
	host = "0.0.0.0",
	port = 8001,
	multilogin = false,	-- disallow multilogin
	name = "Logind",
    instance = 16
}

--验证token
-- return 玩家服务地址、uid
function server.auth_handler(token)
	local tokenInfo = string.split(token, ":")
	local account = tokenInfo[1]
	account = account and crypt.base64decode(account)
	local selectNode = tokenInfo[2]
	selectNode = selectNode and crypt.base64decode(selectNode)
	LOG_INFO("auth_handler", token, account, selectNode)
    if not account then
		error("auth_handler token err, not account")
	end

	local gameNode = SM.AccountMgr.req.auth(account, selectNode)
	if gameNode then
		return gameNode, account
	else
		LOG_ERROR("account auth fail", account)
		return
	end
end

--选择登录点
function server.login_handler(gameNode, uid, secret)
	LOG_INFO(string.format("%s:%s is login, secret is %s", uid, gameNode, crypt.hexencode(secret)))
	
	-- 检查 gameNode 是否存活

	-- todo: zf 这里通知游服 secret 和 uid,同时返回游服的 ip、port
	local connectIp, connectPort = cluster.call(gameNode, "Gamed", "login", uid, secret)
	local ret = string.format(
		"%s@%s", 
		crypt.base64encode(connectIp), 
		crypt.base64encode(connectPort)
	)
	-- todo: zf 这个是否需要加上 subid
	LOG_INFO("server.login_handler", "notify game sucess", connectIp, connectPort, ret)
	return ret
end

local CMD = {}

function server.command_handler(command, ...)
    local f = assert(CMD[command])
    return f(...)
end

login(server)