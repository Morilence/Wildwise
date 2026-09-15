-- 协调层回归：真实模块贯通协议、缓存和状态边界；引擎对象使用隔离替身。
local H = require("tests/harness")
local Config = require("wildwise/core/config")
local Protocol = require("wildwise/core/protocol")
local Observer = require("wildwise/services/observer")
local Facts = require("wildwise/services/facts")
local Queue = require("wildwise/services/queue")
local Planner = require("wildwise/services/planner")
local Items = require("wildwise/services/items")
local Index = require("wildwise/core/ordered_index")
local Sync = require("wildwise/services/map_sync")
local Map = require("wildwise/services/map")
local json = require("cjson")
package.loaded.json = json
local Client = require("wildwise/runtime/client")

local function receiver()
    return setmetatable({
        session = "s",
        received = 0,
        subscribed = {},
        cache = require("wildwise/core/lru").new(256),
        map = { players = {}, pairs = {}, pings = {}, fires = {} },
    }, Client)
end

H.test("OPT-01 same viewer mask changes replace complete snapshots", function()
    local player, target, c, seq = H.entity(1), H.entity(2), receiver(), 0
    c.subscribed[target] = true
    target.components.health = { currenthealth = 100, maxhealth = 100 }
    target.components.combat = { defaultdamage = 20 }
    local obs = Observer.new({ G = {}, config = Config.copy(Config.defaults) }, function(_, e, kind, data)
        seq = seq + 1
        c:receive(e, assert(Protocol.encode(json, kind, "s", seq, data)))
        return true
    end)
    for i, mask in ipairs({ "health", "hover", "health", "hover" }) do
        obs:subscribe(player, target, mask, i / 10)
        obs:tick(i / 10)
        H.eq(c.cache:peek(target).health, 100)
        H.eq(c.cache:peek(target).health_max, 100)
        H.eq(c.cache:peek(target).damage, mask == "hover" and 20 or nil)
    end
    obs:close()
end)

H.test("OPT-02 idle health subscriptions skip field work but retry failed sends", function()
    local player, target, filters, sends = H.entity(1), H.entity(2), 0, 0
    local original = Facts.filter
    Facts.filter = function(...)
        filters = filters + 1
        return original(...)
    end
    local obs = Observer.new({ G = {}, config = Config.copy(Config.defaults) }, function()
        sends = sends + 1
        return sends ~= 2
    end)
    target.components.health = { currenthealth = 100, maxhealth = 100 }
    obs:subscribe(player, target, "health", 0)
    obs:tick(0)
    for i = 1, 4 do
        obs:tick(i / 10)
    end
    local idle_filters = filters
    target.components.health.currenthealth = 50
    target:PushEvent("healthdelta")
    obs:tick(0.41)
    obs:tick(0.42)
    Facts.filter = original
    obs:close()
    H.eq(idle_filters, 1)
    H.eq(sends, 3)
end)

H.test("OPT-18 failed transient health changes return to idle after reverting", function()
    local player, target, filters, sends = H.entity(1), H.entity(2), 0, 0
    local original = Facts.filter
    Facts.filter = function(...)
        filters = filters + 1
        return original(...)
    end
    local obs = Observer.new({ G = {}, config = Config.copy(Config.defaults) }, function()
        sends = sends + 1
        return sends == 1
    end)
    target.components.health = { currenthealth = 100, maxhealth = 100 }
    obs:subscribe(player, target, "health", 0)
    obs:tick(0)
    target.components.health.currenthealth = 50
    target:PushEvent("healthdelta")
    obs:tick(0.1)
    target.components.health.currenthealth = 100
    target:PushEvent("healthdelta")
    obs:tick(0.2)
    obs:tick(0.3)
    obs:tick(0.4)
    Facts.filter = original
    obs:close()
    H.eq(sends, 2)
    H.eq(filters, 3)
end)

H.test("OPT-03 task completion starts an independent waiting window", function()
    local now = 0
    local q = Queue.new({
        ready = function()
            return true
        end,
        progress = function()
            return 0
        end,
        release = function() end,
        cancel = function() end,
        submit = function()
            error("must wait")
        end,
        validate = function(task)
            return task.id == 1 and now >= 4.9 and "done" or "wait"
        end,
    })
    q:add({ id = 1 })
    q:add({ id = 2 })
    q:tick(0)
    now = 4.9
    q:tick(now)
    q:tick(5)
    H.eq(q.tasks[1].id, 2)
    H.eq(q.state, "running")
    q:tick(9.9)
    H.eq(q.state, "running")
    q:tick(10)
    H.eq(q.state, "paused")
end)

