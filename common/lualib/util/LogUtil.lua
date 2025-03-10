local debug = require "debug"
function LOG_INFO(fmt, ...)
    print(fmt, ...)
end

function LOG_DEBUG(fmt, ...)
    local funcInfo = debug.getinfo(2) --显示调用DebugPrint的调用者信息
    local shortSrc = funcInfo.short_src or ""
    local funcName = funcInfo.name or ""
    local curLine = funcInfo.currentline or ""
    print(string.format("%s %s:%d", shortSrc, funcName, curLine), fmt, ...)
end

function LOG_ERROR(fmt, ...)
    print(fmt, ...)
end

function LOG_WARNING(fmt, ...)
    print(fmt, ...)
end