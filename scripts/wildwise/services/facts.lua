local U = require("wildwise/core/util")
local M = {}
M.schema = {}
local function define(id, category, unit, detail, viewer)
    M.schema[id] = { id = id, category = category, unit = unit or "", detail = detail or 1,
        viewer = viewer or false, ttl = (id == "health" or id == "health_max") and .1 or .5, value_type = "scalar" }
end
for _, id in ipairs({ "health", "health_max", "damage", "armor", "absorption", "attack_range", "frozen", "burning" }) do
    define(id, "combat", id == "absorption" and "%" or "", id == "attack_range" and 2 or 1)
end
for _, id in ipairs({ "food_health", "food_hunger", "food_sanity", "edible", "food_type" }) do define(id, "food", "", 1, true) end
for _, id in ipairs({ "freshness", "perish_time", "ingredients" }) do define(id, "food", id == "freshness" and "%" or "", 2) end
for _, id in ipairs({ "durability", "uses", "uses_max", "waterproof", "insulation", "insulation_type", "speed", "dapperness" }) do
    define(id, "equipment", (id == "durability" or id == "waterproof") and "%" or "", 1)
end
for _, id in ipairs({ "fuel", "fuel_time", "fuel_value", "cook_time", "dry_time", "growth_time", "stage", "harvest" }) do
    define(id, "progress", id:match("time$") and "s" or "", 1)
end
for _, id in ipairs({ "moisture", "nutrients", "stress", "fertilizer" }) do define(id, "farm", "", 2, id == "stress") end
for _, id in ipairs({ "leader", "loyalty" }) do define(id, "follower", id == "loyalty" and "s" or "", 1) end
for _, id in ipairs({ "contents", "bundle", "count" }) do define(id, "container", "", id == "count" and 1 or 2) end
for _, id in ipairs({ "domestication", "obedience", "hunger", "hunger_max", "tendency", "domesticated", "ride_time", "saddle_uses" }) do
    define(id, "beefalo", (id == "domestication" or id == "obedience") and "%" or (id == "ride_time" and "s" or ""), 1)
end
for _, id in ipairs({ "season", "season_days", "day", "phase", "temperature", "wetness", "naughtiness", "hunger_rate", "sanity_rate", "world_events" }) do
    define(id, "world", "", 2)
end

local function put(fields, key, value)
    if type(value) == "number" and U.finite(value) then fields[key] = math.floor(value * 100 + .5) / 100
    elseif type(value) == "string" then fields[key] = value:sub(1, 1600)
    elseif type(value) == "boolean" then fields[key] = value end
