local skynet = require "skynet"
local crypt = require "skynet.crypt"

local client = {
    acceptChallenge = function(t, challenge)
        t.challenge = crypt.base64decode(challenge)
        t.ckey = crypt.randomkey()
        return crypt.base64encode(crypt.dhexchange(t.ckey))
    end,
    acceptSkey = function(t, skey)
        t.skey = crypt.base64decode(skey)
        t.secret = crypt.dhsecret(t.skey, t.ckey)
        return crypt.base64encode(crypt.hmac64(t.challenge, t.secret))
    end
}


local function auth()
    -- 1. 服务端生成8字节的随机串 challenge, 发给客户端用于握手验证
    local challenge = crypt.randomkey()
    local handshake = client.acceptChallenge(client, crypt.base64encode(challenge))
    -- 2. 客户端生成8字节的随机串 ckey(私钥), 然后通过 dhexchange 算法算出 ckey(公钥) 发给服务端
    local ckey = crypt.base64decode(handshake)
    -- 3. 服务端生成8字节的随机串 skey(私钥), 然后通过 dhexchange 算法算出 skey(公钥) 发给客户端
    local skey = crypt.randomkey()
    local response = client.acceptSkey(client, crypt.base64encode(crypt.dhexchange(skey)))
    -- 4. 双方用两个公钥通过算法 dhsecret 算出密钥, secret
    -- 5. 双方使用 hmac64 算法将 sectet 和 step1 的 challenge 算出 hmac, 交换然后对比, 一致则验证通过, 登录成功
    local secret = crypt.dhsecret(ckey, skey)
    local hmac = crypt.hmac64(challenge, secret)
    print("验证成功吗?", crypt.base64decode(response) == hmac)


end

skynet.start(function() 
    print("hello world")
    auth()
    
    --init login gate
    skynet.uniqueservice("Logind")

    skynet.exit()
end)