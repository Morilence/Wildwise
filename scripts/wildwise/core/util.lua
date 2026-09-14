local M = {}

-- 将数值限制到闭区间。
function M.clamp(n, lo, hi)
    return math.max(lo, math.min(hi, n))
end

-- 检查是否为有限数值，排除 NaN 和正负无穷。
function M.finite(n)
    return type(n) == "number" and n == n and n > -math.huge and n < math.huge
end

-- 按字节预算截取 UTF-8 文本；不把多字节字符截成无效的半个字符。
function M.textlimit(value, limit)
    if #value <= limit then
        return value
    end
    local stop = limit
    while stop > 0 and value:byte(stop + 1) >= 128 and value:byte(stop + 1) < 192 do
        stop = stop - 1
    end
    return value:sub(1, stop)
end

-- 检查实体引用仍然有效；不持有或重建实体。
function M.valid(e)
    return e ~= nil and e.IsValid ~= nil and e:IsValid()
end

-- 计算键值表的条目数。
function M.count(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

-- 浅拷贝字段表，供每个订阅独立过滤。
function M.copy(t)
    local out = {}
    for k, v in pairs(t or {}) do
        out[k] = v
    end
    return out
end

-- 深拷贝有界、无循环的配置与存档表，避免快照和运行状态互相修改。
-- 深拷贝无循环数据，隔离配置与存档快照。
function M.deepcopy(source)
    local out = {}
    for key, value in pairs(source) do
        out[key] = type(value) == "table" and M.deepcopy(value) or value
    end
    return out
end

-- 返回两实体的水平距离平方，避免热路径开平方。
function M.distance(a, b)
    local x, _, z = a.Transform:GetWorldPosition()
    local bx, _, bz = b.Transform:GetWorldPosition()
    return (x - bx) ^ 2 + (z - bz) ^ 2
end

-- 取得实体当前所在的平台；陆地返回 nil。
function M.platform(e)
    return e.GetCurrentPlatform and e:GetCurrentPlatform() or nil
end

-- 检查两实体是否位于同一平台或均在陆地。
function M.sameplatform(a, b)
    return M.platform(a) == M.platform(b)
end

-- 读取原版客户端表中的玩家屏蔽状态。
function M.muted(G, userid)
    local client = G.TheNet:GetClientTableForUser(userid)
    return client and client.muted == true or false
end

-- 仅在对象提供该方法时调用，并保留全部返回值。
function M.call(object, method, ...)
    if object and type(object[method]) == "function" then
        return object[method](object, ...)
    end
end

-- 记录返回值个数，保留中间及末尾的 nil。
function M.pack(...)
    return { n = select("#", ...), ... }
end

-- 返回排序后的键，保证展示顺序稳定。
function M.sortedkeys(t)
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end
return M
