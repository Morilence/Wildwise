local U = require("wildwise/core/util")
local Lifetime = require("wildwise/core/lifetime")
local Facts = require("wildwise/services/facts")
local Protocol = require("wildwise/core/protocol")
local Observer = {}; Observer.__index = Observer
function Observer.new(context, send)
    return setmetatable({ context = context, send = send, entities = {}, players = {}, computes = 0 }, Observer)
end
function Observer:authorized(player, target)
    if not U.valid(target) or not U.valid(player) or not target.Transform then return false end
    local mount = U.call(player.components.rider, "GetMount")
    local owner = U.call(target.components and target.components.inventoryitem, "GetGrandOwner")
    if target == mount or target == player or owner == player then return true end
    -- 在别人的背包中、或不可见的目标不能靠猜实体引用读取；每次更新都复查。
    if owner and (not owner.components.container or not owner.components.container:IsOpenedBy(player)) then return false end
    if U.distance(player, target) > self.context.config.info_radius^2 then return false end
    local visible = self.context.G.CanEntitySeeTarget
    return not visible or visible(player, target)
end
function Observer:subscribe(player, target, mask, now)
    if not self:authorized(player, target) then return false end
    local subscriptions = self.players[player] or {}; self.players[player] = subscriptions
    if not subscriptions[target] and U.count(subscriptions) >= self.context.config.observer_limit then return false end
    local record = self.entities[target]
    if not record then
        -- 多人共用实体事实与一个 healthdelta 监听；角色食用效果始终放在各自 sub.view。
        record = { scope = Lifetime.new(), subscribers = {}, next_common = 0, health_dirty = true }
        self.entities[target] = record
        record.scope:listen(target, "healthdelta", function() record.health_dirty = true end)
        record.scope:listen(target, "onremove", function() self:remove(target) end)
    end
    if subscriptions[target] then
        local sub = subscriptions[target]
        if sub.mask ~= mask then sub.fresh, sub.next_dynamic, record.next_common = true, 0, 0 end
        sub.mask, sub.expires = mask, now + 6
        return true
    end
    local sub = { player = player, mask = mask, previous = {}, fresh = true, expires = now + 6, next_dynamic = 0 }
    subscriptions[target], record.subscribers[player] = sub, sub
    return true
end
function Observer:unsubscribe(player, target)
    if self.players[player] then
        self.players[player][target] = nil
        if next(self.players[player]) == nil then self.players[player] = nil end
    end
    local record = self.entities[target]
    if record then
        record.subscribers[player] = nil
        if next(record.subscribers) == nil then record.scope:close(); self.entities[target] = nil end
    end
end
function Observer:remove(target)
    local record = self.entities[target]
    if not record then return end
    local users = {}; for p in pairs(record.subscribers) do users[#users + 1] = p end
    for _, player in ipairs(users) do self.send(player, target, "invalidate", {}); self:unsubscribe(player, target) end
end
function Observer:forget(player)
    local targets = {}; for target in pairs(self.players[player] or {}) do targets[#targets + 1] = target end
    for _, target in ipairs(targets) do self:unsubscribe(player, target) end
end
function Observer:tick(now)
    self.context.now = now
    for target, record in pairs(self.entities) do
        if not U.valid(target) then self:remove(target) else
            local refresh = now >= record.next_common
            if refresh then
                local full = false
                for _, sub in pairs(record.subscribers) do if sub.mask ~= "health" then full = true; break end end
                record.common = full and Facts.common(target, self.context) or Facts.health(target)
                record.next_common = now + .5; self.computes = self.computes + 1
            elseif record.health_dirty then
                local hp = Facts.health(target)
                record.common.health, record.common.health_max = hp.health, hp.health_max
            end
            for player, sub in pairs(record.subscribers) do
                if now > sub.expires or not self:authorized(player, target) then
                    self.send(player, target, "invalidate", {}); self:unsubscribe(player, target)
                elseif sub.fresh or refresh or record.health_dirty or now >= sub.next_dynamic then
                    local fields = U.copy(record.common)
                    if sub.mask ~= "health" and (refresh or sub.fresh or now >= sub.next_dynamic) then
                        sub.view = Facts.viewer(target, player, self.context); sub.next_dynamic = now + .5
                    end
                    for k, v in pairs(sub.view or {}) do fields[k] = v end
                    fields = Facts.filter(fields, sub.mask, self.context.config)
                    local changes, removed = Protocol.diff(sub.previous, fields)
                    if sub.fresh or next(changes) or #removed > 0 then
                        self.send(player, target, sub.fresh and "snapshot" or "delta", { fields = changes, removed = removed })
                        sub.previous, sub.fresh = fields, false
                    end
                end
            end
            record.health_dirty = false
        end
    end
end
function Observer:close()
    for _, record in pairs(self.entities) do record.scope:close() end
    self.entities, self.players = {}, {}
end
return Observer
