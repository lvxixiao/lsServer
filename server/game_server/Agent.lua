local skynet = require "skynet"
local crypt = require "skynet.crypt"
local sprotoloader = require "sprotoloader"
local queue = require "skynet.queue"

local _C2S_Request
local _S2C_Push
local AgentNames = {}
-- todo: zf
--call by gated
function response.login(uid, subid, secret, username)
	LOG_DEBUG("agent login", uid, username, "secret", secret)
    assert(AgentNames[username] == nil)
    AgentNames[username] = {
        uid = uid,
        subid = subid,
        secret = secret,
		lock = queue(),
    }
end

--call by gated
function response.afk(_, fd, username)
	-- todo: zf 
end

local function msgUnpack(msg)
    local len = string.unpack('<d', msg)
	msg = msg:sub(9)
	local username = msg:sub(1,len)
	msg = msg:sub(len+1)
	LOG_DEBUG("msgUnpack", username, AgentNames[username].secret, type(msg))
	local rawMsg = crypt.desdecode(AgentNames[username].secret, msg)
	local _, _, sprotoMsg, responser =  _C2S_Request:dispatch(rawMsg)
	return sprotoMsg, responser, username
end

local function msgDispatch(sprotoMsg, responser, username)
	local subName, subMsg, subResponser
	local content = {}
	for _, rawMsg in ipairs(sprotoMsg.content) do
		_, subName, subMsg, subResponser = _C2S_Request:dispatch(rawMsg.message)
		LOG_DEBUG("接收到消息", subName, table.dump(subMsg))
		-- todo: zf 统一的处理消息函数
		-- todo: zf 错误处理
		local thisResp
		local responseMsg = {str = "hi client"}
		if responseMsg and subResponser then
			thisResp = {message = subResponser(responseMsg)}
		end

		if thisResp then
			content[#content + 1] = thisResp
		end
	end

	if #content > 0 then
		local ret = responser({content = content})
		return crypt.desencode(AgentNames[username].secret, ret)
	end
end

function init()
	-- client protocol
	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = skynet.tostring,
		dispatch = function (_, _, msg)
            local sprotoMsg, responser, username = msgUnpack(msg)
			-- skynet.ret(msgDispatch(sprotoMsg, responser, username))
			skynet.ret(AgentNames[username].lock(msgDispatch, sprotoMsg, responser, username))
		end
	}

	local slot = 0
	_C2S_Request = sprotoloader.load(slot):host "package"
	_S2C_Push = _C2S_Request:attach(sprotoloader.load(0))
end