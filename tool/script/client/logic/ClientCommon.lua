local socket = require "clientcore"
local crypt = require "client.crypt"
local sprotoloader = require "sprotoloader"
local sprotoparser = require "sprotoparser"
local ClientCommon = {}

local G_Scrypt
local clientInfo --{fd, session, sprotoSession, scrypt, readline, readpackage}

function ClientCommon:initEvn()
    local filename = "../../../common/protocol/Protocol.sproto"
	local f = io.open(filename, "r")
	local commonSprotoBlock = assert(f:read("*a"), "read commonsproto fail,path:" .. filename)
	f:close()

    local allSproto = commonSprotoBlock

    sprotoloader.save(sprotoparser.parse(allSproto), 0)

	ClientCommon._S2C_Push = sprotoloader.load(0):host "package"
	ClientCommon._S2C_Sender = ClientCommon._S2C_Push:attach(sprotoloader.load(0))
end

function ClientCommon:c2sRequest( protocolName, args )
    clientInfo.sprotoSession = clientInfo.sprotoSession + 1
	return ClientCommon._S2C_Sender( protocolName, args, clientInfo.sprotoSession)
end

function ClientCommon:printRecvSproto()
	local rawMsg = clientInfo:readpackage()
	local success = string.byte(rawMsg, -5)
	local gsession = string.sub(rawMsg, -4, -1)
	local protoMsg = string.sub(rawMsg, 1, #rawMsg-5)
	protoMsg = crypt.desdecode(G_Scrypt, protoMsg)
	local _, session, message, responser = ClientCommon._S2C_Push:dispatch(protoMsg)
	if message.content then
		for _, v in ipairs(message.content) do
			local _, session, pb = ClientCommon._S2C_Push:dispatch(v.message)
			print("response", table.dump(pb))
		end
	else
		print("unknown response, maybe service push", session, table.dump(message))
	end
end

function ClientCommon:makeSprotoPack( msg )
	local req = {  }
	req.content = {}
	table.insert(req.content, { message = msg } )
	return crypt.desencode(G_Scrypt, self:c2sRequest("GateMessage", req) )
end

function ClientCommon:sendpack(fd, msg)
	clientInfo.session = clientInfo.session + 1
	msg = msg..string.pack('>I4', clientInfo.session)
	
	local package = string.pack('>s2', msg)
	return socket.send(fd, package)
end

function ClientCommon:setSecret(secret)
    G_Scrypt = secret
end

function ClientCommon:getSecret()
    return G_Scrypt
end

function ClientCommon:connect(ip, port)
	local function unpack_package(text)
		local size = #text
		if size < 2 then
			return nil, text
		end
		local s = text:byte(1) * 256 + text:byte(2)
		if size < s+2 then
			return nil, text
		end
	
		return text:sub(3,2+s), text:sub(3+s)
	end

	local function unpack_line(text)
        local from = text:find("\n", 1, true)
        if from then
            return text:sub(1, from-1), text:sub(from+1)
        end
        return nil, text
    end
	
	local function unpack_f(f, fd, last)
		local function try_recv(fd, last)
			local result
			result, last = f(last)
			if result then
				return result, last
			end
			local r = socket.recv(fd)
			if not r then
				return nil, last
			end
			if r == "" then
				error "Server closed"
			end
			return f(last .. r)
		end
	
		return function()
			while true do
				local result
				result, last = try_recv(fd, last)
				if result then
					return result
				end
				socket.usleep(100)
			end
		end
	end

	local fd = assert(socket.connect(ip, port))

	clientInfo = {
		fd = fd, session = 0, sprotoSession = 0, last = "",
	}
	clientInfo.readline = unpack_f(unpack_line, clientInfo.fd, clientInfo.last)
	clientInfo.readpackage = unpack_f(unpack_package, clientInfo.fd, clientInfo.last)

	return clientInfo
end

function ClientCommon:closeConnect()
	if clientInfo then
		socket.close(clientInfo.fd)
		clientInfo = nil
	end
end

function ClientCommon:getClientInfo()
	return clientInfo
end


return ClientCommon