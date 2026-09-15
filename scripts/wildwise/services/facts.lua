local U = require("wildwise/core/util")
local Recipes = require("wildwise/services/recipes")
local Containers = require("wildwise/services/containers")
local Details = require("wildwise/services/details")
local M = {}
M.schema = {}

local function define(id, category, unit, detail, viewer)
    M.schema[id] = {
        id = id,
        category = category,
        unit = unit or "",
        detail = detail or 1,
        viewer = viewer or false,
        ttl = (id == "health" or id == "health_max") and 0.1 or 0.5,
        value_type = "scalar",
    }
end
for _, id in ipairs({
    "health",
    "health_max",
    "damage",
    "planar_damage",
    "planar_defense",
    "armor",
    "absorption",
    "attack_range",
    "frozen",
    "burning",
}) do
    define(id, "combat", id == "absorption" and "%" or "", id == "attack_range" and 2 or 1)
end
for _, id in ipairs({ "food_health", "food_hunger", "food_sanity", "edible", "food_type" }) do
    define(id, "food", "", 1, true)
end
for _, id in ipairs({ "freshness", "perish_time", "ingredients" }) do
    define(id, "food", id == "freshness" and "%" or "", 2)
end
for _, id in ipairs({
    "durability",
    "uses",
    "uses_max",
    "waterproof",
    "insulation",
    "insulation_type",
    "speed",
    "dapperness",
}) do
    define(id, "equipment", (id == "durability" or id == "waterproof") and "%" or "", 1)
end
for _, id in ipairs({ "fuel", "fuel_time", "fuel_value", "cook_time", "dry_time", "growth_time", "stage", "harvest" }) do
    define(id, "progress", id:match("time$") and "s" or "", 1)
end
for _, id in ipairs({ "moisture", "nutrients", "stress", "fertilizer" }) do
    define(id, "farm", "", 2, id == "stress")
end
for _, id in ipairs({ "leader", "loyalty" }) do
    define(id, "follower", id == "loyalty" and "s" or "", 1)
end
for _, id in ipairs({ "contents", "bundle", "count" }) do
    define(id, "container", "", id == "count" and 1 or 2)
end
for _, id in ipairs({
    "domestication",
    "obedience",
    "hunger",
    "hunger_max",
    "tendency",
    "domesticated",
    "ride_time",
    "saddle_uses",
    "saddle_name",
}) do
    define(id, "beefalo", (id == "domestication" or id == "obedience") and "%" or (id == "ride_time" and "s" or ""), 1)
end
for _, id in ipairs({
    "season",
    "season_days",
    "day",
    "phase",
    "temperature",
    "wetness",
    "hunger_rate",
    "sanity_rate",
    "world_events",
}) do
    define(id, "world", "", 2)
end

for _, field in ipairs({
    { "perish_estimate", "food", "s", 2 },
    { "perish_state", "food", "", 2 },
    { "recharge", "equipment", "%" },
    { "cooldown_time", "equipment", "s" },
    { "item_moisture", "equipment", "%" },
    { "item_temperature", "equipment" },
    { "sew_value", "equipment", "s", 2 },
    { "repair_health", "equipment", "", 2 },
    { "repair_uses", "equipment", "", 2 },
    { "repair_freshness", "equipment", "%", 2 },
    { "repair_work", "equipment", "", 2 },
    { "repair_percent", "equipment", "%", 2 },
    { "cook_product", "progress" },
    { "dry_product", "progress" },
    { "process_state", "progress" },
    { "timers", "progress", "", 2 },
    { "stress_points", "farm", "", 2 },
    { "stress_max", "farm", "", 2 },
    { "stress_sources", "farm", "", 2 },
}) do
    define(unpack(field))
end

