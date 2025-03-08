local rootpath = "../../../"
local svr =  rootpath .. "common/lualib/?.lua;".."./?.lua;" .. rootpath .. "3rd/skynet/lualib/?.lua;"

package.path = svr .. package.path
package.cpath = rootpath .. "3rd/skynet/luaclib/?.so;" .. rootpath .. "common/luaclib/?.so;" .. package.cpath 

require "LuaExt"

local ClientCommon = require "logic.ClientCommon"
local ClientLogic = require "logic.ClientLogic"
require "logic.ClientLoginLogic"

function ClientLogic:exit()
	os.exit()
end

local function reaLine()
	while true do
		local s = io.read()
		if s then
			return s
		end
	end
end

local function Run( ... )
    ClientCommon:initEvn()
    -- 实时交互模式
    while true do
        print("please input cmd:")
        local args = reaLine()
        local t = string.split(args, " ")
        local cmd = t[1]
        local f = ClientLogic[cmd]
        if f then
            table.remove(t, 1)
            local ok,err = pcall(f, ClientLogic, mode, table.unpack(t))
            if not ok then print(err) end
        else
            print("not found cmd<".. tostring(cmd) ..">! use <help> cmd for usage!")
        end
    end
end

Run( ... )
