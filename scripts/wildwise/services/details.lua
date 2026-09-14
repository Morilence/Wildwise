local U = require("wildwise/core/util")
local M = {}

-- 只读当前公开组件状态，估算环境不变时的余量；未知回调或酸雨额外腐败时明确降级。
function M.perish(item, G)
    local c, world = item.components or {}, G.TheWorld
    local p, t = c.perishable, G.TUNING
    if not p or not U.finite(p.perishremainingtime) or not world or not t then
        return nil, "unknown"
    end
    if not p.updatetask then
        return nil, "paused"
    end
    local owner = c.inventoryitem and c.inventoryitem.owner or U.call(c.occupier, "GetOwner")
    if not owner and world.state.isacidraining and not c.rainimmunity then
        return nil, "acid_rain"
    end
    local modifier = 1
    if owner then
        local preserver = owner.components and owner.components.preserver
        if preserver then
            if type(preserver.perish_rate_multiplier) == "function" then
                return nil, "custom_modifier"
            end
            modifier = preserver.perish_rate_multiplier or 1
        elseif owner:HasTag("fridge") then
            local frozen = item:HasTag("frozen") and not owner:HasTag("nocool") and not owner:HasTag("lowcool")
            modifier = frozen and t.PERISH_COLD_FROZEN_MULT or t.PERISH_FRIDGE_MULT
        elseif owner:HasTag("foodpreserver") then
            modifier = t.PERISH_FOOD_PRESERVER_MULT
        elseif owner:HasTag("cage") and item:HasTag("small_livestock") then
            modifier = t.PERISH_CAGE_MULT
        end
        if owner:HasTag("spoiler") then
            modifier = modifier * t.PERISH_GROUND_MULT
        end
    else
        modifier = t.PERISH_GROUND_MULT
    end
    local pos = (owner or item):GetPosition()
    local temperature = world.state.temperature
    if G.GetTemperatureAtXZ and not (owner and owner:HasTag("pocketdimension_container")) then
        temperature = G.GetTemperatureAtXZ(pos.x, pos.z)
    end
    if not U.finite(temperature) or not U.finite(modifier) then
        return nil, "unknown"
    end
    if U.call(item, "GetIsWet") and not p.ignorewentness then
        modifier = modifier * t.PERISH_WET_MULT
    end
    if temperature < 0 then
        if item:HasTag("frozen") and not p.frozenfiremult then
            modifier = t.PERISH_COLD_FROZEN_MULT
        else
            modifier = modifier * t.PERISH_WINTER_MULT
        end
    end
    if p.frozenfiremult then
        modifier = modifier * t.PERISH_FROZEN_FIRE_MULT
    end
    if temperature > t.OVERHEAT_TEMP then
        modifier = modifier * t.PERISH_SUMMER_MULT
    end
    modifier = modifier * (p.localPerishMultiplyer or 1) * t.PERISH_GLOBAL_MULT
    if not U.finite(modifier) then
        return nil, "unknown"
    end
    if modifier <= 0 then
        return nil, modifier < 0 and "freshening" or "paused"
    end
    return math.max(0, p.perishremainingtime / modifier), "environment_estimate"
end

-- 使用有明确玩家含义的计时器白名单；不展示未命名内部机制和隐藏事件。
M.timer_names = {
    regen = "regrowth",
    regrow = "regrowth",
    grow = "regrowth",
    regrowth = "regrowth",
    cooldown = "cooldown",
    recharge = "recharge",
    decay = "decay",
    harvested = "regrowth",
}

function M.timers(entity, now)
    local output, c = {}, entity.components or {}
    for _, component in ipairs({ "timer", "worldsettingstimer" }) do
        local timer = c[component]
        for _, key in ipairs(timer and U.sortedkeys(timer.timers) or {}) do
            local value, label = timer.timers[key], M.timer_names[key]
            if label and type(value) == "table" then
                local paused = value.paused or value.enabled == false
                local remaining = paused and value.timeleft or (U.finite(value.end_time) and value.end_time - now)
                if U.finite(remaining) then
                    output[#output + 1] = label
                        .. ":"
                        .. math.ceil(math.max(0, remaining))
                        .. ":"
                        .. (paused and "paused" or "running")
                end
            end
            if #output >= 6 then
                return table.concat(output, ";")
            end
        end
    end
    return #output > 0 and table.concat(output, ";") or nil
end

return M
