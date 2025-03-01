local skynet = require "skynet"
require "skynet.manager"
local GameGate = require "GameGate"
local server = {}
local connectIp = skynet.getenv("connectip")
local connectPort = skynet.getenv("connectport")

--login server disallow multi login, so login_handler never be reentry
--call by login
function server.login_handler(_, uid, secret)
    LOG_INFO("login_handler", uid, secret)

    -- todo: zf 检查是否在其他节点登录?

    return connectIp, connectPort
end


skynet.register(SERVICE_NAME)

GameGate.start(server)