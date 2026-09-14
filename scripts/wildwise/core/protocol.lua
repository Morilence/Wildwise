local U = require("wildwise/core/util")
local M = { VERSION = 1, MAX_BYTES = 12000, MAX_FIELDS = 96 }
local function safe(value, depth, budget)
    budget.n = budget.n + 1
    if budget.n > 2048 or depth > 8 then return false end
    local kind = type(value)
    if kind == "number" then return U.finite(value) end
    if kind == "boolean" then return true end
    if kind == "string" then return #value <= 4096 end
    if kind ~= "table" then return false end
    for k, v in pairs(value) do
        if (type(k) ~= "string" and type(k) ~= "number") or not safe(v, depth + 1, budget) then return false end
    end
    return true
end
function M.encode(json, kind, session, sequence, data)
    local envelope = { v = M.VERSION, kind = kind, session = session, seq = sequence, data = data }
    if not safe(envelope, 0, { n = 0 }) then return nil, "invalid_payload" end
    local ok, encoded = pcall(json.encode, envelope)
    if not ok or #encoded > M.MAX_BYTES then return nil, "payload_limit" end
    return encoded
end
function M.decode(json, bytes)
    if type(bytes) ~= "string" or #bytes > M.MAX_BYTES then return nil, "payload_limit" end
    local ok, msg = pcall(json.decode, bytes)
    if not ok or type(msg) ~= "table" or not safe(msg, 0, { n = 0 }) then return nil, "invalid_payload" end
    if msg.v ~= M.VERSION or type(msg.session) ~= "string" or #msg.session > 96
        or type(msg.kind) ~= "string" or not U.finite(msg.seq) or msg.seq < 0 or msg.seq % 1 ~= 0
        or type(msg.data) ~= "table" then return nil, "protocol_mismatch" end
    return msg
end
function M.bucket(rate, burst, now) return { rate = rate, burst = burst, tokens = burst, at = now } end
function M.allow(bucket, now, cost)
    bucket.tokens = math.min(bucket.burst, bucket.tokens + math.max(0, now - bucket.at) * bucket.rate)
    -- 回拨不能把基准时间倒退，否则下次回到原时刻会凭空补充令牌。
    bucket.at = math.max(bucket.at, now)
    if bucket.tokens < (cost or 1) then return false end
    bucket.tokens = bucket.tokens - (cost or 1); return true
end
function M.diff(previous, current)
    local changes, removed = {}, {}
    for key, value in pairs(current) do
        if previous[key] ~= value then changes[key] = value end
    end
    for key in pairs(previous) do if current[key] == nil then removed[#removed + 1] = key end end
    return changes, removed
end
return M
