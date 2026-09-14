local Context = require("wildwise/runtime/context")
local U = require("wildwise/core/util")
local Protocol = require("wildwise/core/protocol")
local Lifetime = require("wildwise/core/lifetime")
local Config = require("wildwise/core/config")
local Health = require("wildwise/services/health")
local Observer = require("wildwise/services/observer")
local Items = require("wildwise/services/items")
local Map = require("wildwise/services/map")
local json = require("json")
local G = Context.G
local World = G.Class(function(self, inst)
    self.inst, self.config, self.scope = inst, Context.config, Lifetime.new()
    self.players, self.remote, self.send_sequence, self.session_sequence = {}, {}, 0, 0
    self.portals, self.fires = {}, {}
    self.boot = tostring(os.time())
    self.map = Map.new(G.TheShard and G.TheShard:GetShardId() or "1")
    self.observer = Observer.new({ G = G, config = self.config, cooking = require("cooking"), now = G.GetTime() },
        function(player, target, kind, data) self:Send(player, target, kind, data) end)
    if self.config.items.enabled then
        self.items = Items.new(self.config, {
            players = function() return G.AllPlayers end,
            pickup = function(player) return self.players[player] and self.players[player].pickup end,
            clock = os.clock,
            result = function(old, result, target)
                for player in pairs(self.players) do
                    if U.valid(player) and U.valid(old) then
                        G.SendModRPCToClient(G.GetClientModRPC("wildwise", "redirect"), player.userid, old, target, result)
                    end
                end
            end,
        })
    end
    self.next_map, self.next_threat, self.next_shard = 0, 0, 0
    self.scope:task(inst:DoPeriodicTask(.1, function() self:Tick() end))
    self.scope:listen(inst, "onremove", function() self:OnRemoveFromEntity() end)
end)

function World:Send(player, target, kind, data)
    local state = self.players[player]
    if not state or not U.valid(player) then return end
    self.send_sequence = self.send_sequence + 1
    local bytes = Protocol.encode(json, kind, state.session, self.send_sequence, data)
    if bytes then
        if Context.client and Context.client.player == player then Context.client:receive(target, bytes)
        else G.SendModRPCToClient(G.GetClientModRPC("wildwise", "message"), player.userid, target, bytes) end
        state.bytes = state.bytes + #bytes
    end
end

