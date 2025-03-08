local socket = require "clientcore"
local crypt = require "client.crypt"
local sprotoloader = require "sprotoloader"
local sprotoparser = require "sprotoparser"
local G_Session = 0
local G_SportoSession = 0
local G_Scrypt
local G_Fd

local ClientCommon = {}

function ClientCommon:initEvn()
    local filename = "../../../common/protocol/Protocol.sproto"
	local f = io.open(filename, "r")
	local commonSprotoBlock = assert(f:read("*a"), "read commonsproto fail,path:" .. filename)
	f:close()

    local allSproto = commonSprotoBlock

    sprotoloader.save(sprotoparser.parse(allSproto), 0)

	ClientCommon._S2C_Push = sprotoloader.load(0):host "package"
end

function ClientCommon:c2sRequest( protocolName, args )
    G_SportoSession = G_SportoSession + 1
    print("ClientCommon:c2sRequest", protocolName, args, G_SportoSession)
	return ClientCommon._S2C_Push:attach(sprotoloader.load(0))( protocolName, args, G_SportoSession)
end

function ClientCommon:makeSprotoPack( msg )
	local req = {  }
	req.content = {}
	table.insert(req.content, { networkMessage = msg } )
	return crypt.desencode(G_Scrypt, self:c2sRequest("GateMessage", req) )
end

function ClientCommon:sendpack(fd, msg, login)
	if login then
		msg = msg
		return socket.send(fd, msg)
	else
	
        G_Session = G_Session + 1
        msg = msg..string.pack('>I4', G_Session)
		
		local package = string.pack('>s2', msg)
		return socket.send(fd, package)
	end
end

function ClientCommon:setSecret(secret)
    G_Scrypt = secret
end

function ClientCommon:setFd(fd)
    G_Fd = fd
end

function ClientCommon:getFd()
    return G_Fd
end

return ClientCommon