local U = require("wildwise/core/util")
local M = {}

local function take(budget)
    if budget.remaining <= 0 then
        return false
    end
    budget.remaining = budget.remaining - 1
    return true
end

-- 读取普通容器或当前口袋容器的主存储；主存储失效或禁止开启时返回 nil。
function M.readable(entity)
    local c = entity.components or {}
    local container = c.container
    if not container and c.container_proxy and U.call(c.container_proxy, "CanBeOpened") then
        local master = U.call(c.container_proxy, "GetMaster")
        container = U.valid(master) and master.components and master.components.container or nil
    end
    return container and container.canbeopened ~= false and container or nil
end

-- 在有界查询中匹配可见实体、可读容器及一层包裹快照；不解包、不生成或移动物品。
-- 容器权限由调用方先检查；禁止开启的容器不读取，递归层数和总访问量均有限制。
function M.matches(entity, prefab, budget, depth)
    depth = depth or 0
    if not U.valid(entity) or depth > 2 or not take(budget) then
        return false
    end
    if entity.prefab == prefab then
        return true
    end
    local c = entity.components or {}
    local bundle = c.unwrappable and c.unwrappable.itemdata
    if type(bundle) == "table" then
        for i = 1, math.min(#bundle, 40) do
            if not take(budget) then
                return false
            end
            if type(bundle[i]) == "table" and bundle[i].prefab == prefab then
                return true
            end
        end
    end
    local container = M.readable(entity)
    if container then
        for slot = 1, math.min(container.numslots or 0, 80) do
            if budget.remaining <= 0 then
                return false
            end
            if M.matches(container:GetItemInSlot(slot), prefab, budget, depth + 1) then
                return true
            end
        end
    end
    return false
end
return M