function World:SendMap(player, state, data)
    if #json.encode(data) < 9000 then self:Send(player, nil, "map", data); return end
    -- 配对/标记较多时按原子记录分片；客户端收到完整版本才切换，防止半张地图闪烁。
    state.map_revision = (state.map_revision or 0) + 1
    local revision = state.map_revision
    self:Send(player, nil, "map_begin", { revision = revision })
    for _, key in ipairs({ "players", "pings", "pairs", "fires" }) do
        for first = 1, #data[key], 12 do
            local entries = {}
            for i = first, math.min(first + 11, #data[key]) do entries[#entries + 1] = data[key][i] end
            self:Send(player, nil, "map_chunk", { revision = revision, key = key, entries = entries })
        end
    end
    self:Send(player, nil, "map_end", { revision = revision })
end

function World:AddPlayer(player)
    if self.players[player] or not player.userid then return end
    self.session_sequence = self.session_sequence + 1
    local scope = Lifetime.new()
    local state = { session = self.map.worldid .. ":" .. self.boot .. ":" .. self.session_sequence .. ":" .. tostring(G.GetTime()),
        scope = scope, limiter = Protocol.bucket(20, 40, G.GetTime()), seq = 0, pickup = false,
        threats = {}, explore_cursor = 0, next_explore = 0, bytes = 0 }
    self.players[player] = state
    scope:listen(player, "onremove", function() self:RemovePlayer(player) end)
    -- performaction 先于 BufferedAction:Do；在此挂原生成功/失败回调，可区分动画开始与实际成功。
    scope:listen(player, "performaction", function(_, data)
        local watch, action = state.action, data and data.action
        if not watch or not action or G.GetTime() > watch.expires then return end
        if action.action.id ~= watch.action or action.target ~= watch.target then return end
        state.action = nil
        action:AddSuccessAction(function()
            self:Send(player, nil, "action_result", { token = watch.token, result = "success" })
        end)
        action:AddFailAction(function()
            self:Send(player, nil, "action_result", { token = watch.token, result = "failed" })
        end)
    end)
    scope:listen(player, "actionfailed", function()
        if state.action then
            self:Send(player, nil, "action_result", { token = state.action.token, result = "failed" }); state.action = nil
        end
    end)
    scope:listen(player, "builditem", function()
        if state.action and state.action.action == "BUILD" then
            self:Send(player, nil, "action_result", { token = state.action.token, result = "success" }); state.action = nil
        end
    end)
    for _, event in ipairs({ "attacked", "death", "ms_becameghost", "ms_playerdespawnandmigrate" }) do
        scope:listen(player, event, function()
            state.action = nil
            if self.items then self.items:reserve(player, nil, G.GetTime()) end
            self:Send(player, nil, "cancel", { reason = event })
        end)
    end
end
function World:RemovePlayer(player)
    local state = self.players[player]
    if not state then return end
    state.scope:close(); self.observer:forget(player)
    if self.items then self.items:reserve(player, nil, G.GetTime()) end
    self.players[player] = nil
end

local masks = { health = true, hover = true, beefalo = true, menu = true }
function World:Request(player, target, bytes)
    if not U.valid(player) or not player.userid then return end
    self:AddPlayer(player)
    local state, now = self.players[player], G.GetTime()
    -- 先限流、检查长度和协议，再接触实体/存档；客户端传来的值都不是权威事实。
    if not Protocol.allow(state.limiter, now) then return end
    local msg = Protocol.decode(json, bytes)
    if not msg then return end
    local data = msg.data
    if msg.kind == "hello" then
        if type(data.nonce) ~= "string" or #data.nonce > 64 then return end
        state.seq = 0; state.active_until = now + 10
        self:Send(player, nil, "welcome", { nonce = data.nonce, config = self.config, conflicts = Context.conflicts,
            shard = self.map.worldid, preferences = self.map:preferences_for(player.userid) })
        return
    end
    if msg.session ~= state.session or msg.seq <= state.seq then return end
    state.seq, state.active_until = msg.seq, now + 10
    if msg.kind == "subscribe" and masks[data.mask] then
        if ((data.mask == "hover" or data.mask == "menu") and not self.config.info.enabled)
            or (data.mask == "beefalo" and not self.config.beefalo.enabled)
            or (data.mask == "health" and not self.config.healthbars.enabled and not self.config.info.enabled) then return end
        self.observer:subscribe(player, target, data.mask, now)
    elseif msg.kind == "unsubscribe" then self.observer:unsubscribe(player, target)
    elseif msg.kind == "heartbeat" then
        self:Send(player, nil, "heartbeat", { server_time = now, bytes = state.bytes, observations = U.count(self.observer.entities) })
    elseif msg.kind == "preference" then
        if data.key == "items.pickup" then state.pickup = self.config.items.pickup_allowed and data.value == true
        elseif data.key == "healthbars.enabled" then state.healthbars = data.value == true
        elseif data.key == "healthbars.hostile_scope" and ({ self = true, followers = true, nearby = true, nearby_followers = true })[data.value] then
            state.hostile_scope = data.value
        elseif data.key == "map.share_position" or data.key == "map.share_exploration" then
            local preference = data.key == "map.share_position" and "position" or "exploration"
            self.map:set_preference(player.userid, preference, data.value)
        end
    elseif msg.kind == "ping" and self.config.map.enabled then
        local x, z = data.x, data.z
        -- 只允许已探索地点，不接受 prefab、任意实体生成或其它世界坐标。
        if U.finite(x) and U.finite(z) and player.CanSeePointOnMiniMap and player:CanSeePointOnMiniMap(x, 0, z) then
            local _, reason = self.map:add_ping(player.userid, data.kind, x, z, now)
            if reason then self:Send(player, nil, "notice", { reason = reason }) end
        end
    elseif msg.kind == "delete_ping" then
        local client = G.TheNet:GetClientTableForUser(player.userid)
        self.map:delete_ping(player.userid, data.id, client and client.admin)
    elseif msg.kind == "recipes" and self.config.info.enabled then
        local results, reason = require("wildwise/services/recipes").query(require("cooking"),
            data.cooker == "portablecookpot" and "portablecookpot" or "cookpot", data.ingredients)
        self:Send(player, nil, "recipes", { results = results or {}, reason = reason or "" })
    elseif msg.kind == "find" and self.config.info.enabled and self.config.info.container_contents then
        if type(data.prefab) ~= "string" or #data.prefab > 80 then return end
        local x, y, z = player.Transform:GetWorldPosition()
        local candidates = G.TheSim:FindEntities(x, y, z, self.config.observation.radius, nil, { "INLIMBO", "FX" })
        local count = 0
        for _, candidate in ipairs(candidates) do
            local container = candidate.components.container
            local match = candidate.prefab == data.prefab
            if not match and container and container.canbeopened ~= false then
                match = container:FindItem(function(item) return item.prefab == data.prefab end) ~= nil
            end
            if match and candidate.entity:IsVisible() and (not G.CanEntitySeeTarget or G.CanEntitySeeTarget(player, candidate)) then
                self:Send(player, candidate, "found", {}); count = count + 1
                if count >= 40 then break end
            end
        end
    elseif msg.kind == "watch_action" and self.config.queue.enabled then
        if type(data.token) ~= "string" or #data.token > 48 or not G.ACTIONS[data.action] then return end
        if target and (not U.valid(target) or not target.Transform or U.distance(player, target) > 80^2) then return end
        state.action = { token = data.token, action = data.action, target = target, expires = now + 7 }
        if self.items and data.action == "PICKUP" then self.items:reserve(player, target, now) end
    elseif msg.kind == "release" then
        state.action = nil; if self.items then self.items:reserve(player, nil, now) end
    end
end

function World:Threats(player, state, now)
    if not self.config.healthbars.enabled or state.healthbars == false then return end
    local x, y, z = player.Transform:GetWorldPosition()
    local nearby = G.TheSim:FindEntities(x, y, z, self.config.observation.radius, { "_combat", "_health" }, { "INLIMBO", "FX" })
    local alive = {}
    for _, target in ipairs(nearby) do
        local hostile, direct = Health.hostility(target, player, state.hostile_scope or self.config.healthbars.hostile_scope, G.AllPlayers, 30)
        if hostile then
            alive[target] = true
            local previous = state.threats[target]
            if not previous or previous.direct ~= direct or now - previous.sent > 1 then
                self:Send(player, target, "threat", { hostile = true, direct = direct == true })
                state.threats[target] = { direct = direct, sent = now }
            end
        end
    end
    for target in pairs(state.threats) do
        if not alive[target] then
            self:Send(player, target, "threat", { hostile = false, direct = false }); state.threats[target] = nil
        end
    end
end

function World:MapUpdate(now)
    if not self.config.map.enabled or self.map.load_error then return end
    self.map:expire(now)
    local positions, exploration = Config.share(self.config, G.TheNet:GetServerGameMode(), G.TheNet:GetPVPEnabled())
    local roster = {}
    for _, player in ipairs(G.AllPlayers) do
        if U.valid(player) and player.userid then
            local prefs = self.map:preferences_for(player.userid)
            if positions and prefs.position then
                local x, _, z = player.Transform:GetWorldPosition()
                roster[#roster + 1] = { userid = player.userid, name = player:GetDisplayName(), prefab = player.prefab,
                    x = math.floor(x * 4) / 4, z = math.floor(z * 4) / 4, shard = self.map.worldid }
            end
            local state = self.players[player]
            if exploration and prefs.exploration and state and now >= state.next_explore then
                state.next_explore = now + 1
                local x, _, z = player.Transform:GetWorldPosition()
                local cell = math.floor(x / 4) .. ":" .. math.floor(z / 4)
                if state.last_cell ~= cell and player.CanSeePointOnMiniMap and player:CanSeePointOnMiniMap(x, 0, z) then
                    state.last_cell = cell; self.map:record_exploration(x, z)
                end
            end
        end
    end
    table.sort(roster, function(a, b) return a.userid < b.userid end)
    for shard, remote in pairs(self.remote) do
        if now - remote.time > 20 then self.remote[shard] = nil else
            for _, record in ipairs(remote.players) do roster[#roster + 1] = record end
        end
    end
    local pings = {}; for _, ping in pairs(self.map.pings) do pings[#pings + 1] = ping end
    local fires = {}
    for fire in pairs(self.fires) do
        if not U.valid(fire) or not fire.components.fueled or fire.components.fueled:IsEmpty() then self.fires[fire] = nil
        else
            local x, _, z = fire.Transform:GetWorldPosition()
            fires[#fires + 1] = { x = x, z = z, prefab = fire.prefab }
        end
    end
    table.sort(pings, function(a, b) return a.id < b.id end)
    for player, state in pairs(self.players) do
        if state.active_until and now < state.active_until then
            local prefs = self.map:preferences_for(player.userid)
            local data = { players = roster, pings = pings, fires = fires, pairs = self.map:visible_pairs(player.userid, exploration and prefs.exploration) }
            local encoded = json.encode(data)
            if encoded ~= state.last_map then
                self:SendMap(player, state, data); state.last_map = encoded
            end
            -- 每次最多回放 8 个允许共享的点，加入时不会瞬间执行整张地图的恢复。
            if exploration and prefs.exploration and player.player_classified and player.player_classified.MapExplorer then
                local explorer = player.player_classified.MapExplorer
                local finish = math.min(#self.map.exploration, state.explore_cursor + 8)
                for i = state.explore_cursor + 1, finish do
                    local point = self.map.exploration[i]
                    explorer:RevealArea(point.x, 0, point.z)
                end
                state.explore_cursor = finish
            end
        end
    end
    if now >= self.next_shard and G.TheShard then
        self.next_shard = now + 5
        local remote_players = {}
        for _, record in ipairs(roster) do
            if record.shard == self.map.worldid then
                remote_players[#remote_players + 1] = { userid = record.userid, name = record.name, prefab = record.prefab, shard = self.map.worldid }
            end
        end
        -- 跨世界只发身份与所在世界；绝不把洞穴坐标画到地上地图。
        local payload = Protocol.encode(json, "presence", self.map.worldid, 0, { players = remote_players })
        if payload then G.SendModRPCToShard(G.GetShardModRPC("wildwise", "presence"), nil, payload) end
    end
end
function World:ShardPresence(shard, bytes)
    local msg = Protocol.decode(json, bytes)
    if not msg or msg.kind ~= "presence" or type(msg.data.players) ~= "table" or #msg.data.players > 64 then return end
    local players = {}
    for _, record in ipairs(msg.data.players) do
        if type(record.userid) == "string" and type(record.name) == "string" then
            players[#players + 1] = { userid = record.userid, name = record.name, prefab = record.prefab, shard = tostring(shard) }
        end
    end
    self.remote[tostring(shard)] = { players = players, time = G.GetTime() }
end
function World:DiscoverPair(player, a, b)
    if self.map.load_error then return end
    if not U.valid(a) or not U.valid(b) or not b.components.teleporter or b.components.teleporter.targetTeleporter ~= a then return end
    local function endpoint(e)
        local x, _, z = e.Transform:GetWorldPosition()
        return { key = Map.endpoint(e.prefab, x, z), prefab = e.prefab, x = x, z = z }
    end
    local _, share = Config.share(self.config, G.TheNet:GetServerGameMode(), G.TheNet:GetPVPEnabled())
    self.map:discover(player.userid, endpoint(a), endpoint(b), share and self.map:preferences_for(player.userid).exploration)
end
function World:RegisterPortal(entity)
    local x, _, z = entity.Transform:GetWorldPosition()
    self.portals[Map.endpoint(entity.prefab, x, z)] = entity
end
function World:ValidatePairs()
    if self.map.load_error then return end
    for id, pair in pairs(self.map.pairs) do
        local a, b = self.portals[pair.a.key], self.portals[pair.b.key]
        if not U.valid(a) or not U.valid(b) or not a.components.teleporter or not b.components.teleporter
            or a.components.teleporter.targetTeleporter ~= b or b.components.teleporter.targetTeleporter ~= a then self.map:remove_pair(id) end
    end
end
function World:Tick()
    local now = G.GetTime()
    self.observer:tick(now)
    if self.items then self.items:tick(now) end
    if now >= self.next_threat then
        self.next_threat = now + .25
        for player, state in pairs(self.players) do
            if U.valid(player) and state.active_until and now < state.active_until then self:Threats(player, state, now) end
        end
    end
    if now >= self.next_map then
        self.next_map = now + .25; self:MapUpdate(now)
        if self.config.map.enabled and now > 2 then self:ValidatePairs() end
    end
end
function World:OnSave() return self.map:save() end
function World:OnLoad(data)
    if not self.map:load(data) then print("[Wildwise] 无法迁移地图存档；已保留原数据，停止地图修改。") end
end
function World:OnRemoveFromEntity()
    self.scope:close(); self.observer:close()
    if self.items then self.items:close() end
    for player in pairs(self.players) do self:RemovePlayer(player) end
end
return World
