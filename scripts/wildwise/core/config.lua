local U = require("wildwise/core/util")
local M = {}

-- 通用设置位于根节点；模块内部只保留短字段名，避免 beefalo.beefalo_hunger_threshold。
M.defaults = {
    language = "auto",
    ui_scale = 1,
    menu_key = 288,
    diagnostics = false,
    info = {
        enabled = true,
        container_contents = false,
        world_events = false,
        attack_range = false,
        font_size = 22,
        combat = true,
        food_values = true,
        perishable = true,
        equipment = true,
        progress = true,
        farm = true,
        follower = true,
        cooldowns = true,
        timers = true,
        max_lines = 10,
        inspect_lines = 25,
        time_style = "clock",
        temperature_units = "game",
    },
    healthbars = { enabled = true, limit = 12, scale = 1, numbers = true, linger_seconds = 2, hostile_scope = "self" },
    map = {
        enabled = true,
        share_position = "auto",
        share_exploration = "auto",
        wormholes = true,
        pings = true,
        signal_fires = true,
    },
    items = {
        enabled = true,
        stack_world = true,
        stack_manual = false,
        stack_loaded = false,
        pickup_allowed = false,
        pickup_existing = true,
        radius = 4,
        world_radius = 0,
        manual_radius = 0,
        pickup_radius = 0,
        world_ash = false,
        world_poop = false,
        world_seeds = false,
        manual_ash = false,
        manual_poop = false,
        manual_seeds = false,
        pickup_ash = false,
        pickup_poop = false,
        pickup_seeds = false,
        budget = 16,
    },
    queue = {
        enabled = true,
        farm_grid = 3,
        limit = 200,
        collect_after_work = false,
        double_click_speed = 0.35,
        double_click_range = 15,
    },
    signs = {
        enabled = true,
        bundle_contents = true,
        body_skins = true,
        scale = 0.65,
        treasurechest = true,
        dragonflychest = true,
        boat_ancient_container = true,
        chester = false,
        hutch = false,
        icebox = false,
        saltbox = false,
        fish_box = false,
    },
    beefalo = { enabled = true, hunger_threshold = 15, show_hunger = true, scale = 1 },
    observation = { radius = 40, limit = 24 },
}

-- DST 的配置界面与 GetModConfigData 使用平铺标量；只在这个边界映射为模块路径。
-- 预算、观察范围等内部常量不在公开字段表中，不能通过 modoverrides.lua 改写。
M.fields = {
    { "language", { "auto", "zh", "en" } },
    { "ui_scale", { 0.75, 1, 1.25, 1.5 } },
    { "menu_key", { 287, 288, 289 } },
    { "diagnostics" },
    { "info.enabled" },
    { "info.container_contents" },
    { "info.world_events" },
    { "info.attack_range" },
    { "info.font_size", { 18, 22, 26, 30 } },
    { "healthbars.enabled" },
    { "healthbars.limit", { 4, 8, 12, 16, 20 } },
    { "healthbars.linger_seconds", { 0, 1, 2, 3, 5 } },
    { "healthbars.scale", { 0.75, 1, 1.25, 1.5 } },
    { "healthbars.numbers" },
    { "healthbars.hostile_scope", { "self", "followers", "nearby", "nearby_followers" } },
    { "map.enabled" },
    { "map.share_position", { "auto", "on", "off" } },
    { "map.share_exploration", { "auto", "on", "off" } },
    { "items.enabled" },
    { "items.stack_world" },
    { "items.stack_manual" },
    { "items.stack_loaded" },
    { "items.pickup_allowed" },
    { "items.pickup_existing" },
    { "items.radius", { 2, 4, 6, 8 } },
    { "queue.enabled" },
    { "queue.farm_grid", { 2, 3, 4 } },
    { "signs.enabled" },
    { "signs.treasurechest" },
    { "signs.dragonflychest" },
    { "signs.boat_ancient_container" },
    { "signs.chester" },
    { "signs.hutch" },
    { "signs.icebox" },
    { "signs.saltbox" },
    { "signs.fish_box" },
    { "beefalo.enabled" },
    { "beefalo.hunger_threshold", { 0, 5, 15, 25 } },
    { "info.combat" },
    { "info.food_values" },
    { "info.perishable" },
    { "info.equipment" },
    { "info.progress" },
    { "info.farm" },
    { "info.follower" },
    { "info.cooldowns" },
    { "info.timers" },
    { "info.max_lines", { 4, 8, 10, 15, 20, 25 } },
    { "info.inspect_lines", { 10, 15, 20, 25, 35 } },
    { "info.time_style", { "clock", "seconds", "days", "both" } },
    { "info.temperature_units", { "game", "celsius", "fahrenheit" } },
    { "map.wormholes" },
    { "map.pings" },
    { "map.signal_fires" },
    { "items.world_radius", { 0, 1, 2, 4, 6, 8, 10, 15, 20, 25 } },
    { "items.manual_radius", { 0, 1, 2, 4, 6, 8, 10, 15, 20, 25 } },
    { "items.pickup_radius", { 0, 1, 2, 4, 6, 8, 10, 15, 20, 25 } },
    { "items.world_ash" },
    { "items.world_poop" },
    { "items.world_seeds" },
    { "items.manual_ash" },
    { "items.manual_poop" },
    { "items.manual_seeds" },
    { "items.pickup_ash" },
    { "items.pickup_poop" },
    { "items.pickup_seeds" },
    { "queue.collect_after_work" },
    { "queue.double_click_speed", { 0.2, 0.25, 0.35, 0.5, 0.75 } },
    { "queue.double_click_range", { 5, 10, 15, 20, 25 } },
    { "signs.bundle_contents" },
    { "signs.body_skins" },
    { "signs.scale", { 0.5, 0.65, 0.8, 1 } },
    { "beefalo.show_hunger" },
    { "beefalo.scale", { 0.75, 1, 1.25, 1.5 } },
}

