local skynet = require "skynet"

skynet.start(function() 
    print("login_server启动")
    --init login gate
    skynet.uniqueservice("Logind")

    skynet.exit()
end)