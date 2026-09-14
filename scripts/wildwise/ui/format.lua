local Facts = require("wildwise/services/facts")
local Strings = require("wildwise/ui/strings")
local U = require("wildwise/core/util")
local M = {}

-- 权重只在同优先级候选之间归一化；耗时明确为原版基础值，不假设角色或锅的倍率。
function M.recipes(results, lang, info, names, base_time)
    local total, lines = 0, {}
    for _, result in ipairs(results or {}) do
        total = total + (result.weight or 0)
    end
    for _, result in ipairs(results or {}) do
        local name = names and names[result.name:upper()] or result.name
        local probability = total > 0 and string.format("%.1f%%", 100 * result.weight / total) or "?"
        local duration = M.value(result.cooktime * base_time, { unit = "s" }, lang, info)
        lines[#lines + 1] = name
            .. " · "
            .. probability
            .. " · "
            .. Strings.get("base_cook_time", lang)
            .. " "
            .. duration
    end
    return table.concat(lines, "\n")
end

-- 按字段单位格式化已校验的标量值。
function M.value(value, schema, lang, info, names)
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
        local seconds = math.max(0, value)
        local clock = string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
        local style = info and info.time_style
        if style == "seconds" then
            return string.format("%.0f s", seconds)
        end
        local days = string.format("%.2f %s", seconds / 480, Strings.get("game_days", lang))
        if style == "days" then
            return days
        end
        return style == "both" and (clock .. " / " .. days) or clock
    end
    if schema.id == "temperature" or schema.id == "item_temperature" then
        if info and info.temperature_units == "celsius" then
            return string.format("%.1f °C", value / 2)
        end
        if info and info.temperature_units == "fahrenheit" then
            return string.format("%.1f °F", value * 0.9 + 32)
        end
    end
    if schema.id == "cook_product" or schema.id == "dry_product" or schema.id == "saddle_name" then
        local labels = {}
        for prefab in tostring(value):gmatch("[^,]+") do
            labels[#labels + 1] = names and names[prefab:upper()] or prefab
        end
        return table.concat(labels, " / ")
    end
    if schema.id == "stress_sources" then
        local labels = {}
        for key in tostring(value):gmatch("[^,]+") do
            labels[#labels + 1] = Strings.get("stress_" .. key, lang)
        end
        return table.concat(labels, " / ")
    end
    if schema.id == "timers" then
        local labels = {}
        for key, seconds, state in tostring(value):gmatch("([%w_]+):(%d+):([%w_]+)") do
            labels[#labels + 1] = Strings.get(key, lang)
                .. " "
                .. M.value(tonumber(seconds), { unit = "s" }, lang, info)
                .. (state == "paused" and (" · " .. Strings.get("paused", lang)) or "")
        end
        return table.concat(labels, " / ")
    end
    if schema.id == "tendency" or schema.id == "process_state" or schema.id == "perish_state" then
        return Strings.get(value, lang)
    end
    return tostring(value) .. schema.unit
end

-- 按密度、分类和现有血条筛选悬浮信息，避免重复健康数值。
function M.lines(fields, settings, lang, detailed, health_visible, names)
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
    local limit = detailed and (settings.info.inspect_lines or 25)
        or (settings.info.preset == "minimal" and 4 or settings.info.max_lines or 10)
    for _, key in ipairs(keys) do
        local schema = Facts.schema[key]
        local is_health = key == "health" or key == "health_max"
        if
            schema.detail <= level
            and settings.info[Facts.group(key)] ~= false
            and not (health_visible and is_health)
            and (not settings.info.categories or settings.info.categories[schema.category] ~= false)
        then
            out[#out + 1] = Strings.get(key, lang) .. ": " .. M.value(fields[key], schema, lang, settings.info, names)
        end
    end
    if #out > limit then
        local omitted = #out - limit + 1
        for i = #out, limit, -1 do
            out[i] = nil
        end
        out[limit] = string.format(Strings.get(detailed and "details_truncated" or "inspect_more", lang), omitted)
    end
    return table.concat(out, "\n")
end
return M
