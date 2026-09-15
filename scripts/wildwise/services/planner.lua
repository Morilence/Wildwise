local U = require("wildwise/core/util")
local M = {}

-- 将用户区域向内对齐；不会为了补齐格子而在框选区域外部署。
-- 将区域向内对齐到原版网格，不越界补点。
function M.bounds(a, b, spacing, ox, oz)
    local ax = ox + math.ceil((math.min(a.x, b.x) - ox) / spacing) * spacing
    local az = oz + math.ceil((math.min(a.z, b.z) - oz) / spacing) * spacing
    local bx = ox + math.floor((math.max(a.x, b.x) - ox) / spacing) * spacing
    local bz = oz + math.floor((math.max(a.z, b.z) - oz) / spacing) * spacing
    if ax > bx or az > bz then
        return nil
    end
    return { x = ax, z = az }, { x = bx, z = bz }
end

-- 生成有界蛇形点序列，并为平台上的点保存局部坐标。
function M.grid(a, b, spacing, limit, validate, platform)
    if not U.finite(spacing) or spacing <= 0 then
        return nil, "invalid_spacing"
    end
    local minx, minz = math.min(a.x, b.x), math.min(a.z, b.z)
    local nx, nz = math.floor(math.abs(a.x - b.x) / spacing) + 1, math.floor(math.abs(a.z - b.z) / spacing) + 1
    if nx * nz > limit then
        return nil, "queue_limit"
    end
    local points = {}
    for row = 0, nz - 1 do
        for col = 0, nx - 1 do
            local x = minx + (row % 2 == 0 and col or (nx - 1 - col)) * spacing
            local point = { x = x, y = 0, z = minz + row * spacing }
            local record = { point = point, valid = validate(point), platform = platform }
            if platform then
                record.lx, record.ly, record.lz = platform.entity:WorldToLocalSpace(point.x, 0, point.z)
            end
            points[#points + 1] = record
        end
    end
    return points
end

-- 把计划点投影回世界；平台失效时返回 nil。
function M.project(record)
    if not record.platform then
        return record.point
    end
    if not U.valid(record.platform) then
        return nil
    end
    local x, y, z = record.platform.entity:LocalToWorldSpace(record.lx, record.ly, record.lz)
    return { x = x, y = y, z = z }
end

-- 先用有界最大堆选出最近 K 项，再规划路线；O(N log K + K²)，每个候选只读一次坐标。
-- accept 在读取坐标前过滤无关实体；内部调用默认也不允许规划超过 200 项。
function M.nearest(targets, start, limit, accept)
    limit = math.max(0, math.min(limit or 200, 200))
    if limit == 0 then
        return {}
    end
    local pending, ordered = {}, {}
    local function farther(a, b)
        return a.distance > b.distance or (a.distance == b.distance and a.target.GUID > b.target.GUID)
    end
    for _, target in ipairs(targets) do
        if U.valid(target) and (not accept or accept(target)) then
            local x, _, z = target.Transform:GetWorldPosition()
            local entry = { target = target, x = x, z = z, distance = (x - start.x) ^ 2 + (z - start.z) ^ 2 }
            if #pending < limit then
                local i = #pending + 1
                while i > 1 and farther(entry, pending[math.floor(i / 2)]) do
                    pending[i] = pending[math.floor(i / 2)]
                    i = math.floor(i / 2)
                end
                pending[i] = entry
            elseif farther(pending[1], entry) then
                local i = 1
                while i * 2 <= #pending do
                    local child = i * 2
                    if child < #pending and farther(pending[child + 1], pending[child]) then
                        child = child + 1
                    end
                    if not farther(pending[child], entry) then
                        break
                    end
                    pending[i], i = pending[child], child
                end
                pending[i] = entry
            end
        end
    end
    local x, z = start.x, start.z
    while #pending > 0 do
        local best, distance = 1, math.huge
        for i, entry in ipairs(pending) do
            local d = (entry.x - x) ^ 2 + (entry.z - z) ^ 2
            if d < distance or (d == distance and entry.target.GUID < pending[best].target.GUID) then
                best, distance = i, d
            end
        end
        local entry = pending[best]
        local last = #pending
        pending[best] = pending[last]
        pending[last] = nil
        ordered[#ordered + 1] = entry.target
        x, z = entry.x, entry.z
    end
    return ordered
end
return M
