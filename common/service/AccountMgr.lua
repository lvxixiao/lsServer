--[[
    账号管理
]]

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