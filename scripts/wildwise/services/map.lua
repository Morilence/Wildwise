local U = require("wildwise/core/util")
local Map = {}
Map.__index = Map
Map.VERSION = 1

-- 创建独立分世界地图状态，编号不使用运行期 GUID。
function Map.new(worldid)
    return setmetatable({
        worldid = tostring(worldid),
        next_pair = 1,
        next_ping = 1,
        pairs = {},
        endpoints = {},
        discoveries = {},
        pings = {},
        exploration = {},
        exploration_keys = {},
        preferences = {},
        revision = 0,
        load_error = nil,
        pair_views = {},
    }, Map)
end

-- 读取玩家共享偏好；未保存时返回默认开启值。
function Map:preferences_for(userid)
    return self.preferences[userid] or { position = true, exploration = true }
end

-- 修改当前世界的共享偏好；损坏存档状态拒绝写入。
function Map:set_preference(userid, key, value)
    if self.load_error then
        return false
    end
    if key ~= "position" and key ~= "exploration" then
        return false
    end
    local prefs = self:preferences_for(userid)
    prefs[key] = value == true
    self.preferences[userid] = prefs
    return true
end

-- 创建受类型、坐标、数量和有效期约束的临时标记。
function Map:add_ping(userid, kind, x, z, now)
    if self.load_error then
        return nil, "unsupported_save"
    end
    if
        not ({ location = true, danger = true, resource = true, rally = true })[kind]
        or not U.finite(x)
        or not U.finite(z)
        or math.abs(x) > 10000
        or math.abs(z) > 10000
    then
        return nil, "invalid_ping"
    end
    self:expire(now)
    local count = 0
    for _, ping in pairs(self.pings) do
        if ping.owner == userid then
            count = count + 1
        end
    end
    if count >= 5 then
        return nil, "ping_limit"
    end
    local id = self.next_ping
    self.next_ping = id + 1
    self.pings[id] = { id = id, owner = userid, kind = kind, x = x, z = z, expires = now + 60 }
    return id
end

-- 仅允许本人或管理员删除标记；管理员可用 0 清空。
function Map:delete_ping(userid, id, admin)
    if self.load_error then
        return false
    end
    if admin and id == 0 then
        self.pings = {}
        return true
    end
    local ping = self.pings[id]
    if ping and (ping.owner == userid or admin) then
        self.pings[id] = nil
        return true
    end
    return false
end

-- 移除到期临时标记；不把标记持久化。
function Map:expire(now)
    if self.load_error then
        return
    end
    for id, ping in pairs(self.pings) do
        if ping.expires <= now then
            self.pings[id] = nil
        end
    end
end

-- 端点身份来自坐标与设施类型；GUID 仅作当前运行期实体引用，绝不作为存档主键。
-- 以设施类型和坐标构造重启后稳定的端点键。
function Map.endpoint(prefab, x, z)
    return string.format("%s:%.2f:%.2f", prefab, x, z)
end

-- 登记实际旅行确认的配对；重连不改号，改连时替换旧配对。
function Map:discover(userid, a, b, shared)
    if self.load_error then
        return nil
    end
    if a.key == b.key then
        return nil
    end
    if not self.endpoints[a.key] and not self.endpoints[b.key] and U.count(self.pairs) >= 2048 then
        return nil
    end
    local olda, oldb = self.endpoints[a.key], self.endpoints[b.key]
    local id = olda and olda == oldb and olda or nil
    if not id then
        if olda then
            self:remove_pair(olda)
        end
        if oldb then
            self:remove_pair(oldb)
        end
        id = self.next_pair
        self.next_pair = id + 1
        self.pairs[id] = { id = id, a = a, b = b, shared = shared == true }
        self.endpoints[a.key], self.endpoints[b.key] = id, id
    elseif shared then
        local previous = self.pairs[id]
        self.pairs[id] = { id = id, a = previous.a, b = previous.b, shared = true }
    end
    self.discoveries[userid] = self.discoveries[userid] or {}
    self.discoveries[userid][tostring(id)] = true
    self.revision = self.revision + 1
    return id
end

-- 移除配对及双端索引，同时递增修订号。
function Map:remove_pair(id)
    if self.load_error then
        return
    end
    local pair = self.pairs[id]
    if pair then
        self.endpoints[pair.a.key], self.endpoints[pair.b.key] = nil, nil
        self.pairs[id] = nil
        for _, discovery in pairs(self.discoveries) do
            discovery[tostring(id)] = nil
        end
        self.revision = self.revision + 1
    end
end

