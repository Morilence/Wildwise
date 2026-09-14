local Facts = require("wildwise/services/facts")
local Strings = require("wildwise/ui/strings")
local U = require("wildwise/core/util")
local M = {}

-- 按字段单位格式化已校验的标量值。
function M.value(value, schema, lang)
    if
        not schema
        or (type(value) == "number" and not U.finite(value))
        or (type(value) ~= "number" and type(value) ~= "string" and type(value) ~= "boolean")
    then
        return ""
    end
    if type(value) == "boolean" then
        return Strings.get(value and "yes" or "no", lang)
    end
    if schema.unit == "s" and type(value) == "number" then
        return string.format("%d:%02d", math.floor(math.max(0, value) / 60), math.floor(math.max(0, value) % 60))
    end
    if schema.id == "tendency" then
        return Strings.get(value, lang)
    end
    return tostring(value) .. schema.unit
end

-- 按密度、分类和现有血条筛选悬浮信息，避免重复健康数值。
function M.lines(fields, settings, lang, detailed, health_visible)
    local out, keys = {}, {}
    for key in pairs(fields or {}) do
        if Facts.schema[key] then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys, function(a, b)
        local sa, sb = Facts.schema[a], Facts.schema[b]
        if sa.detail ~= sb.detail then
            return sa.detail < sb.detail
        end
        if sa.category ~= sb.category then
            return sa.category < sb.category
        end
        return a < b
    end)
    local level = detailed and 2 or (settings.info.preset == "detailed" and 2 or 1)
    local limit = detailed and 25 or (settings.info.preset == "minimal" and 4 or 10)
    for _, key in ipairs(keys) do
        local schema = Facts.schema[key]
        local is_health = key == "health" or key == "health_max"
        if
            schema.detail <= level
            and not (health_visible and is_health)
            and (not settings.info.categories or settings.info.categories[schema.category] ~= false)
        then
            out[#out + 1] = Strings.get(key, lang) .. ": " .. M.value(fields[key], schema, lang)
            if #out >= limit then
                break
            end
        end
    end
    return table.concat(out, "\n")
end
return M