local text_fields = {
    saddle_name = true,
    perish_state = true,
    cook_product = true,
    dry_product = true,
    process_state = true,
    timers = true,
    stress_sources = true,
    food_type = true,
    ingredients = true,
    insulation_type = true,
    stage = true,
    nutrients = true,
    stress = true,
    fertilizer = true,
    leader = true,
    contents = true,
    bundle = true,
    tendency = true,
    season = true,
    phase = true,
    world_events = true,
}
local boolean_fields = { frozen = true, burning = true, edible = true, domesticated = true, moisture = true }
for id, schema in pairs(M.schema) do
    schema.value_type = boolean_fields[id] and "boolean" or (text_fields[id] and "text" or "number")
end
-- stage 在不同原生组件中可能是索引或名称；水分目前由农田只读接口返回布尔值。
M.schema.stage.value_type = "scalar"
-- schema 在模块加载阶段完成登记；热路径复用有序键，不为每个订阅重新排序。
local schema_keys = U.sortedkeys(M.schema)

local function put(fields, key, value)
    if type(value) == "number" and U.finite(value) then
        fields[key] = math.abs(value) < 1e12 and math.floor(value * 100 + 0.5) / 100 or value
    elseif type(value) == "string" then
        fields[key] = U.textlimit(value, 240)
    elseif type(value) == "boolean" then
        fields[key] = value
    end
end

local function percent(value)
    return U.finite(value) and value * 100 or nil
end