-- 只返回本玩家已发现或获准共享的配对，按编号排序。
function Map:visible_pairs(userid, share)
    local cached = self.pair_views[userid]
    if cached and cached.revision == self.revision and cached.share == share then
        return cached.rows, cached.group
    end
    local out, private = {}, false
    for _, pair in pairs(self.pairs) do
        local personal = self.discoveries[userid] and self.discoveries[userid][tostring(pair.id)]
        if (share and pair.shared) or personal then
            out[#out + 1] = pair
            private = private or not (share and pair.shared)
        end
    end
    table.sort(out, function(a, b)
        return a.id < b.id
    end)
    local group = share and (not private and "shared" or "shared+" .. userid) or "private:" .. userid
    self.pair_views[userid] = { revision = self.revision, share = share, rows = out, group = group }
    return out, group
end

-- 只记录共享开启期间的探索来源。不会把任何玩家的完整个人地图复制进公共状态。
-- 相同点去重，接收端分批调用原版 MapExplorer:RevealArea，避免整图反复广播。
-- 去重记录获准来源点，拒绝非有限坐标和超限日志。
function Map:record_exploration(x, z)
    if self.load_error then
        return false
    end
    if not U.finite(x) or not U.finite(z) or math.abs(x) > 10000 or math.abs(z) > 10000 then
        return false
    end
    local key = string.format("%.1f:%.1f", x, z)
    if self.exploration_keys[key] then
        return false
    end
    if #self.exploration >= 65536 then
        return false
    end
    self.exploration_keys[key] = true
    self.exploration[#self.exploration + 1] = { x = x, z = z }
    return true
end

-- 生成独立持久化快照；不支持的原存档保持原样返回。
function Map:save()
    if self.load_error then
        return self.original
    end
    return U.deepcopy({
        version = Map.VERSION,
        worldid = self.worldid,
        next_pair = self.next_pair,
        pairs = self.pairs,
        discoveries = self.discoveries,
        preferences = self.preferences,
        exploration = self.exploration,
    })
end

local function text(value)
    return type(value) == "string" and #value > 0 and #value <= 160
end

local function coordinate(value)
    return U.finite(value) and math.abs(value) <= 10000
end

local function valid_endpoint(value)
    return type(value) == "table"
        and text(value.key)
        and text(value.prefab)
        and coordinate(value.x)
        and coordinate(value.z)
end

-- 完整校验临时数据后原子加载；失败保留原数据并停止修改。
function Map:load(data)
    if data == nil then
        return true
    end

    local function invalid()
        self.original, self.load_error = data, "unsupported_save"
        return false
    end
    if
        type(data) ~= "table"
        or data.version ~= Map.VERSION
        or type(data.pairs) ~= "table"
        or not U.finite(data.next_pair)
        or data.next_pair < 1
        or data.next_pair % 1 ~= 0
        or data.next_pair > 9007199254740991
        or (data.worldid ~= nil and tostring(data.worldid) ~= self.worldid)
        or (data.preferences ~= nil and type(data.preferences) ~= "table")
        or (data.discoveries ~= nil and type(data.discoveries) ~= "table")
        or (data.exploration ~= nil and type(data.exploration) ~= "table")
    then
        return invalid()
    end
    -- 验证到临时状态后一次提交。端点、编号、稀疏数组和世界身份都不能靠容错丢弃。
    local loaded, endpoints, maxid, count = {}, {}, 0, 0
    for key, pair in pairs(data.pairs) do
        local id = tonumber(key)
        if
            not U.finite(id)
            or id < 1
            or id % 1 ~= 0
            or id >= data.next_pair
            or loaded[id]
            or type(pair) ~= "table"
            or pair.id ~= id
            or type(pair.shared) ~= "boolean"
            or not valid_endpoint(pair.a)
            or not valid_endpoint(pair.b)
            or pair.a.key == pair.b.key
            or endpoints[pair.a.key]
            or endpoints[pair.b.key]
        then
            return invalid()
        end
        loaded[id] = {
            id = id,
            a = { key = pair.a.key, prefab = pair.a.prefab, x = pair.a.x, z = pair.a.z },
            b = { key = pair.b.key, prefab = pair.b.prefab, x = pair.b.x, z = pair.b.z },
            shared = pair.shared,
        }
        endpoints[pair.a.key], endpoints[pair.b.key] = id, id
        count, maxid = count + 1, math.max(maxid, id)
        if count > 2048 then
            return invalid()
        end
    end
    if data.next_pair <= maxid then
        return invalid()
    end
    local preferences, discoveries = {}, {}
    for userid, prefs in pairs(data.preferences or {}) do
        if
            not text(userid)
            or type(prefs) ~= "table"
            or type(prefs.position) ~= "boolean"
            or type(prefs.exploration) ~= "boolean"
        then
            return invalid()
        end
        preferences[userid] = { position = prefs.position, exploration = prefs.exploration }
    end
    for userid, discovery in pairs(data.discoveries or {}) do
        if not text(userid) or type(discovery) ~= "table" then
            return invalid()
        end
        discoveries[userid] = {}
        for id, value in pairs(discovery) do
            if type(id) ~= "string" or not tonumber(id) or value ~= true then
                return invalid()
            end
            if loaded[tonumber(id)] then
                discoveries[userid][id] = true
            end
        end
    end
    local exploration, keys, size = {}, {}, 0
    for index, point in pairs(data.exploration or {}) do
        size = size + 1
        if
            not U.finite(index)
            or index < 1
            or index % 1 ~= 0
            or index > 65536
            or size > 65536
            or type(point) ~= "table"
            or not coordinate(point.x)
            or not coordinate(point.z)
        then
            return invalid()
        end
        exploration[index] = { x = point.x, z = point.z }
        keys[string.format("%.1f:%.1f", point.x, point.z)] = true
    end
    for index = 1, size do
        if not exploration[index] then
            return invalid()
        end
    end
    self.next_pair, self.pairs, self.endpoints = data.next_pair, loaded, endpoints
    self.discoveries, self.preferences = discoveries, preferences
    self.exploration, self.exploration_keys = exploration, keys
    self.load_error, self.original = nil, nil
    self.revision, self.pair_views = self.revision + 1, {}
    return true
end
return Map
