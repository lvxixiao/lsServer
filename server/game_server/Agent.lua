local skynet = require "skynet"
local crypt = require "skynet.crypt"
local sprotoloader = require "sprotoloader"

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
    }
end

local function msgUnpack(msg)
    local len = string.unpack('<d', msg)
	msg = msg:sub(9)
	local username = msg:sub(1,len)
	msg = msg:sub(len+1)
	LOG_DEBUG("msgUnpack", username, AgentNames[username].secret, type(msg))
	local rawMsg = crypt.desdecode(AgentNames[username].secret, msg)
	local type, protoname, message, responser =  _C2S_Request:dispatch(rawMsg)
	if protoname == "GateMessage" then
		-- todo: zf GateMessage 内容的循环处理
		-- todo: zf 怎么回复客户端
	else
		LOG_DEBUG("msgUnpack", "protoname", protoname, table.dump(message))
	end
end

function init()
	-- client protocol
	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = skynet.tostring,
		dispatch = function (_, _, msg)
            msgUnpack(msg)
			skynet.ret("true")
		end
	}

	local slot = 0
	_C2S_Request = sprotoloader.load(slot):host "package"
	_S2C_Push = _C2S_Request:attach(sprotoloader.load(0))
end