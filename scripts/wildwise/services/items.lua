local U = require("wildwise/core/util")
local Items = {}; Items.__index = Items
function Items.new(config, environment)
    return setmetatable({ config = config, env = environment, known = setmetatable({}, { __mode = "k" }),
        pending = {}, head = 1, tail = 0, queued = {}, serial = 0, reservations = {}, index = {}, processed = 0, dropped = 0 }, Items)
end
function Items:unindex(item)
    local record = self.known[item]
    local bucket = record and record.cell and self.index[record.cell]
    if bucket then
        bucket[item] = nil
        if next(bucket) == nil then self.index[record.cell] = nil end
    end
    if record then record.cell = nil end
end
function Items:forget(item) self:unindex(item); self.known[item] = nil end
function Items:cell(item)
    local x, y, z = item.Transform:GetWorldPosition()
    local platform = U.platform(item)
    -- 船以自身局部坐标分桶，移动船不会让静置货物的索引失效。
    if platform and platform.entity then
        local lx, _, lz = platform.entity:WorldToLocalSpace(x, y, z); x, z = lx, lz
    end
    return (item.prefab or "") .. ":" .. (item.skinname or "") .. ":" .. tostring(platform or "land"),
        math.floor(x / self.config.items.radius), math.floor(z / self.config.items.radius)
end
function Items:indexitem(item)
    self:unindex(item)
    if U.call(item.components.stackable, "IsFull") then return end
    local prefix, x, z = self:cell(item)
    local key = prefix .. ":" .. x .. ":" .. z
    local bucket = self.index[key] or {}; self.index[key] = bucket
    bucket[item] = true; self.known[item].cell = key