-- 深拷贝配置，使服务器规则和每名玩家的偏好互相独立。
function M.copy(source)
    local out = {}
    for key, value in pairs(source) do
        out[key] = type(value) == "table" and M.copy(value) or value
    end
    return out
end

-- 按模块路径读取配置；只支持根字段或一层模块字段。
function M.get(config, path)
    local group, key = path:match("^([^.]+)%.([^.]+)$")
    if group then
        return config[group] and config[group][key]
    end
    return config[path]
end

-- 写入已校验的内部配置路径。
function M.set(config, path, value)
    local group, key = path:match("^([^.]+)%.([^.]+)$")
    if group then
        config[group][key] = value
    else
        config[path] = value
    end
end

-- 把原生平铺配置转为模块结构，返回配置及非法字段列表。
function M.load(read)
    local out, invalid = M.copy(M.defaults), {}
    for _, field in ipairs(M.fields) do
        local path, choices = field[1], field[2]
        local name = path:gsub("%.", "_")
        local supplied, valid = read(name), false
        if choices then
            for _, value in ipairs(choices) do
                if supplied == value then
                    valid = true
                end
            end
        else
            valid = type(supplied) == "boolean"
        end
        -- 显式保留 false；非法类型／枚举回退默认值，不让半径为零等输入进入服务层。
        if valid then
            M.set(out, path, supplied)
        elseif supplied ~= nil then
            invalid[#invalid + 1] = name
        end
    end
    return out, invalid
end

-- 根据服务器初始值创建独立的个人偏好。
function M.settings(config)
    -- 个人偏好与服务器权限分开持久化，避免保存整个服务器配置后跨世界带入旧规则。
    return {
        language = config.language,
        ui_scale = config.ui_scale,
        menu_key = config.menu_key,
        first_tip_seen = false,
        info = {
            font_size = config.info.font_size,
            combat = config.info.combat,
            food_values = config.info.food_values,
            perishable = config.info.perishable,
            equipment = config.info.equipment,
            progress = config.info.progress,
            farm = config.info.farm,
            follower = config.info.follower,
            cooldowns = config.info.cooldowns,
            timers = config.info.timers,
            max_lines = config.info.max_lines,
            inspect_lines = config.info.inspect_lines,
            time_style = config.info.time_style,
            temperature_units = config.info.temperature_units,
            preset = "standard",
            categories = {
                combat = true,
                food = true,
                equipment = true,
                progress = true,
                farm = true,
                follower = true,
                container = true,
                world = true,
            },
        },
        healthbars = M.copy(config.healthbars),
        map = {
            share_position = true,
            share_exploration = true,
            indicators = "scoreboard",
            ping_kind = "location",
            show_players = true,
            show_pings = true,
            show_fires = true,
            show_wormholes = true,
        },
        items = { pickup = false },
        queue = {
            farm_grid = config.queue.farm_grid,
            modifier_key = 304,
            last_recipe_key = 99,
            collect_after_work = config.queue.collect_after_work,
            double_click_speed = config.queue.double_click_speed,
            double_click_range = config.queue.double_click_range,
        },
        beefalo = {
            visible = true,
            layout = "badges",
            background = 0.82,
            show_hunger = config.beefalo.show_hunger,
            scale = config.beefalo.scale,
            hunger_threshold = config.beefalo.hunger_threshold,
            offset_x = 0,
            offset_y = 0,
            toggle_key = 98,
        },
    }
end
-- 本地持久化数据也要校验值域；同类型的零缩放、无限值或未知枚举同样不可用。
local personal_choices = {
    language = { "auto", "zh", "en" },
    ["info.preset"] = { "minimal", "standard", "detailed" },
    ["healthbars.hostile_scope"] = { "self", "followers", "nearby", "nearby_followers" },
    ["map.indicators"] = { "always", "scoreboard", "off" },
    ["map.ping_kind"] = { "location", "danger", "resource", "rally" },
    ["beefalo.layout"] = { "badges", "compact" },
    ["beefalo.background"] = { 0, 0.35, 0.65, 0.82, 1 },
}
for _, field in ipairs(M.fields) do
    if field[2] then
        personal_choices[field[1]] = field[2]
    end
end

local function personal_valid(path, value, default)
    if type(value) ~= type(default) then
        return false
    end
    if type(value) == "number" and not U.finite(value) then
        return false
    end
    if path:match("key$") then
        return value >= 0 and value <= 512 and value % 1 == 0
    end
    if path == "beefalo.offset_x" or path == "beefalo.offset_y" then
        return math.abs(value) <= 600
    end
    local choices = personal_choices[path]
    if choices then
        for _, choice in ipairs(choices) do
            if value == choice then
                return true
            end
        end
        return false
    end
    return true
end

-- 只恢复已知且类型、枚举和值域合法的本地偏好。
function M.restore(settings, saved, prefix)
    if type(saved) ~= "table" then
        return
    end
    for key, value in pairs(settings) do
        local supplied = saved[key]
        local path = prefix and (prefix .. "." .. key) or key
        if type(value) == "table" then
            M.restore(value, supplied, path)
        elseif personal_valid(path, supplied, value) then
            settings[key] = supplied
        end
    end
end

-- 结合世界模式、PvP 和服主规则计算位置与探索共享权限。
function M.share(config, mode, pvp)
    local cautious = mode == "wilderness" or pvp

    local function enabled(value)
        return value == "on" or (value == "auto" and not cautious)
    end
    return config.map.enabled and enabled(config.map.share_position),
        config.map.enabled and enabled(config.map.share_exploration)
end
M.conflicts = {
    ["2189004162"] = { "info" },
    ["378160973"] = { "map" },
    ["362175979"] = { "wormholes" },
    ["1803285852"] = { "items" },
    ["2873533916"] = { "queue" },
    ["1608191708"] = { "queue" },
    ["3334208307"] = { "queue" },
    ["1595631294"] = { "signs" },
    ["2881739960"] = { "signs" },
    ["2477889104"] = { "beefalo" },
}

-- 检测已知重叠模组，停用对应模块并返回可显示的原因。
function M.compat(config, enabled)
    local reasons = {}
    for _, name in ipairs(enabled or {}) do
        local id = tostring(name):match("(%d+)$")
        for _, feature in ipairs(M.conflicts[id] or {}) do
            if feature == "wormholes" then
                config.map.wormholes = false
            else
                config[feature].enabled = false
            end
            reasons[feature] = "workshop-" .. id
        end
    end
    return reasons
end
return M