H.test("OPT-04 nearest planning filters before ranking and reads each position once", function()
    local targets, reads = {}, 0
    for i = 1, 5000 do
        local x = i
        local target = H.entity(i)
        target.Transform.GetWorldPosition = function()
            reads = reads + 1
            return x, 0, 0
        end
        targets[i] = target
    end
    local out = Planner.nearest(targets, { x = 0, z = 0 }, 25, function(target)
        return target.GUID % 2 == 0
    end)
    H.eq(#out, 25)
    H.eq(reads, 2500)
    for i, target in ipairs(out) do
        H.eq(target.GUID, i * 2)
    end
    H.eq(#Planner.nearest(targets, { x = 0, z = 0 }, 0), 0)
end)

H.test("OPT-05 bounded selection keeps nearest candidates in adversarial input order", function()
    local targets = {}
    for i = 1000, 1, -1 do
        targets[#targets + 1] = H.entity(i, i, 0)
    end
    local out = Planner.nearest(targets, { x = 0, z = 0 }, 200)
    H.eq(#out, 200)
    for i, target in ipairs(out) do
        H.eq(target.GUID, i)
    end
end)

H.test("OPT-06 ordered index survives deletion and reinsertion during cursor traversal", function()
    local index, reference = Index.new(), {}
    for i = 1, 997 do
        local key = (i * 37) % 997
        index:set(key, key)
        reference[key] = true
    end
    for key = 0, 996, 2 do
        index:remove(key)
        reference[key] = nil
    end
    for key = 0, 996, 10 do
        index:set(key, key)
        reference[key] = true
    end
    local cursor = -1
    for key = 0, 996 do
        if reference[key] then
            local value, next_key = index:after(cursor)
            H.eq(next_key, key)
            H.eq(value, key)
            index:remove(key)
            cursor = key
        end
    end
    H.eq(index.root, nil)
end)

H.test("OPT-07 incompatible stacks yield with bounded work and eventually reach an older valid stack", function()
    local attempts = 0
    local service = Items.new(Config.copy(Config.defaults), {
        players = function()
            return {}
        end,
        result = function() end,
    })
    local final
    for i = 1, 1000 do
        local item = H.item(i, 0, 1)
        item.prefab = "flint"
        service.serial = i
        service.known[item] = { source = "world", order = i, at = 0 }
        if i < 1000 then
            item.components.stackable.Put = function()
                attempts = attempts + 1
            end
        else
            final = item
        end
        service:indexitem(item)
    end
    local incoming = H.item(1001, 0, 3)
    incoming.prefab = "flint"
    service:mark(incoming, "world", 0)
    service:tick(1)
    assert(attempts <= 64 and incoming.valid)
    for i = 2, 30 do
        service:tick(i)
    end
    H.eq(incoming.valid, false)
    H.eq(final.components.stackable:StackSize(), 4)
    H.eq(attempts, 999)
    service:close()
end)

H.test("OPT-08 prepared payloads preserve escaping and envelope limits", function()
    local packet = assert(Protocol.prepare(json, "map", { players = { { name = '引号"\\\n', x = 5 } } }))
    local bytes = assert(Protocol.wrap(json, packet, "s", 3))
    local message = assert(Protocol.decode(json, bytes))
    H.eq(message.data.players[1].name, '引号"\\\n')
    assert(#bytes <= packet.max_bytes)
    H.eq(Protocol.prepare(json, "map", { players = { string.rep("x", 4097) } }), nil)
end)

local function sync_fixture()
    local clients, sequence, sent = {}, 0, {}
    local sync = Sync.new(json, function(player, packet)
        sequence = sequence + 1
        sent[#sent + 1] = { player = player, packet = packet }
        clients[player]:receive(nil, assert(Protocol.wrap(json, packet, "s", sequence)))
        return true
    end, function()
        return 0
    end)
    return sync, clients, sent
end

H.test("OPT-09 interleaved map channels preserve the old pairs until completion", function()
    local sync, clients = sync_fixture()
    clients.p = receiver()
    clients.p.map.pairs = { { id = -1 } }
    local pairs_ = {}
    for i = 1, 240 do
        pairs_[i] = { id = i }
    end
    sync:watch("p", "pairs", sync:publish("shared", "pairs", 1, pairs_))
    sync:watch("p", "players", sync:publish_rows("players", "players", { { userid = "p", x = 0 } }))
    sync:tick()
    H.eq(clients.p.map.pairs[1].id, -1)
    sync:watch("p", "players", sync:publish_rows("players", "players", { { userid = "p", x = 1 } }))
    for _ = 1, 20 do
        sync:tick()
    end
    H.eq(#clients.p.map.pairs, 240)
    H.eq(clients.p.map.players[1].x, 1)
end)

H.test("OPT-10 movement only resends positions after static map synchronization", function()
    local sync, clients, sent = sync_fixture()
    local entries = {}
    for i = 1, 200 do
        entries[i] = { id = i }
    end
    local pairs_job = sync:publish("shared", "pairs", 1, entries)
    local positions = sync:publish_rows("players", "players", { { userid = "p", x = 0 } })
    for i = 1, 6 do
        clients[i] = receiver()
        sync:watch(i, "pairs", pairs_job)
        sync:watch(i, "players", positions)
    end
    for _ = 1, 100 do
        local messages, bytes = sync:tick()
        assert(messages <= 8 and bytes <= 24000)
    end
    local before = #sent
    local updated = sync:publish_rows("players", "players", { { userid = "p", x = 1 } })
    for i = 1, 6 do
        sync:watch(i, "players", updated)
    end
    for _ = 1, 10 do
        sync:tick()
    end
    H.eq(#sent - before, 6)
    for i = 1, 6 do
        H.eq(#clients[i].map.pairs, 200)
        H.eq(clients[i].map.players[1].x, 1)
    end
    H.eq(sync:publish_rows("players", "players", { { userid = "p", x = 1 } }), updated)
end)

H.test("OPT-11 map stream retries failed sends and releases departed audiences", function()
    local fail, deliveries = true, 0
    local sync = Sync.new(json, function()
        if fail then
            return false
        end
        deliveries = deliveries + 1
        return true
    end, function()
        return 0
    end)
    sync:watch("p", "players", sync:publish_rows("players", "players", {}))
    sync:tick()
    H.eq(deliveries, 0)
    fail = false
    sync:tick()
    H.eq(deliveries, 1)
    sync:remove("p")
    sync:tick()
    H.eq(next(sync.jobs), nil)
    H.eq(next(sync.players), nil)
end)

H.test("OPT-12 pair visibility caches preserve snapshots across permission and discovery changes", function()
    local map = Map.new("1")
    local function end_(id)
        return { key = id, prefab = "wormhole", x = 0, z = 0 }
    end
    map:discover("a", end_("a"), end_("b"), false)
    local old = map:visible_pairs("a", false)
    H.eq(old[1].shared, false)
    map:discover("a", end_("a"), end_("b"), true)
    H.eq(old[1].shared, false)
    local visible = map:visible_pairs("b", true)
    H.eq(#visible, 1)
    H.eq(#map:visible_pairs("b", false), 0)
    H.eq(#map:visible_pairs("b", true), 1)
    map:remove_pair(1)
    H.eq(next(map.discoveries.a), nil)
end)

H.test("OPT-16 revoked map audience cancels an incomplete shared channel", function()
    local sync, clients = sync_fixture()
    clients.p = receiver()
    local entries = {}
    for i = 1, 240 do
        entries[i] = { id = i }
    end
    sync:watch("p", "pairs", sync:publish("shared", "pairs", 1, entries))
    sync:tick()
    assert(clients.p.map_pending and clients.p.map_pending.pairs)
    sync:watch("p", "pairs", sync:publish("private", "pairs", 1, {}))
    for _ = 1, 20 do
        sync:tick()
    end
    H.eq(#clients.p.map.pairs, 0)
    H.eq(clients.p.map_pending.pairs, nil)
end)

H.test("OPT-17 map fragments split by actual byte budget and commit together", function()
    local sync, clients = sync_fixture()
    clients.p = receiver()
    local entries = {}
    for i = 1, 24 do
        entries[i] = { id = i, text = string.rep("a", 3000) }
    end
    sync:watch("p", "pairs", sync:publish("large", "pairs", 1, entries))
    for _ = 1, 60 do
        local messages, bytes = sync:tick()
        assert(messages <= 8 and bytes <= 24000)
    end
    H.eq(#clients.p.map.pairs, 24)
    H.eq(#clients.p.map.pairs[24].text, 3000)
end)

local Context = require("wildwise/runtime/context")
local previous_g, previous_config, previous_cooking = Context.G, Context.config, package.loaded.cooking
local time, transmissions = 0, {}
local G = {
    Class = function(ctor)
        local cls = {}
        cls.__index = cls
        return setmetatable(cls, {
            __call = function(_, ...)
                local obj = setmetatable({}, cls)
                ctor(obj, ...)
                return obj
            end,
        })
    end,
    GetTime = function()
        return time
    end,
    TheShard = {
        GetShardId = function()
            return "1"
        end,
    },
    TheNet = {
        GetServerGameMode = function()
            return "survival"
        end,
        GetPVPEnabled = function()
            return false
        end,
    },
    AllPlayers = {},
    GetClientModRPC = function()
        return {}
    end,
    SendModRPCToClient = function(_, player, _, bytes)
        transmissions[#transmissions + 1] = { player = player, msg = assert(Protocol.decode(json, bytes)) }
    end,
    GetShardModRPC = function()
        return {}
    end,
    SendModRPCToShard = function() end,
    ACTIONS = { PICKUP = {} },
}
Context.G, Context.config = G, Config.copy(Config.defaults)
Context.config.items.enabled = false
package.loaded.cooking = { ingredients = {}, recipes = {} }
local World = require("components/wildwise_world")

local function world_fixture()
    local inst, player = H.entity(1), H.entity(2)
    player.userid = "review"
    inst.DoPeriodicTask = function()
        return { Cancel = function() end }
    end
    G.AllPlayers = { player }
    local world = World(inst)
    world:AddPlayer(player)
    return world, player, world.players[player]
end

H.test("OPT-13 world request rejects malformed entity parameters and empty unsubscribe", function()
    local world, player, state = world_fixture()
    for i, target in ipairs({ 42, true, "entity", { IsValid = true } }) do
        world:Request(player, target, assert(Protocol.encode(json, "subscribe", state.session, i, { mask = "health" })))
    end
    assert(world.observer:subscribe(player, H.entity(3), "health", 0))
    world:Request(player, nil, assert(Protocol.encode(json, "unsubscribe", state.session, 10, {})))
    world:OnRemoveFromEntity()
end)

H.test("OPT-14 new nonce rotates session and resets map while duplicate hello is idempotent", function()
    local world, player, state = world_fixture()
    local function hello(nonce)
        world:Request(player, nil, assert(Protocol.encode(json, "hello", "hello", 1, { nonce = nonce })))
    end
    hello("first")
    local first = state.session
    state.seq = 20
    hello("first")
    H.eq(state.session, first)
    H.eq(state.seq, 20)
    world:MapUpdate(time)
    for _ = 1, 5 do
        world.map_sync:tick()
    end
    hello("second")
    assert(state.session ~= first)
    local current = state.session
    hello("first")
    H.eq(state.session, current)
    state.action = { token = "new" }
    world:Request(player, nil, assert(Protocol.encode(json, "release", first, 21, {})))
    H.eq(state.action.token, "new")
    local before = #transmissions
    world:MapUpdate(time)
    for _ = 1, 5 do
        world.map_sync:tick()
    end
    assert(#transmissions > before)
    world:OnRemoveFromEntity()
end)

H.test("OPT-15 delayed native result from an old client cannot complete a new task", function()
    local world, player, state = world_fixture()
    local target, callback = H.entity(3), nil
    world:Request(
        player,
        target,
        assert(Protocol.encode(json, "watch_action", state.session, 1, { token = "0:1", action = "PICKUP" }))
    )
    player:PushEvent("performaction", {
        action = {
            action = { id = "PICKUP" },
            target = target,
            AddSuccessAction = function(_, fn)
                callback = fn
            end,
            AddFailAction = function() end,
        },
    })
    assert(callback)
    world:Request(player, nil, assert(Protocol.encode(json, "hello", "hello", 1, { nonce = "new" })))
    local before = #transmissions
    callback()
    H.eq(#transmissions, before)
    world:OnRemoveFromEntity()
end)

Context.G, Context.config, package.loaded.cooking = previous_g, previous_config, previous_cooking
package.loaded["components/wildwise_world"] = nil