end
function Items:neighbors(item)
    local prefix, x, z = self:cell(item)
    local out = {}
    -- 只索引已确认来源的可合堆物，不对千件掉落反复调用整片 FindEntities 并排序。
    for dx = -1, 1 do for dz = -1, 1 do
        for target in pairs(self.index[prefix .. ":" .. (x + dx) .. ":" .. (z + dz)] or {}) do
            if target ~= item and U.valid(target) and U.distance(item, target) <= self.config.items.radius^2 then out[#out + 1] = target end
        end
    end end
    return out
end
function Items:mark(item, source, now)
    if not U.valid(item) then return end
    self:unindex(item)
    self.serial = self.serial + 1
    self.known[item] = { source = source, order = self.serial, at = now }
    if self:sourceallowed(source) then self:enqueue(item, now + .25) end
end
function Items:sourceallowed(source)
    return (source == "world" and self.config.items.stack_world)
        or (source == "manual" and self.config.items.stack_manual)
        or (source == "loaded" and self.config.items.stack_loaded)
        or (source == "world" and self.config.items.pickup_allowed)
end
function Items:enqueue(item, at)
    if self.queued[item] then return end
    if self.tail - self.head + 1 >= 2048 then self.dropped = self.dropped + 1; return end
    self.tail = self.tail + 1; self.pending[self.tail] = { item = item, at = at }
    self.queued[item] = true
end
function Items:reserve(player, item, now)
    self.reservations[player] = item and { item = item, until_time = now + 7 } or nil
end
function Items:reserved(item, now)
    for player, reservation in pairs(self.reservations) do
        if not U.valid(player) or now >= reservation.until_time then self.reservations[player] = nil
        elseif reservation.item == item then return true end
    end
    return false
end
function Items:eligible(item, now)
    if not U.valid(item) or not item.Transform then return false end
    local record, c = self.known[item], item.components
    if not record or not self:sourceallowed(record.source) or not c or not c.stackable or not c.inventoryitem then return false end
    if c.inventoryitem.owner or c.inventoryitem.canbepickedup == false or c.inventoryitem.is_landed == false
        or item:HasTag("INLIMBO") or item:HasTag("heavy") or item:HasTag("smallcreature")
        or c.health or c.projectile or c.complexprojectile or item:HasTag("projectile")
        or item:HasTag("falling") or item:HasTag("small_livestock") or item:HasTag("no_autostack_all")
        or item:HasTag("penguin_egg") or c.locomotor or c.trap or (c.bait and c.bait.trap)
        or self:reserved(item, now) then return false end
    local _, y = item.Transform:GetWorldPosition()
    if math.abs(y) > .05 then return false end
    if item.Physics then
        local vx, vy, vz = item.Physics:GetVelocity()
        if vx * vx + vy * vy + vz * vz > .04 then return false end
    end
    return true
end
function Items:process(item, now)
    if not self:eligible(item, now) then
        if U.valid(item) and self.known[item] and now - self.known[item].at < 30 then self:enqueue(item, now + .25) end
        return
    end
    local cfg, c = self.config, item.components
    if cfg.items.pickup_allowed and self.known[item].source == "world" then
        local players = {}
        for _, player in ipairs(self.env.players()) do
            local inv = player.components.inventory
            if U.valid(player) and inv and self.env.pickup(player) and not player:HasTag("playerghost")
                and U.sameplatform(player, item) and U.distance(player, item) <= cfg.items.radius^2
                and (not cfg.items.pickup_existing or inv:Has(item.prefab, 1, true))
                and inv:CanAcceptCount(item, c.stackable:StackSize()) > 0 then players[#players + 1] = player end
        end
        table.sort(players, function(a, b)
            local ad, bd = U.distance(a, item), U.distance(b, item)
            if ad == bd then return tostring(a.userid) < tostring(b.userid) end
            return ad < bd
        end)
        local player = players[1]
        if player then
            local before = c.stackable:StackSize()
            local inventory = player.components.inventory
            local accepted = math.min(before, inventory:CanAcceptCount(item, before))
            -- GiveItem 会把溢出放到鼠标上，因此先按容量调用原版 Get 拆分。
            -- Get 负责复制湿度、保鲜、皮肤等属性；余量原实体留在原地，不自行删除重建。
            if accepted <= 0 then return end
            local transfer = accepted < before and c.stackable:Get(accepted) or item
            inventory:GiveItem(transfer, nil, item:GetPosition())
            if transfer ~= item and U.valid(transfer) and not transfer.components.inventoryitem.owner then
                -- 若其它组件在入包回调中拒收，使用同一原版合堆语义归还未接收的部分。
                c.stackable:Put(transfer)
            end
            if not U.valid(item) or c.inventoryitem.owner then
                self.env.result(item, "picked", nil); return
            elseif c.stackable:StackSize() < before then self.env.result(item, "partial", item) end
        end
    end
    if not self:eligible(item, now) then return end
    local source = self.known[item].source
    if not ((source == "world" and cfg.items.stack_world) or (source == "manual" and cfg.items.stack_manual)
        or (source == "loaded" and cfg.items.stack_loaded)) then return end
    local neighbors = self:neighbors(item)
    table.sort(neighbors, function(a, b)
        return (self.known[a] and self.known[a].order or math.huge) < (self.known[b] and self.known[b].order or math.huge)
    end)
    for _, target in ipairs(neighbors) do
        if target ~= item and self:eligible(target, now) and self.known[target].order < self.known[item].order
            and U.sameplatform(item, target) and item.prefab == target.prefab then
            -- 原版 Put 校验皮肤、自定义可堆叠规则，并转移保鲜、湿度与余量，不删除再重建。
            target.components.stackable:Put(item)
            if U.call(target.components.stackable, "IsFull") then self:unindex(target) end
            if not U.valid(item) then self:forget(item); self.env.result(item, "merged", target); return end
        end
    end
    if self:eligible(item, now) then self:indexitem(item) end
end
function Items:tick(now)
    local stop = math.min(self.tail, self.head + self.config.items.budget - 1)
    local started = self.env.clock and self.env.clock()
    while self.head <= stop do
        -- 数量和 CPU 双预算；保留候选等待后续 tick，不靠丢弃任务换取耗时下降。
        if started and self.env.clock() - started >= .002 then break end
        local entry = self.pending[self.head]; self.pending[self.head] = nil; self.head = self.head + 1
        self.queued[entry.item] = nil
        if now >= entry.at then self:process(entry.item, now); self.processed = self.processed + 1
        else self:enqueue(entry.item, entry.at) end
    end
    if self.head > self.tail then self.head, self.tail, self.pending = 1, 0, {} end
end
function Items:close() self.pending, self.queued, self.known, self.reservations, self.index = {}, {}, {}, {}, {} end
return Items
