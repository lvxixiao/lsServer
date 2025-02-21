local ClientLogic = require "logic.ClientLogic"
local socket = require "clientcore"
local crypt = require "client.crypt"

local loginip = "127.0.0.1"
local loginport = 8001
local token = "test:game1" --account:serverId

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

function ClientLogic:login()
    print("loginnnnnnnnnn")
    local fd = assert(socket.connect(loginip, loginport))

    local last = ""
    local function unpack_f(f)
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

    local readline = unpack_f(unpack_line)

    local challenge = crypt.base64decode(readline())
    print("recv challenge code:", challenge)
    local clientkey = crypt.randomkey()
    writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
    local secret = crypt.dhsecret(crypt.base64decode(readline()), clientkey)
    print("recv secret key:", secret)
    local hmac = crypt.hmac64(challenge, secret)
    writeline(fd, crypt.base64encode(hmac))
    writeline(fd, crypt.base64encode(crypt.desencode(secret, token)))

    local result = readline()
    print("recv result:", result)
    local code = tonumber(string.sub(result, 1, 3))
    print(code)
    assert(code == 200)
    socket.close(fd)

    local subid = crypt.base64decode(string.sub(result, 5))

    print("login ok, subid=", subid)
end