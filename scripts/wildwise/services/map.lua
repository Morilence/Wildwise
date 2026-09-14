local U = require("wildwise/core/util")
local Map = {}; Map.__index = Map
Map.VERSION = 1
function Map.new(worldid)
    return setmetatable({ worldid = tostring(worldid), next_pair = 1, next_ping = 1,
        pairs = {}, endpoints = {}, discoveries = {}, pings = {}, exploration = {}, exploration_keys = {},
        preferences = {}, revision = 0, load_error = nil }, Map)
end
function Map:preferences_for(userid)
    return self.preferences[userid] or { position = true, exploration = true }
end
function Map:set_preference(userid, key, value)
    if key ~= "position" and key ~= "exploration" then return false end
    local prefs = self:preferences_for(userid); prefs[key] = value == true; self.preferences[userid] = prefs
    return true
end
function Map:add_ping(userid, kind, x, z, now)
    if not ({ location = true, danger = true, resource = true, rally = true })[kind]
        or not U.finite(x) or not U.finite(z) or math.abs(x) > 10000 or math.abs(z) > 10000 then return nil, "invalid_ping" end
    self:expire(now)
    local count = 0; for _, ping in pairs(self.pings) do if ping.owner == userid then count = count + 1 end end
    if count >= 5 then return nil, "ping_limit" end
    local id = self.next_ping; self.next_ping = id + 1
    self.pings[id] = { id = id, owner = userid, kind = kind, x = x, z = z, expires = now + 60 }
    return id
end
function Map:delete_ping(userid, id, admin)
    if admin and id == 0 then self.pings = {}; return true end
    local ping = self.pings[id]
    if ping and (ping.owner == userid or admin) then self.pings[id] = nil; return true end
    return false
end
function Map:expire(now)
    for id, ping in pairs(self.pings) do if ping.expires <= now then self.pings[id] = nil end end
end
-- 端点身份来自坐标与设施类型；GUID 仅作当前运行期实体引用，绝不作为存档主键。
function Map.endpoint(prefab, x, z) return string.format("%s:%.2f:%.2f", prefab, x, z) end
function Map:discover(userid, a, b, shared)
    if a.key == b.key then return nil end
    local olda, oldb = self.endpoints[a.key], self.endpoints[b.key]
    local id = olda and olda == oldb and olda or nil
    if not id then
        if olda then self:remove_pair(olda) end
        if oldb then self:remove_pair(oldb) end
        id = self.next_pair; self.next_pair = id + 1
        self.pairs[id] = { id = id, a = a, b = b, shared = shared == true }
        self.endpoints[a.key], self.endpoints[b.key] = id, id
    elseif shared then self.pairs[id].shared = true end
    self.discoveries[userid] = self.discoveries[userid] or {}
    self.discoveries[userid][tostring(id)] = true; self.revision = self.revision + 1
    return id
end
function Map:remove_pair(id)
    local pair = self.pairs[id]
    if pair then
        self.endpoints[pair.a.key], self.endpoints[pair.b.key] = nil, nil; self.pairs[id] = nil
        self.revision = self.revision + 1
    end
end
function Map:visible_pairs(userid, share)
    local out = {}
    for _, pair in pairs(self.pairs) do
        if (share and pair.shared) or (self.discoveries[userid] and self.discoveries[userid][tostring(pair.id)]) then
            out[#out + 1] = pair
        end
    end
    table.sort(out, function(a, b) return a.id < b.id end); return out
end
-- 只记录共享开启期间的探索来源。不会把任何玩家的完整个人地图复制进公共状态。
-- 相同点去重，接收端分批调用原版 MapExplorer:RevealArea，避免整图反复广播。
function Map:record_exploration(x, z)
    local key = string.format("%.1f:%.1f", x, z)
    if self.exploration_keys[key] then return false end
    if #self.exploration >= 65536 then return false end
    self.exploration_keys[key] = true
    self.exploration[#self.exploration + 1] = { x = x, z = z }
    return true
end
function Map:save()
    if self.load_error then return self.original end
    return { version = Map.VERSION, worldid = self.worldid, next_pair = self.next_pair,
        pairs = self.pairs, discoveries = self.discoveries, preferences = self.preferences, exploration = self.exploration }
end
function Map:load(data)
    if not data then return true end
    local function invalid()
        self.original, self.load_error = data, "unsupported_save"; return false
    end
    if type(data) ~= "table" or data.version ~= Map.VERSION or type(data.pairs) ~= "table"
        or not U.finite(data.next_pair) or data.next_pair < 1 or data.next_pair % 1 ~= 0
        or (data.preferences ~= nil and type(data.preferences) ~= "table")
        or (data.discoveries ~= nil and type(data.discoveries) ~= "table")
        or (data.exploration ~= nil and type(data.exploration) ~= "table") then
        self.original, self.load_error = data, "unsupported_save"; return false
    end
    -- 完整检查后再写入当前状态；损坏记录不会迁移一半后把旧数据覆盖掉。
    for id, pair in pairs(data.pairs) do
        if not U.finite(tonumber(id)) or type(pair) ~= "table" or pair.id ~= tonumber(id)
            or type(pair.a) ~= "table" or type(pair.b) ~= "table"
            or type(pair.a.key) ~= "string" or type(pair.b.key) ~= "string" then return invalid() end
    end
    for _, prefs in pairs(data.preferences or {}) do
        if type(prefs) ~= "table" then return invalid() end
    end
    for _, discovery in pairs(data.discoveries or {}) do
        if type(discovery) ~= "table" then return invalid() end
    end
    for _, point in ipairs(data.exploration or {}) do
        if type(point) ~= "table" or not U.finite(point.x) or not U.finite(point.z) then return invalid() end
    end
    self.next_pair, self.worldid = data.next_pair, data.worldid or self.worldid
    self.pairs, self.endpoints = {}, {}
    for id, pair in pairs(data.pairs) do
        if type(pair) == "table" and type(pair.a) == "table" and type(pair.b) == "table"
            and pair.a.key and pair.b.key then
            self.pairs[tonumber(id)] = pair
            self.endpoints[pair.a.key], self.endpoints[pair.b.key] = pair.id, pair.id
        end
    end
    self.discoveries, self.preferences = data.discoveries or {}, data.preferences or {}
    self.exploration, self.exploration_keys = {}, {}
    for _, point in ipairs(data.exploration or {}) do
        if U.finite(point.x) and U.finite(point.z) then self:record_exploration(point.x, point.z) end
    end
    return true
end
return Map
