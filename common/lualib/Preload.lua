local snax = require "skynet.snax"

require "LuaExt"
require "util.LogUtil"
SnaxUtil = require "util.SnaxUtil"
Common = require "Common"

--获取保存SM的元表, server 不存在时，会自动 uniqueservice
SM = setmetatable(
    {}, {
        __index = function(self, key)
            local obj = snax.uniqueservice(key)
            rawset( self, key, obj )
            return obj
        end
    }
)