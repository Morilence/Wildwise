local U = require("wildwise/core/util")
local M = {}

-- 依据原版战斗目标及选定的队友范围判断是否显示血条。
function M.hostility(target, viewer, scope, players, radius)
    if not U.valid(target) then
        return false
    end
    local combat = target.components and target.components.combat
    local victim = combat and combat.target
    if not U.valid(victim) then
        return false
    end
    if victim == viewer then
        return true, true
    end
    local followers = scope == "followers" or scope == "nearby_followers"
    local nearby = scope == "nearby" or scope == "nearby_followers"
    local leader = victim.components and victim.components.follower and victim.components.follower.leader
    if followers and leader == viewer then
        return true, false
    end
    if nearby then
        for _, player in ipairs(players or {}) do
            if
                U.valid(player)
                and U.distance(player, viewer) <= radius * radius
                and (victim == player or (followers and leader == player))
            then
                return true, false
            end
        end
    end
    return false
end

-- 按悬浮、直接威胁、距离和稳定顺序选出有界血条列表。
function M.select(candidates, hover, limit, now, linger)
    local eligible = {}
    for target, state in pairs(candidates) do
        if
            U.valid(target)
            and state.visible
            and not state.dead
            and (state.hostile or now - state.last_hostile < linger)
        then
            eligible[#eligible + 1] = { target = target, state = state }
        end
    end
    table.sort(eligible, function(a, b)
        local ah, bh = a.target == hover, b.target == hover
        if ah ~= bh then
            return ah
        end
        if a.state.direct ~= b.state.direct then
            return a.state.direct == true
        end
        if a.state.distance ~= b.state.distance then
            return a.state.distance < b.state.distance
        end
        return a.state.order < b.state.order
    end)
    local selected = {}
    for i = 1, math.min(limit, #eligible) do
        selected[#selected + 1] = eligible[i].target
    end
    return selected
end
return M
