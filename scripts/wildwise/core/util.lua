local M = {}
function M.clamp(n, lo, hi) return math.max(lo, math.min(hi, n)) end
function M.finite(n) return type(n) == "number" and n == n and n > -math.huge and n < math.huge end
function M.valid(e) return e ~= nil and e.IsValid ~= nil and e:IsValid() end
function M.count(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
function M.copy(t) local out = {}; for k, v in pairs(t or {}) do out[k] = v end; return out end
function M.distance(a, b)
    local x, _, z = a.Transform:GetWorldPosition()
    local bx, _, bz = b.Transform:GetWorldPosition()
    return (x - bx)^2 + (z - bz)^2
end
function M.platform(e) return e.GetCurrentPlatform and e:GetCurrentPlatform() or nil end
function M.sameplatform(a, b) return M.platform(a) == M.platform(b) end
function M.muted(G, userid)
    local client = G.TheNet:GetClientTableForUser(userid)
    return client and client.muted == true or false
end
function M.call(object, method, ...)
    if object and type(object[method]) == "function" then return object[method](object, ...) end
end
function M.pack(...) return { n = select("#", ...), ... } end
function M.sortedkeys(t)
    local keys = {}; for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys); return keys
end
return M
