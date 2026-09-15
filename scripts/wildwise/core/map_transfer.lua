-- 地图快照的传输边界：预检所有分片，完整收齐才替换客户端旧快照。
local Protocol = require("wildwise/core/protocol")
local M = {}
local keys = { "players", "pings", "pairs", "fires" }
local allowed = { players = true, pings = true, pairs = true, fires = true }

-- 在正式发送前检查字节和节点预算，避免 begin 已发出后才发现后续内容无法编码。
-- 预检完整快照或所有分片；任一记录超限则拒绝整次发送。
function M.pack(json, data, revision)
    local function fits(kind, payload)
        return Protocol.encode(json, kind, string.rep("s", 96), 9007199254740991, payload) ~= nil
    end
    if fits("map", data) then
        return { { kind = "map", data = data } }
    end
    local chunks = {}
    for _, key in ipairs(keys) do
        local entries = {}
        for _, entry in ipairs(data[key] or {}) do
            entries[#entries + 1] = entry
            local payload = { revision = revision, index = #chunks + 1, key = key, entries = entries }
            if #entries > 12 or not fits("map_chunk", payload) then
                entries[#entries] = nil
                if #entries == 0 then
                    return nil, "map_record_limit"
                end
                chunks[#chunks + 1] = { kind = "map_chunk", data = payload }
                entries = { entry }
                if
                    not fits("map_chunk", { revision = revision, index = #chunks + 1, key = key, entries = entries })
                then
                    return nil, "map_record_limit"
                end
            end
        end
        if #entries > 0 then
            chunks[#chunks + 1] = {
                kind = "map_chunk",
                data = { revision = revision, index = #chunks + 1, key = key, entries = entries },
            }
        end
    end
    local messages = { { kind = "map_begin", data = { revision = revision, chunks = #chunks } } }
    for _, chunk in ipairs(chunks) do
        messages[#messages + 1] = chunk
    end
    messages[#messages + 1] = { kind = "map_end", data = { revision = revision } }
    return messages
end

-- 返回待收状态和可提交快照；缺片、重片或超限时丢弃本次组装，保留已显示的地图。
-- 顺序接收分片，只有片数完整且版本一致才提交新地图。
function M.receive(pending, kind, data)
    if kind == "map_begin" then
        if type(data.chunks) ~= "number" or data.chunks < 0 or data.chunks > 8192 or data.chunks % 1 ~= 0 then
            return nil
        end
        local state = {
            revision = data.revision,
            expected = data.chunks,
            received = 0,
        }
        local selected = data.keys or keys
        if type(selected) ~= "table" or #selected > 4 or #selected == 0 then
            return nil
        end
        for _, key in ipairs(selected) do
            if not allowed[key] or state[key] then
                return nil
            end
            state[key] = {}
        end
        return state
    end
    if not pending or pending.revision ~= data.revision then
        return nil
    end
    if kind == "map_chunk" then
        if
            not allowed[data.key]
            or type(pending[data.key]) ~= "table"
            or type(data.entries) ~= "table"
            or data.index ~= pending.received + 1
            or pending.received >= pending.expected
        then
            return nil
        end
        local entries = pending[data.key]
        for _, entry in ipairs(data.entries) do
            if #entries >= 2048 then
                return nil
            end
            entries[#entries + 1] = entry
        end
        pending.received = pending.received + 1
        return pending
    end
    if kind == "map_end" and pending.received == pending.expected then
        local snapshot = {}
        for _, key in ipairs(keys) do
            if pending[key] then
                snapshot[key] = pending[key]
            end
        end
        return nil, snapshot
    end
    return nil
end

return M
