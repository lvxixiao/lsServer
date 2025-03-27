local skynet = require "skynet"
require "skynet.manager"
local snax = require "skynet.snax"
local GameGate = require "GameGate"
local crypt = require "skynet.crypt"
local server = {}
local connectIp = skynet.getenv("connectip")
local connectPort = skynet.getenv("connectport")
local inner_index = 0
local username_map = {}
local servername
local logiccenterNodeName = skynet.getenv("logiccenternode")

local agent_id = 0
local uid_agent = {}
local agents = {}
local maxAgent 
local perClientInAgent = 100 -- 100 client per agent

local function allocAgent()
	-- maxAgent = assert(tonumber(skynet.getenv("maxclient")) or 10000) / perClientInAgent
    -- todo: zf
    maxAgent = 1
	for _ = 1 , maxAgent do
		table.insert(agents, assert(snax.newservice("Agent")))
	end
end

--login server disallow multi login, so login_handler never be reentry
--call by login
function server.login_handler(uid, secret)
    LOG_INFO("login_handler", uid, secret)
    inner_index = inner_index + 1
    local subid = inner_index 
    -- todo: zf 检查是否在其他节点登录?
    local username = GameGate.username(uid, subid, servername)
    -- todo: zf 怎么阻止重复登录?
    -- todo: zf 这个节点如果不限制区服要怎么做?
    -- todo: zf 这个要保存???
    -- todo: zf 借助 redis, 登录时 uid 记录状态

    -- todo: zf nodename
    SnaxUtil.remoteCall(logiccenterNodeName, "AccountMgr", "checkRepetitionLogin", uid, servername, username)

    local agent
    if uid_agent[uid] then
        agent = uid_agent[uid]
    else
        agent_id = agent_id + 1
        agent = assert(agents[agent_id % maxAgent + 1], "not found valid agent")
        uid_agent[uid] = agent
    end
    agent.req.login(uid, subid, secret, username)
    local u = {
        username = username,
        secret = secret,
        uid = uid,
        subid = subid,
        agent = agent
    }
    assert(username_map[username] == nil)
    username_map[username] = u
    GameGate.login(username, secret)
    return connectIp, connectPort, subid
end

--call by agent
function server.logout_handler(fd, username, uid)

end

-- call by self (when socket disconnect)
function server.disconnect_handler(fd, username)
	local u = username_map[username]
	if u then
		u.agent.req.afk( skynet.self(), fd, username )
	end
end

function server.kick_handler(username)
    -- todo: zf 
end

-- call by self (when recv a request from client)
function server.request_handler(username, msg)
	local u = username_map[username]
	msg = string.pack('<d', username:len()) .. username .. msg
	return skynet.tostring(skynet.rawcall(u.agent.handle, "client", msg))
end

function server.register_handler(name)
    servername = name
    allocAgent()
end


skynet.register(SERVICE_NAME)

GameGate.start(server)