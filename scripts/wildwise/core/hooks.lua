local U = require("wildwise/core/util")
local M = {}
-- The wrapper owns only its own link. Later wrappers remain intact on teardown.
function M.wrap(scope, object, key, around)
    local original = object[key]
    if type(original) ~= "function" then return false end
    local active = true
    local wrapper = function(...)
        if active then return around(original, ...) end
        return original(...)
    end
    object[key] = wrapper
    scope:add(function()
        active = false
        if object[key] == wrapper then object[key] = original end
    end)
    return true
end
function M.after(scope, object, key, after)
    return M.wrap(scope, object, key, function(original, ...)
        local result = U.pack(original(...))
        after(result, ...)
        return unpack(result, 1, result.n)
    end)
end
return M
