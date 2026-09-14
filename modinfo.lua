name = "Wildwise"
description =
    "Unified insight, combat bars, shared maps, item handling, action queues, smart storage signs and beefalo status.\n统一信息、血条、协作地图、物品整理、行为队列、智能小木牌与牛状态。"
author = "Morilence"
version = "0.2.1"
api_version = 10
dst_compatible = true
all_clients_require_mod = true
client_only_mod = false
server_only_mod = false
server_filter_tags = { "wildwise", "quality-of-life" }
local zh = locale == "zh" or locale == "zhr" or locale == "zht"
local function label(en, cn)
    return zh and cn or en
end
local yesno = {
    { description = label("Enabled", "开启"), data = true },
    { description = label("Disabled", "关闭"), data = false },
}
local function option(name_, en, cn, default, options, hover)
    return { name = name_, label = label(en, cn), default = default, options = options or yesno, hover = hover or "" }
end
local function values(numbers)
    local out = {}
    for i = 1, #numbers do
        out[i] = { description = "" .. numbers[i], data = numbers[i] }
    end
    return out
end
local share = {
    { description = label("Follow game mode", "跟随游戏模式"), data = "auto" },
    { description = label("Enabled", "开启"), data = "on" },
    { description = label("Disabled", "关闭"), data = "off" },
}
-- 原生配置保持平铺标量，通用项在前，模块项使用前缀；运行时由 core/config 分组。
configuration_options = {
    -- 通用 / General
    option("language", "Language", "语言", "auto", {
        { description = label("Follow game", "跟随游戏"), data = "auto" },
        { description = "English", data = "en" },
        { description = "简体中文", data = "zh" },
    }),
    option("ui_scale", "Interface scale", "界面缩放", 1, values({ 0.75, 1, 1.25, 1.5 })),
    option("menu_key", "Menu key", "菜单按键", 288, {
        { description = "F6", data = 287 },
        { description = "F7", data = 288 },
        { description = "F8", data = 289 },
    }),
    option("diagnostics", "Local diagnostic logs", "本地诊断日志", false),

    -- 信息 / Information
    option("info_enabled", "Insight", "信息洞察", true),
    option("info_container_contents", "Allow content queries", "允许容器内容查询", false),
    option("info_world_events", "Allow world event details", "允许世界事件详情", false),
    option("info_attack_range", "Allow attack range hints", "允许攻击范围提示", false),
    option("info_font_size", "Information font size", "信息字号", 22, values({ 18, 22, 26, 30 })),

    -- 血条 / Health bars
    option("healthbars_enabled", "Combat health bars", "战斗血条", true),
    option("healthbars_limit", "Health bar limit", "血条数量上限", 12, values({ 4, 8, 12, 16, 20 })),
    option("healthbars_linger_seconds", "Out-of-combat delay", "脱战收起延迟", 2, values({ 0, 1, 2, 3, 5 })),
    option("healthbars_scale", "Health bar scale", "血条缩放", 1, values({ 0.75, 1, 1.25, 1.5 })),
    option("healthbars_numbers", "Health numbers", "血量数值", true),
    option("healthbars_hostile_scope", "Hostility scope", "敌意范围", "self", {
        { description = label("Self", "仅自己"), data = "self" },
        { description = label("Self and followers", "自己及随从"), data = "followers" },
        { description = label("Nearby players", "附近玩家"), data = "nearby" },
        { description = label("Players and followers", "附近玩家及随从"), data = "nearby_followers" },
    }),

    -- 地图 / Map
    option("map_enabled", "Map collaboration", "地图协作", true),
    option("map_share_position", "Position sharing", "位置共享", "auto", share),
    option("map_share_exploration", "Exploration sharing", "探索共享", "auto", share),

    -- 物品 / Items
    option("items_enabled", "Item service", "物品整理", true),
    option("items_stack_world", "Stack new world drops", "合堆新世界掉落", true),
    option("items_stack_manual", "Stack manually dropped items", "合堆玩家丢弃物", false),
    option("items_stack_loaded", "Stack loaded ground items", "合堆读档地面物品", false),
    option("items_pickup_allowed", "Allow opt-in auto pickup", "允许玩家开启自动拾取", false),
    option("items_pickup_existing", "Pickup requires existing item", "拾取要求背包已有同类", true),
    option("items_radius", "Item radius", "物品处理半径", 4, values({ 2, 4, 6, 8 })),

    -- 队列 / Queue
    option("queue_enabled", "Action queue", "行为队列", true),
    option("queue_farm_grid", "Farm grid", "农田布点", 3, values({ 2, 3, 4 })),

    -- 木牌 / Signs
    option("signs_enabled", "Smart storage signs", "智能小木牌", true),
    option("signs_treasurechest", "Signs on chests", "木箱小木牌", true),
    option("signs_dragonflychest", "Signs on scaled chests", "龙鳞宝箱小木牌", true),
    option("signs_boat_ancient_container", "Signs on cargo holds", "远古船货舱小木牌", true),
    option("signs_chester", "Signs on Chester", "切斯特小木牌", false),
    option("signs_hutch", "Signs on Hutch", "哈奇小木牌", false),
    option("signs_icebox", "Signs on ice boxes", "冰箱小木牌", false),
    option("signs_saltbox", "Signs on salt boxes", "盐盒小木牌", false),
    option("signs_fish_box", "Signs on tin fishin' bins", "鱼类储物箱小木牌", false),

    -- 牛状态 / Beefalo
    option("beefalo_enabled", "Beefalo status", "牛状态栏", true),
    option(
        "beefalo_hunger_threshold",
        "Beefalo hunger threshold",
        "牛饥饿显示阈值",
        15,
        values({ 0, 5, 15, 25 })
    ),
}
