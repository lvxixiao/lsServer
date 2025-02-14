local login = require "snax.loginserver"
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
	local serverId = tokenInfo[2]
    if not account or not serverId then
		error("auth_handler token err, not account or serverId")
	end
	-- todo: zf
	return 1, 1
end

--选择登录点
function server.login_handler(server, uid, secret)
	print(string.format("%s:%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
	-- local gameserver = assert(server_list[server], "Unknown server")
	-- -- only one can login, because disallow multilogin
	-- local last = user_online[uid]
	-- if last then
	-- 	skynet.call(last.address, "lua", "kick", uid, last.subid)
	-- end
	-- if user_online[uid] then
	-- 	error(string.format("user %s is already online", uid))
	-- end

	-- local subid = tostring(skynet.call(gameserver, "lua", "login", uid, secret))
	-- user_online[uid] = { address = gameserver, subid = subid , server = server}
	-- return subid
	return 111
end

local CMD = {}

function server.command_handler(command, ...)
    local f = assert(CMD[command])
    return f(...)
end

login(server)