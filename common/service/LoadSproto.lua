local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local skynet = require "skynet"

function response.load()
    local filename = skynet.getenv("protocolpath")
	local f = io.open(filename, "r")
	local commonSprotoBlock = assert(f:read("*a"), "read commonsproto fail,path:" .. filename)
	f:close()

    local allSproto = commonSprotoBlock

    local slot = 0
    sprotoloader.save(sprotoparser.parse(allSproto), slot)

    LOG_INFO("加载 sproto 完成")
end