local function summary(container)
    local items = {}
    for slot = 1, math.min(container.numslots or 0, 80) do
        local item = container:GetItemInSlot(slot)
        if U.valid(item) then
            items[#items + 1] = (item.prefab or "?")
                .. " ×"
                .. tostring(U.call(item.components.stackable, "StackSize") or 1)
        end
    end
    return table.concat(items, ", ")
end

local function health_fields(entity)
    local out, c = {}, entity.components or {}
    if c.health then
        put(out, "health", c.health.currenthealth)
        put(out, "health_max", U.call(c.health, "GetMaxWithPenalty") or c.health.maxhealth)
    end
    return out
end
-- 读取器按功能命名并顺序执行；扩展字段仍由 schema 与权限过滤统一管理。
local readers = {}

local function register(id, read)
    readers[#readers + 1] = { id = id, read = read }
end

local function read_safely(id, read, context, ...)
    local out = {}
    local ok, reason = pcall(read, out, ...)
    if not ok then
        context.reader_errors = context.reader_errors or {}
        local entry = context.reader_errors[id]
        if not entry then
            entry = { count = 0, message = tostring(reason):sub(1, 240) }
            context.reader_errors[id] = entry
            if context.config.diagnostics then
                print("[Wildwise] 信息读取失败 " .. id .. ": " .. entry.message)
            end
        end
        entry.count = entry.count + 1
        return {}
    end
    return out
end

-- 健康专用订阅也经过相同故障边界，不让血条成为未保护的旁路。
-- 读取当前与最大生命值，隔离读取异常；不改动战斗组件。
function M.health(entity, context)
    return read_safely("health", function(out)
        for key, value in pairs(health_fields(entity)) do
            out[key] = value
        end
    end, context or { config = {} })
end

register("combat", function(out, entity, context)
    local c = entity.components or {}
    local cfg = context.config
    if c.combat then
        put(out, "damage", c.combat.defaultdamage)
    end
    if c.weapon and type(c.weapon.damage) == "number" then
        put(out, "damage", c.weapon.damage)
    end
    put(out, "planar_damage", U.call(c.planardamage, "GetDamage"))
    put(out, "planar_defense", U.call(c.planardefense, "GetDefense"))
    if cfg.info.attack_range and c.combat then
        put(out, "attack_range", c.combat.attackrange)
    end
    if c.armor then
        put(out, "armor", c.armor.condition)
        put(out, "absorption", percent(c.armor.absorb_percent))
    end
    if c.health then
        put(out, "absorption", percent(c.health.absorb))
    end
    if c.freezable and c.freezable:IsFrozen() then
        put(out, "frozen", true)
    end
    if c.burnable and c.burnable:IsBurning() then
        put(out, "burning", true)
    end
end)

register("food", function(out, entity, context)
    local c = entity.components or {}
    if c.stackable then
        put(out, "count", c.stackable:StackSize())
    end
    if c.perishable then
        put(out, "freshness", percent(c.perishable:GetPercent()))
        put(out, "perish_time", c.perishable.perishremainingtime)
    end
    local cooking = context.cooking
    local ingredient = cooking and Recipes.ingredient(cooking, entity.prefab)
    if ingredient then
        local tags, text = ingredient.tags or {}, {}
        for _, key in ipairs(U.sortedkeys(tags)) do
            text[#text + 1] = key .. " " .. tostring(tags[key])
        end
        put(out, "ingredients", table.concat(text, ", "))
    end
end)

register("equipment", function(out, entity)
    local c = entity.components or {}
    if c.finiteuses then
        put(out, "uses", c.finiteuses:GetUses())
        put(out, "uses_max", c.finiteuses.total)
        put(out, "durability", percent(c.finiteuses:GetPercent()))
    end
    if c.waterproofer then
        put(out, "waterproof", percent(c.waterproofer:GetEffectiveness()))
    end
    if c.insulator then
        put(out, "insulation", c.insulator:GetInsulation())
        put(out, "insulation_type", c.insulator:GetType())
    end
    if c.equippable then
        put(out, "speed", c.equippable.walkspeedmult)
        put(out, "dapperness", c.equippable.dapperness)
    end
end)

register("details", function(out, entity, context)
    local c = entity.components or {}
    if c.perishable then
        local estimate, state = Details.perish(entity, context.G)
        put(out, "perish_estimate", estimate)
        put(out, "perish_state", state)
    end
    if c.rechargeable then
        put(out, "recharge", percent(U.call(c.rechargeable, "GetPercent")))
        put(out, "cooldown_time", U.call(c.rechargeable, "GetTimeToCharge"))
    elseif c.cooldown then
        put(out, "cooldown_time", U.call(c.cooldown, "GetTimeToCharged"))
    end
    if c.inventoryitem then
        put(out, "item_moisture", U.call(entity, "GetMoisture"))
    end
    put(out, "item_temperature", U.call(c.temperature, "GetCurrent"))
    if c.sewing then
        put(out, "sew_value", c.sewing.repair_value)
    end
    if c.repairer then
        for key, field in pairs({
            repair_health = "healthrepairvalue",
            repair_uses = "finiteusesrepairvalue",
            repair_work = "workrepairvalue",
        }) do
            if (c.repairer[field] or 0) > 0 then
                put(out, key, c.repairer[field])
            end
        end
        if (c.repairer.perishrepairpercent or 0) > 0 then
            put(out, "repair_freshness", percent(c.repairer.perishrepairpercent))
        end
        if (c.repairer.healthrepairpercent or 0) > 0 then
            put(out, "repair_percent", percent(c.repairer.healthrepairpercent))
        end
    end
    put(out, "timers", Details.timers(entity, context.now))
end)

register("progress", function(out, entity, context)
    local c = entity.components or {}
    local now = context.now
    if c.fueled then
        put(out, "fuel", percent(c.fueled:GetPercent()))
        if U.finite(c.fueled.rate) and c.fueled.rate > 0 then
            put(out, "fuel_time", c.fueled.currentfuel / c.fueled.rate)
        end
    end
    if c.fuel then
        put(out, "fuel_value", c.fuel.fuelvalue)
    end
    if c.stewer and c.stewer:IsCooking() then
        put(out, "cook_time", c.stewer:GetTimeToCook())
    end
    if c.stewer and c.stewer.product then
        put(out, "cook_product", c.stewer.product)
        put(out, "process_state", c.stewer:IsCooking() and "cooking" or "ready_to_harvest")
    end
    if c.dryer and c.dryer:IsDrying() then
        put(out, "dry_time", c.dryer:GetTimeToDry())
    end
    if c.dryer and c.dryer.product then
        put(out, "dry_product", c.dryer.product)
        put(
            out,
            "process_state",
            not c.dryer.ingredient and "ready_to_harvest" or (U.call(c.dryer, "IsPaused") and "paused" or "drying")
        )
    end
    local dryingrack = c.dryingrack or c.wobyrack
    if dryingrack then
        -- 新版肉架按格子计时；只读原版快照，显示下一份完成品的剩余时间。
        local remaining
        for _, value in pairs(dryingrack:GetDryingInfoSnapshot() or {}) do
            if U.finite(value) and value >= 0 then
                remaining = math.min(remaining or value, value)
            end
        end
        put(out, "dry_time", remaining)
        if remaining then
            put(out, "process_state", dryingrack.dryingpaused and "paused" or "drying")
        end
        local rack_container = U.call(dryingrack, "GetContainer")
        if rack_container then
            local products = {}
            for slot = 1, math.min(rack_container.numslots or 0, 12) do
                local item = rack_container:GetItemInSlot(slot)
                if U.valid(item) then
                    local product = U.call(item.components.dryable, "GetProduct") or item.prefab
                    products[#products + 1] = product
                end
            end
            if #products > 0 then
                put(out, "dry_product", table.concat(products, ","))
                if not remaining then
                    put(out, "process_state", "ready_to_harvest")
                end
            end
        end
    end
    if c.growable then
        put(out, "stage", c.growable:GetStage())
        if c.growable.targettime then
            put(out, "growth_time", math.max(0, c.growable.targettime - now))
        end
    end
    if c.pickable and not c.pickable.canbepicked and not c.pickable.paused and not entity:HasTag("withered") then
        local pickable = c.pickable
        local remaining
        if pickable.useexternaltimer and type(pickable.getregentimertime) == "function" then
            -- 当前原版草、树枝、浆果可使用 worldsettingstimer；参数是实体，不是组件。
            remaining = pickable.getregentimertime(entity)
        elseif U.finite(pickable.targettime) then
            remaining = pickable.targettime - now
        end
        if U.finite(remaining) then
            put(out, "growth_time", math.max(0, remaining))
        end
    end
    if c.harvestable then
        put(out, "harvest", c.harvestable.produce)
    end
end)

register("farm", function(out, entity, context)
    local c = entity.components or {}
    local G = context.G
    if c.farmplantstress then
        put(out, "stress_points", c.farmplantstress.stress_points)
        put(out, "stress_max", c.farmplantstress.max_stress_points)
        -- 展示已经记录的本阶段压力源，不调用可能带副作用的未知测试函数。
        local sources = {}
        for _, key in ipairs(U.sortedkeys(c.farmplantstress.stressors or {})) do
            if c.farmplantstress.stressors[key] then
                sources[#sources + 1] = key
            end
        end
        put(out, "stress_sources", #sources > 0 and table.concat(sources, ",") or "none")
    end
    if c.fertilizer then
        local values = c.fertilizer.nutrients
        if values then
            put(out, "fertilizer", table.concat(values, " / "))
        end
    end
    if entity:HasTag("farm_plant") and G.TheWorld.components.farming_manager then
        local farm = G.TheWorld.components.farming_manager
        local x, y, z = entity.Transform:GetWorldPosition()
        put(out, "moisture", U.call(farm, "IsSoilMoistAtPoint", x, y, z))
        local a, b, d = U.call(farm, "GetTileNutrients", G.TheWorld.Map:GetTileCoordsAtPoint(x, y, z))
        if a and b and d then
            put(out, "nutrients", a .. " / " .. b .. " / " .. d)
        end
    end
end)

register("follower", function(out, entity, context)
    local c = entity.components or {}
    local now = context.now
    if c.follower then
        if U.valid(c.follower.leader) then
            put(out, "leader", c.follower.leader:GetDisplayName())
        end
        if c.follower.targettime then
            put(out, "loyalty", math.max(0, c.follower.targettime - now))
        end
    end
end)

register("beefalo", function(out, entity, context)
    local c = entity.components or {}
    local G = context.G
    if c.domesticatable then
        put(out, "domestication", percent(c.domesticatable:GetDomestication()))
        put(out, "obedience", percent(c.domesticatable:GetObedience()))
        put(out, "domesticated", c.domesticatable:IsDomesticated())
        put(out, "tendency", entity.tendency or "default")
    end
    if c.rideable then
        if c.hunger then
            put(out, "hunger", c.hunger.current)
            put(out, "hunger_max", c.hunger.max)
        end
        local saddle = c.rideable.saddle
        if U.valid(saddle) then
            put(out, "saddle_name", saddle.prefab)
            put(out, "saddle_uses", U.call(saddle.components.finiteuses, "GetUses"))
        end
        -- 直接读原版踢落任务的剩余时间；顺从度变化可能重置任务，不自行复刻公式。
        if entity._bucktask and G.GetTaskRemaining then
            put(out, "ride_time", G.GetTaskRemaining(entity._bucktask))
        end
    end
end)

-- 公共事实按读取器隔离；一个新组件接口失效时仍返回其它可用字段。
-- 汇总独立读取器的公共事实，单组失败时仍保留其它组。
function M.common(entity, context)
    local out = M.health(entity, context)
    for _, reader in ipairs(readers) do
        local fields = read_safely(reader.id, reader.read, context, entity, context)
        for key, value in pairs(fields) do
            out[key] = value
        end
    end
    return out
end

local viewer_readers = {}
local function register_viewer(id, read)
    viewer_readers[#viewer_readers + 1] = { id = id, read = read }
end

register_viewer("food", function(out, entity, viewer)
    local c, vc = entity.components or {}, viewer.components or {}
    if c.edible and vc.eater then
        local eater = vc.eater
        local can = eater:PrefersToEat(entity)
        put(out, "edible", can)
        put(out, "food_type", c.edible.foodtype)
        -- 未知食用修正回调可能改变世界状态；查询不能为了估算而执行它。
        if can and not eater.custom_stats_mod_fn then
            local memory = vc.foodmemory and vc.foodmemory:GetFoodMultiplier(entity.prefab) or 1
            local amount = eater.eatwholestack
                    and (U.call(c.edible, "GetStackMultiplier") or U.call(c.stackable, "StackSize"))
                or 1
            for _, field in ipairs({ { "health", "GetHealth" }, { "hunger", "GetHunger" }, { "sanity", "GetSanity" } }) do
                local stat, method = field[1], field[2]
                local absorption = eater[stat .. "absorption"]
                if vc[stat] and U.finite(absorption) then
                    local v = c.edible[method](c.edible, viewer)
                    if stat ~= "hunger" and c.edible[stat .. "value"] < 0 and not eater:DoFoodEffects(entity) then
                        v = 0
                    end
                    put(out, "food_" .. stat, v * memory * absorption * (amount or 1))
                end
            end
        end
    end
end)

register_viewer("farm", function(out, entity, viewer)
    local c = entity.components or {}
    if c.farmplantstress then
        put(out, "stress", c.farmplantstress:GetStressDescription(viewer))
    end
end)

register_viewer("container", function(out, entity, _, context)
    local c = entity.components or {}
    if context.config.info.container_contents then
        local container = Containers.readable(entity)
        if container then
            put(out, "contents", summary(container))
        end
        if c.unwrappable and c.unwrappable.itemdata then
            local names = {}
            for i, record in ipairs(c.unwrappable.itemdata) do
                if i > 40 then
                    break
                end
                names[#names + 1] = tostring(record.prefab)
                    .. " ×"
                    .. tostring(record.data and record.data.stackable and record.data.stackable.stack or 1)
            end
            put(out, "bundle", table.concat(names, ", "))
        end
    end
end)

register_viewer("world", function(out, entity, viewer, context)
    local vc = viewer.components or {}
    if entity == viewer then
        local state = context.G.TheWorld.state
        for _, pair in ipairs({
            { "season", "season" },
            { "remainingdaysinseason", "season_days" },
            { "cycles", "day" },
            { "phase", "phase" },
            { "temperature", "temperature" },
            { "wetness", "wetness" },
        }) do
            local value = state[pair[1]]
            put(out, pair[2], pair[2] == "day" and U.finite(value) and value + 1 or value)
        end
        -- 当前 kramped 属于世界且把每个玩家的计数保存在私有闭包中；
        -- 没有结构化只读接口时不展示猜测值，也不替换原版惩罚机制。
        if vc.hunger then
            put(out, "hunger_rate", vc.hunger.hungerrate)
        end
        if vc.sanity then
            put(out, "sanity_rate", vc.sanity.rate)
        end
        if context.config.info.world_events then
            local timer = context.G.TheWorld.components.worldsettingstimer
            local events = {}
            for _, key in ipairs(timer and U.sortedkeys(timer.timers) or {}) do
                local remaining = U.call(timer, "GetTimeLeft", key)
                if U.finite(remaining) then
                    events[#events + 1] = key .. " " .. math.ceil(remaining) .. "s"
                end
                if #events >= 12 then
                    break
                end
            end
            put(out, "world_events", table.concat(events, ", "))
        end
    end
end)

-- 服务器许可和个人显示使用同一分组；不能用大类开关绕过较细的禁用项。
function M.group(key)
    if key == "recharge" or key == "cooldown_time" then
        return "cooldowns"
    end
    if key == "timers" then
        return "timers"
    end
    if key == "freshness" or key:match("^perish_") then
        return "perishable"
    end
    local schema = M.schema[key]
    if not schema then
        return nil
    end
    return schema.category == "food" and "food_values" or schema.category
end

-- 查看者数据独立计算；失败时省略估值，不伪造零值或复用别人的角色数据。
-- 计算当前查看者专属信息，避免角色饮食差异污染公共缓存。
function M.viewer(entity, viewer, context)
    local out = {}
    for _, reader in ipairs(viewer_readers) do
        local fields = read_safely("viewer_" .. reader.id, reader.read, context, entity, viewer, context)
        for key, value in pairs(fields) do
            out[key] = value
        end
    end
    return out
end

-- 按订阅用途与服务器规则筛选可发送字段。
function M.filter(fields, mask, config)
    if mask == "health" then
        local health = {}
        for _, key in ipairs({ "health", "health_max" }) do
            if U.finite(fields[key]) then
                health[key] = fields[key]
            end
        end
        return health
    end
    local out = {}
    for key, value in pairs(fields) do
        local schema = M.schema[key]
        local full = mask ~= "health" and config.info.enabled
        local mount = mask == "beefalo" and config.beefalo.enabled
        local group = M.group(key)
        if
            schema
            and ((key == "health" or key == "health_max") or full or (mount and schema.category == "beefalo"))
            and (
                not full
                or config.info[group] ~= false
                or (mount and (schema.category == "beefalo" or key == "health" or key == "health_max"))
            )
        then
            out[key] = value
        end
    end
    return M.sanitize(out)
end

-- 按 schema 校验字段类型，并限制文本总量，给 JSON 转义和删除键列表保留预算。
-- 数值不因长容器摘要被挤掉；相同输入按稳定键顺序产生相同快照。
function M.sanitize(fields)
    local out, remaining = {}, 960
    if type(fields) ~= "table" then
        return out
    end
    for _, key in ipairs(schema_keys) do
        local value, expected = fields[key], M.schema[key].value_type
        local kind = type(value)
        if kind == "number" and U.finite(value) and (expected == "number" or expected == "scalar") then
            out[key] = value
        elseif kind == "boolean" and (expected == "boolean" or expected == "scalar") then
            out[key] = value
        elseif kind == "string" and (expected == "text" or expected == "scalar") and remaining > 0 then
            out[key] = U.textlimit(value, math.min(240, remaining))
            remaining = remaining - #out[key]
        end
    end
    return out
end
return M
