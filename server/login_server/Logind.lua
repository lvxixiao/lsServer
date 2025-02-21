local login = require "LoginGate"
local crypt = require "skynet.crypt"
local skynet = require "skynet"

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
	print("auth_handler", token)
	local tokenInfo = string.split(token, ":")
	local account = tokenInfo[1]
	local selectNode = tokenInfo[2]
    if not account then
		error("auth_handler token err, not account")
	end

	local ret, err = SM.AccountMgr.req.Auth(account, selectNode)
	if ret then
		return serverId, account
	else
		error(err)
	end
end

--选择登录点
function server.login_handler(server, uid, secret)
	print(string.format("%s:%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
	
	-- todo: zf 这里通知游服 secret 和 uid,同时返回游服的 ip、port
	return 111
end

local CMD = {}

function server.command_handler(command, ...)
    local f = assert(CMD[command])
    return f(...)
end

login(server)