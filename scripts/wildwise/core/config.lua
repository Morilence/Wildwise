local M = {}
M.defaults = {
    info = true, healthbars = true, maps = true, items = true, queue = true,
    signs = true, beefalo = true, containers = false, world_events = false, ranges = false,
    sharing = "auto", exploration = "auto", stack_world = true, stack_manual = false,
    stack_loaded = false, pickup_allowed = false, pickup_existing = true, item_radius = 4,
    item_budget = 16, info_radius = 40, observer_limit = 24, hostile_scope = "self",
    bar_limit = 12, bar_scale = 1, bar_numbers = true, combat_linger = 2,
    preset = "standard", font_size = 22, ui_scale = 1, indicators = "scoreboard",
    menu_key = 288, queue_key = 304, beefalo_key = 98, language = "auto",
    queue_limit = 200, grid = 3, hunger_threshold = 15, diagnostics = false,
}
function M.load(read)
    local out = {}
    for k, v in pairs(M.defaults) do
        local supplied = read(k)
        -- Lua 的 a and b or c 不能正确保留 b=false，默认关闭项必须显式分支。
        if supplied == nil then out[k] = v else out[k] = supplied end
    end
    return out
end
function M.share(config, mode, pvp)
    local cautious = mode == "wilderness" or pvp
    local function enabled(v) return v == "on" or (v == "auto" and not cautious) end
    return config.maps and enabled(config.sharing), config.maps and enabled(config.exploration)
end
M.conflicts = {
    ["2189004162"] = { "info" }, ["378160973"] = { "maps" },
    ["362175979"] = { "wormholes" }, ["1803285852"] = { "items" },
    ["2873533916"] = { "queue" }, ["1608191708"] = { "queue" },
    ["3334208307"] = { "queue" }, ["1595631294"] = { "signs" },
    ["2881739960"] = { "signs" }, ["2477889104"] = { "beefalo" },
}
function M.compat(config, enabled)
    local reasons = {}
    for _, name in ipairs(enabled or {}) do
        local id = tostring(name):match("(%d+)$")
        for _, feature in ipairs(M.conflicts[id] or {}) do
            config[feature] = false; reasons[feature] = "workshop-" .. id
        end
    end
    return reasons
end
return M
