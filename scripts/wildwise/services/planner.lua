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

-- 按贪心最近邻稳定排序已筛选的目标。
function M.nearest(targets, start)
    local pending, ordered = {}, {}
    for _, t in ipairs(targets) do
        pending[#pending + 1] = t
    end
    local x, z = start.x, start.z
    while #pending > 0 do
        local best, distance = 1, math.huge
        for i, target in ipairs(pending) do
            local tx, _, tz = target.Transform:GetWorldPosition()
            local d = (tx - x) ^ 2 + (tz - z) ^ 2
            if d < distance or (d == distance and target.GUID < pending[best].GUID) then
                best, distance = i, d
            end
        end
        local target = table.remove(pending, best)
        ordered[#ordered + 1] = target
        local tx, _, tz = target.Transform:GetWorldPosition()
        x, z = tx, tz
    end
    return ordered
end
return M
