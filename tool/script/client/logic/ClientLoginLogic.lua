local ClientLogic = require "logic.ClientLogic"
local ClientCommon = require "logic.ClientCommon"
local socket = require "clientcore"
local crypt = require "client.crypt"

local loginip = "127.0.0.1"
local loginport = 8001
local account = "test"
local token = string.format("%s:%s", crypt.base64encode(account),crypt.base64encode("game1")) --account:serverId
local token1 = string.format("%s", crypt.base64encode(account)) --account:serverId

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

function ClientLogic:login()
    local function writeline(fd, text)
        socket.send(fd, text .. "\n")
    end

    local function unpack_line(text)
        local from = text:find("\n", 1, true)
        if from then
            return text:sub(1, from-1), text:sub(from+1)
        end
        return nil, text
    end

    local clientInfo = ClientCommon:connect(loginip, loginport)
    local fd = clientInfo.fd
    local challenge = crypt.base64decode(clientInfo:readline())
    local clientkey = crypt.randomkey()
    writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
    local secret = crypt.dhsecret(crypt.base64decode(clientInfo:readline()), clientkey)
    ClientCommon:setSecret(secret)
    local hmac = crypt.hmac64(challenge, secret)
    writeline(fd, crypt.base64encode(hmac))
    writeline(fd, crypt.base64encode(crypt.desencode(secret, token)))

    local result = clientInfo:readline()
    local code = tonumber(string.sub(result, 1, 3))
    assert(code == 200)
    ClientCommon:closeConnect()

    local ret = crypt.base64decode(string.sub(result, 5, #result))
    local connectip, connectport,gameNode,subid = ret:match "([^@]*)@(.*)@(.*)@(.*)"
    connectip = crypt.base64decode(connectip)
    connectport = crypt.base64decode(connectport)
    gameNode = crypt.base64decode(gameNode)
    subid = crypt.base64decode(subid)

    print(string.format("login ok, connectip=%s, connectport=%s, gameNode=%s, subid=%s", connectip, connectport, gameNode, subid))

    --登录 game
    local username = string.format("%s@%s@%s", 
        crypt.base64encode(account),
        crypt.base64encode(gameNode),
        crypt.base64encode(subid)
    )
    print("connect game username", username, gameNode, subid)

    clientInfo = ClientCommon:connect(connectip, connectport)
    fd = clientInfo.fd
    local index = 1
    socket.send(fd, string.pack(">s2",string.format("%s:%s:%s", 
        crypt.base64encode(username),
        tostring(index),
        crypt.base64encode(crypt.hmac64(crypt.hashkey(tostring(index)), secret))
        )))

    local gresult = clientInfo:readpackage()
    code = tonumber(string.sub(gresult, 1, 3))
    assert(code == 200, code)
    print("game login ok")

    local function send_package(fd, pack)
        local package = string.pack(">s2", pack)
        socket.send(fd, package)
    end
end

function ClientLogic:hello()
    local clientInfo = ClientCommon:getClientInfo()
    ClientCommon:sendpack(clientInfo.fd, ClientCommon:makeSprotoPack(
        ClientCommon:c2sRequest("Hello_Agent", {str = "hi agent"})
    ))

    ClientCommon:printRecvSproto()
end