--[[
    账号管理
]]
local skynet = require "skynet"
local LoginStat = {
    LOGIN_OK = 1,
    GAME_OK = 2,
}
local accountInfoMap = {} --<uid, {uid, stat, node, username}

--- 验证账号
function response.auth(account, selectNode)
    LOG_INFO("AccountMgr auth", account, selectNode)
    -- todo: zf 验证 account 是否存在, 不存在则创建
    -- 验证所选 selectNode 是否是存在的节点, 如果没有 selectNode 则推荐一个
    if selectNode then
        if not SM.MonitorSubscribe.req.NodeIsExist(selectNode) then
            return 
        end
    else
        -- 选择一个登录节点 todo: zf
        return "game1"
    end

    return selectNode
end

-- todo: zf 有个问题, 某个节点down了, GAME_OK 状态还在怎么办?
-- 先查 game 节点在不在, 然后再查 Gamed 有没有这个人.
-- todo: zf 如果这个节点刚好断线了呢???, 连不上节点不给登录，防止极端情况下有两个玩家实体

--- 检查登录状态, 如果已经在线则踢出
-- call by Gamed
function response.checkRepetitionLogin(uid, nodeName, username)
    -- todo: zf 改成 username, 那登录怎么限制???分开???
    local info = accountInfoMap[uid]
    if info then
        if info.stat == LoginStat.GAME_OK then
            -- todo: zf
            SnaxUtil.remoteCall(info.node, "Gamed", "kick", username)
        end
        if info.stat == LoginStat.LOGIN_OK then
            -- todo: zf 
        end
    end
    accountInfoMap[uid] = {uid = uid, stat = LoginStat.GAME_OK, node = nodeName}
end

--- 
function response.gameLogin(uid)
end

skynet.register(SERVICE_NAME)