local U = require("wildwise/core/util")
local M = {}

-- The wrapper owns only its own link. Later wrappers remain intact on teardown.
-- 包装单个对象方法，关闭时仅撤销本层，不覆盖后续包装。
function M.wrap(scope, object, key, around)
    local original = object[key]
    if type(original) ~= "function" then
        return false
    end
    local active = true
    local wrapper = function(...)
        if active then
            return around(original, ...)
        end
        return original(...)
    end
    object[key] = wrapper
    scope:add(function()
        active = false
        if object[key] == wrapper then
            object[key] = original
        end
    end)
    return true
end

-- 原方法成功返回后执行观察回调，完整保留原返回值。
function M.after(scope, object, key, after)
    return M.wrap(scope, object, key, function(original, ...)
        local result = U.pack(original(...))
        after(result, ...)
        return unpack(result, 1, result.n)
    end)
end
return M