end
local function percent(value) return U.finite(value) and value * 100 or nil end
local function summary(container)
    local items = {}
    for slot = 1, math.min(container.numslots or 0, 80) do
        local item = container:GetItemInSlot(slot)
        if U.valid(item) then
            items[#items + 1] = (item.prefab or "?") .. " ×" .. tostring(U.call(item.components.stackable, "StackSize") or 1)
        end
    end
    return table.concat(items, ", ")
end
function M.health(entity)
    local out, c = {}, entity.components or {}
    if c.health then
        put(out, "health", c.health.currenthealth)
        put(out, "health_max", U.call(c.health, "GetMaxWithPenalty") or c.health.maxhealth)
    end
    return out
end
function M.common(entity, context)
    local out, c = M.health(entity), entity.components or {}
    local now, G, cfg = context.now, context.G, context.config
    if c.combat then put(out, "damage", c.combat.defaultdamage) end
    if c.weapon and type(c.weapon.damage) == "number" then put(out, "damage", c.weapon.damage) end
    if cfg.info.attack_range and c.combat then put(out, "attack_range", c.combat.attackrange) end
    if c.armor then
        put(out, "armor", c.armor.condition); put(out, "absorption", percent(c.armor.absorb_percent))
    end
    if c.health then put(out, "absorption", percent(c.health.absorb)) end
    if c.freezable and c.freezable:IsFrozen() then put(out, "frozen", true) end
    if c.burnable and c.burnable:IsBurning() then put(out, "burning", true) end
    if c.stackable then put(out, "count", c.stackable:StackSize()) end
    if c.perishable then
        put(out, "freshness", percent(c.perishable:GetPercent()))
        put(out, "perish_time", c.perishable.perishremainingtime)
    end
    local cooking = context.cooking
    if cooking and cooking.ingredients[entity.prefab] then
        local tags, text = cooking.ingredients[entity.prefab].tags or {}, {}
        for _, key in ipairs(U.sortedkeys(tags)) do text[#text + 1] = key .. " " .. tostring(tags[key]) end
        put(out, "ingredients", table.concat(text, ", "))
    end
    if c.finiteuses then
        put(out, "uses", c.finiteuses:GetUses()); put(out, "uses_max", c.finiteuses.total)
        put(out, "durability", percent(c.finiteuses:GetPercent()))
    end
    if c.waterproofer then put(out, "waterproof", percent(c.waterproofer:GetEffectiveness())) end
    if c.insulator then put(out, "insulation", c.insulator:GetInsulation()); put(out, "insulation_type", c.insulator:GetType()) end
    if c.equippable then put(out, "speed", c.equippable.walkspeedmult); put(out, "dapperness", c.equippable.dapperness) end
    if c.fueled then
        put(out, "fuel", percent(c.fueled:GetPercent()))
        if U.finite(c.fueled.rate) and c.fueled.rate > 0 then put(out, "fuel_time", c.fueled.currentfuel / c.fueled.rate) end
    end
    if c.fuel then put(out, "fuel_value", c.fuel.fuelvalue) end
    if c.stewer and c.stewer:IsCooking() then put(out, "cook_time", c.stewer:GetTimeToCook()) end
    if c.dryer and c.dryer:IsDrying() then put(out, "dry_time", c.dryer:GetTimeToDry()) end
    if c.growable then
        put(out, "stage", c.growable:GetStage())
        if c.growable.targettime then put(out, "growth_time", math.max(0, c.growable.targettime - now)) end
    end
    if c.harvestable then put(out, "harvest", c.harvestable.produce) end
    if c.fertilizer then
        local values = c.fertilizer.nutrients
        if values then put(out, "fertilizer", table.concat(values, " / ")) end
    end
    if entity:HasTag("farm_plant") and G.TheWorld.components.farming_manager then
        local farm = G.TheWorld.components.farming_manager
        local x, y, z = entity.Transform:GetWorldPosition()
        put(out, "moisture", U.call(farm, "IsSoilMoistAtPoint", x, y, z))
        local a, b, d = U.call(farm, "GetTileNutrients", G.TheWorld.Map:GetTileCoordsAtPoint(x, y, z))
        if a and b and d then put(out, "nutrients", a .. " / " .. b .. " / " .. d) end
    end
    if c.follower then
        if U.valid(c.follower.leader) then put(out, "leader", c.follower.leader:GetDisplayName()) end
        if c.follower.targettime then put(out, "loyalty", math.max(0, c.follower.targettime - now)) end
    end
    if c.domesticatable then
        put(out, "domestication", percent(c.domesticatable:GetDomestication()))
        put(out, "obedience", percent(c.domesticatable:GetObedience()))
        put(out, "domesticated", c.domesticatable:IsDomesticated())
        put(out, "tendency", entity.tendency or "default")
    end
    if c.rideable then
        if c.hunger then put(out, "hunger", c.hunger.current); put(out, "hunger_max", c.hunger.max) end
        local saddle = c.rideable.saddle
        if U.valid(saddle) then put(out, "saddle_uses", U.call(saddle.components.finiteuses, "GetUses")) end
        -- 直接读原版踢落任务的剩余时间；顺从度变化可能重置任务，不自行复刻公式。
        if entity._bucktask and G.GetTaskRemaining then put(out, "ride_time", G.GetTaskRemaining(entity._bucktask)) end
    end
    return out
end
function M.viewer(entity, viewer, context)
    local out, c, vc = {}, entity.components or {}, viewer.components or {}
    if c.edible and vc.eater then
        local eater = vc.eater
        local can = eater:PrefersToEat(entity)
        put(out, "edible", can)
        put(out, "food_type", c.edible.foodtype)
        -- 未知食用修正回调可能改变世界状态；查询不能为了估算而执行它。
        if can and not eater.custom_stats_mod_fn then
            local memory = vc.foodmemory and vc.foodmemory:GetFoodMultiplier(entity.prefab) or 1
            local amount = eater.eatwholestack and (U.call(c.edible, "GetStackMultiplier") or U.call(c.stackable, "StackSize")) or 1
            for _, field in ipairs({ {"health", "GetHealth"}, {"hunger", "GetHunger"}, {"sanity", "GetSanity"} }) do
                local stat, method = field[1], field[2]
                local absorption = eater[stat .. "absorption"]
                if vc[stat] and U.finite(absorption) then
                    local v = c.edible[method](c.edible, viewer)
                    if stat ~= "hunger" and c.edible[stat .. "value"] < 0 and not eater:DoFoodEffects(entity) then v = 0 end
                    put(out, "food_" .. stat, v * memory * absorption * (amount or 1))
                end
            end
        end
    end
    if c.farmplantstress then put(out, "stress", c.farmplantstress:GetStressDescription(viewer)) end
    if context.config.info.container_contents then
        if c.container and c.container.canbeopened ~= false then put(out, "contents", summary(c.container)) end
        if c.unwrappable and c.unwrappable.itemdata then
            local names = {}
            for i, record in ipairs(c.unwrappable.itemdata) do
                if i > 40 then break end
                names[#names + 1] = tostring(record.prefab) .. " ×" .. tostring(record.data and record.data.stackable and record.data.stackable.stack or 1)
            end
            put(out, "bundle", table.concat(names, ", "))
        end
    end
    if entity == viewer then
        local state = context.G.TheWorld.state
        for _, pair in ipairs({ {"season", "season"}, {"remainingdaysinseason", "season_days"}, {"cycles", "day"},
            {"phase", "phase"}, {"temperature", "temperature"}, {"wetness", "wetness"} }) do put(out, pair[2], state[pair[1]]) end
        if vc.kramped then put(out, "naughtiness", vc.kramped.naughtiness) end
        if vc.hunger then put(out, "hunger_rate", vc.hunger.hungerrate) end
        if vc.sanity then put(out, "sanity_rate", vc.sanity.rate) end
        if context.config.info.world_events then
            local timer = context.G.TheWorld.components.worldsettingstimer
            local events = {}
            for _, key in ipairs(timer and U.sortedkeys(timer.timers) or {}) do
                local remaining = U.call(timer, "GetTimeLeft", key)
                if U.finite(remaining) then events[#events + 1] = key .. " " .. math.ceil(remaining) .. "s" end
                if #events >= 12 then break end
            end
            put(out, "world_events", table.concat(events, ", "))
        end
    end
    return out
end
function M.filter(fields, mask, config)
    local out = {}
    for key, value in pairs(fields) do
        local schema = M.schema[key]
        local full = mask ~= "health" and config.info.enabled
        local mount = mask == "beefalo" and config.beefalo.enabled
        if schema and ((key == "health" or key == "health_max")
            or full or (mount and schema.category == "beefalo")) then out[key] = value end
    end
    return out
end
return M
