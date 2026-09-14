local H = require("tests/harness")
local U = require("wildwise/core/util")
local Config = require("wildwise/core/config")
local Health = require("wildwise/services/health")
local Items = require("wildwise/services/items")
local Map = require("wildwise/services/map")
local Queue = require("wildwise/services/queue")
local Planner = require("wildwise/services/planner")
local Observer = require("wildwise/services/observer")
local Recipes = require("wildwise/services/recipes")
local function config() return U.copy(Config.defaults) end
H.test("hostility follows actual targets and changed follower ownership", function()
    local viewer, friend, pet, enemy = H.entity(1), H.entity(2), H.entity(3), H.entity(4)
    enemy.components.combat = { target = pet }; pet.components.follower = { leader = viewer }
    H.eq(Health.hostility(enemy, viewer, "self", { viewer, friend }, 30), false)
    assert(Health.hostility(enemy, viewer, "followers", { viewer, friend }, 30))
    pet.components.follower.leader = friend
    H.eq(Health.hostility(enemy, viewer, "followers", { viewer, friend }, 30), false)
    assert(Health.hostility(enemy, viewer, "nearby_followers", { viewer, friend }, 30))
    H.eq(Health.hostility(enemy, viewer, "nearby", { viewer, friend }, 30), false)
end)
H.test("health bar priority limit visibility and exact linger", function()
    local a, b, c = H.entity(1), H.entity(2), H.entity(3)
    local states = {
        [a] = { visible = true, hostile = true, direct = true, order = 1, distance = 1 },
        [b] = { visible = true, hostile = true, direct = false, order = 2, distance = 4 },
        [c] = { visible = false, hostile = true, direct = true, order = 3, distance = 0 },
    }
    local out = Health.select(states, b, 1, 3, 2); H.eq(out[1], b)
    states[b].hostile, states[b].last_hostile = false, 1
    out = Health.select(states, b, 12, 3, 2); H.eq(#out, 1); H.eq(out[1], a)
end)
local function itemservice(cfg, candidates, players, pickup)
    return Items.new(cfg or config(), { players = function() return players or {} end,
        pickup = pickup or function() return false end, neighbors = function() return candidates end, result = function() end })
end
H.test("new drops merge into older eligible stacks", function()
    local a, b = H.item(1, 0, 5), H.item(2, 1, 7)
    local service = itemservice(nil, { b, a }); service:mark(a, "world", 0); service:mark(b, "world", 0)
    service:tick(1); H.eq(a.components.stackable.size, 12); H.eq(b.valid, false)
end)
H.test("manual loaded and unknown targets stay protected", function()
    for _, source in ipairs({ "manual", "loaded", "unknown" }) do
        local a, b = H.item(1, 0, 2), H.item(2, 1, 3); local service = itemservice(nil, { a, b })
        service:mark(a, source, 0); service:mark(b, "world", 0); service:tick(1)
        assert(a.valid and b.valid); H.eq(a.components.stackable.size, 2)
    end
end)
H.test("no merging across boat and shore", function()
    local a, b = H.item(1, 0), H.item(2, 1); a.platform = {}
    local service = itemservice(nil, { a, b }); service:mark(a, "world", 0); service:mark(b, "world", 0); service:tick(1)
    assert(a.valid and b.valid)
end)
H.test("landing and active queue reservation block pickup and merging", function()
    local a, b, player = H.item(1, 0), H.item(2, 1), H.entity(3)
    local service = itemservice(nil, { a, b }); service:mark(a, "world", 0); service:mark(b, "world", 0)
    b.components.inventoryitem.is_landed = false; service:tick(1); assert(b.valid)
    b.components.inventoryitem.is_landed = true; service:reserve(player, b, 1); service:tick(2); assert(b.valid)
    service:reserve(player, nil, 3); service:tick(4); H.eq(b.valid, false)
end)
H.test("partial stacks conserve count and skins", function()
    local a, b = H.item(1, 0, 38), H.item(2, 1, 5); local service = itemservice(nil, { a, b })
    service:mark(a, "world", 0); service:mark(b, "world", 0); service:tick(1)
    H.eq(a.components.stackable.size, 40); H.eq(b.components.stackable.size, 3)
    local d = H.item(3, 2, 4); d.skinname = "skin"; service:mark(d, "world", 1); service:tick(2); assert(d.valid)
end)
H.test("pickup selects nearest eligible receiver with stable userid tie", function()
    local cfg, item, chosen = config(), H.item(5, 0, 4), nil; cfg.pickup_allowed = true
    local a, b = H.entity(1, 1), H.entity(2, -1); a.userid, b.userid = "b", "a"
    for _, player in ipairs({ a, b }) do
        player.components.inventory = { Has = function() return true end, CanAcceptCount = function() return 4 end,
            GiveItem = function() chosen = player; item:Remove() end }
    end
    local service = itemservice(cfg, { item }, { a, b }, function() return true end)
    service:mark(item, "world", 0); service:tick(1); H.eq(chosen, b)
end)
H.test("item work budget and queue bound resist burst", function()
    local cfg = config(); cfg.item_budget = 16
    local service = itemservice(cfg, {})
    for i = 1, 3000 do service:mark(H.item(i, i * 10), "world", 0) end
    assert(service.tail <= 2049); assert(service.dropped > 0)
    service:tick(1); H.eq(service.processed, 16)
end)
H.test("marker validates type coordinates owner limit and expiry", function()
    local map = Map.new("1")
    H.eq(map:add_ping("a", "arbitrary_prefab", 0, 0, 0), nil)
    H.eq(map:add_ping("a", "location", 0 / 0, 0, 0), nil)
    local id = map:add_ping("a", "location", 0, 0, 0)
    H.eq(map:delete_ping("b", id, false), false)
    for _ = 1, 4 do assert(map:add_ping("a", "danger", 0, 0, 0)) end
    H.eq(map:add_ping("a", "danger", 0, 0, 0), nil)
    assert(map:add_ping("a", "danger", 0, 0, 60)); assert(map:delete_ping("b", 0, true))
end)
H.test("pair identity persists and reconnect does not shuffle numbers", function()
    local map = Map.new("1"); local a, b = { key = "a" }, { key = "b" }
    H.eq(map:discover("a", a, b, false), 1)
    local reloaded = Map.new("1"); assert(reloaded:load(map:save()))
    H.eq(reloaded:discover("a", b, a, false), 1); H.eq(#reloaded:visible_pairs("b", true), 0)
    reloaded:discover("a", a, b, true); H.eq(#reloaded:visible_pairs("b", true), 1)
end)
H.test("changed destination invalidates old pair and preserves monotonic ID", function()
    local map = Map.new("1"); map:discover("a", { key = "a" }, { key = "b" }, true)
    H.eq(map:discover("a", { key = "a" }, { key = "c" }, true), 2); H.eq(map.endpoints.b, nil)
end)
H.test("unsupported saves are preserved without silent reset", function()
    local map, original = Map.new("1"), { version = 99, mystery = "preserve" }
    H.eq(map:load(original), false); H.eq(map:save(), original)
end)
H.test("exploration records only supplied authorized points and deduplicates", function()
    local map = Map.new("1"); assert(map:record_exploration(1, 2)); H.eq(map:record_exploration(1, 2), false)
    map:set_preference("user", "exploration", false); H.eq(#map.exploration, 1)
end)
local function queue()
    local a = { submitted = 0, callbacks = {} }
    a.ready = function() return true end; a.validate = function() return "ready" end
    a.release = function() end; a.cancel = function() end; a.progress = function() return "same" end
    a.submit = function(_, token, cb) a.submitted = a.submitted + 1; a.callbacks[token] = cb end
    return Queue.new(a, 3), a
end
H.test("queue preserves order deduplicates and respects capacity", function()
    local q = queue(); assert(q:add({ key = "a" })); H.eq(q:add({ key = "a" }), false)
    q:add({ key = "b" }); q:add({ key = "c" }); H.eq(q:add({ key = "d" }), false)
    H.eq(q.tasks[1].key, "a"); H.eq(q.tasks[3].key, "c")
end)
H.test("one executor awaits one result and cancellation ignores stale callbacks", function()
    local q, a = queue(); q:add({ key = "a" }); q:tick(0); local token = q.inflight.token; q:tick(1)
    H.eq(a.submitted, 1); q:cancel(); a.callbacks[token]("done"); H.eq(q.done, 0); H.eq(q.state, "idle")
end)
H.test("no-progress retries once then skips", function()
    local q, a = queue(); q:add({ key = "a" }); q:tick(0); q:tick(5); q:tick(5.1); q:tick(10.1)
    H.eq(a.submitted, 2); H.eq(q.skipped, 1); H.eq(q.state, "idle")
end)
H.test("focus pause never resumes automatically", function()
    local q, a = queue(); q:add({}); a.ready = function() return false, "input_focus" end; q:tick(0)
    H.eq(q.state, "paused"); a.ready = function() return true end; q:tick(1); H.eq(a.submitted, 0)
    q:resume(); q:tick(2); H.eq(a.submitted, 1)
end)
H.test("destroyed targets are skipped and merged targets redirected", function()
    local q = queue(); local old, survivor = {}, {}; q:add({ target = old, key = old })
    q:redirect(old, "merged", survivor); H.eq(q.tasks[1].target, survivor)
    q:redirect(survivor, "picked", nil); H.eq(#q.tasks, 0)
end)
H.test("grid uses serpentine order bounds and reprojects moving platforms", function()
    local platform = H.entity(1); platform.entity = {
        WorldToLocalSpace = function(_, x, y, z) return x - 10, y, z end,
        LocalToWorldSpace = function(_, x, y, z) return x + 20, y, z end,
    }
    local points = assert(Planner.grid({ x = 10, z = 0 }, { x = 12, z = 2 }, 1, 9, function() return true end, platform))
    H.eq(#points, 9); H.eq(points[4].point.x, 12); H.eq(points[6].point.x, 10)
    H.eq(Planner.project(points[1]).x, 20)
    H.eq(Planner.grid({ x = 0, z = 0 }, { x = 20, z = 20 }, 1, 200, function() end), nil)
end)
H.test("observer shares facts but isolates viewer food effects and cleans up", function()
    local a, b, food, calls, sent = H.entity(1), H.entity(2), H.entity(3), 0, {}
    for _, player in ipairs({ a, b }) do
        player.components.health, player.components.hunger, player.components.sanity = {}, {}, {}
        player.components.eater = { PrefersToEat = function() return true end, DoFoodEffects = function() return true end,
            healthabsorption = 1, hungerabsorption = 1, sanityabsorption = 1 }
    end
    food.components.edible = { healthvalue = 1, sanityvalue = 1, foodtype = "VEGGIE",
        GetHealth = function(_, player) return player.GUID end, GetHunger = function() return 10 end, GetSanity = function() return 2 end }
    food.components.health = { currenthealth = 10, maxhealth = 10, GetMaxWithPenalty = function() calls = calls + 1; return 10 end }
    local obs = Observer.new({ G = { TheWorld = { state = {} } }, config = config() }, function(p, _, kind, data) sent[p] = { kind = kind, data = data } end)
    obs:subscribe(a, food, "hover", 0); obs:subscribe(b, food, "hover", 0); obs:tick(0)
    H.eq(sent[a].data.fields.food_health, 1); H.eq(sent[b].data.fields.food_health, 2); H.eq(calls, 1)
    obs:forget(a); assert(obs.entities[food]); obs:forget(b); H.eq(next(obs.entities), nil)
    H.eq(next(food.events.healthdelta), nil)
end)
H.test("observer rejects distance limit and expires abandoned subscriptions", function()
    local a, far, close = H.entity(1), H.entity(2, 100), H.entity(3, 1)
    local obs = Observer.new({ G = { TheWorld = { state = {} } }, config = config() }, function() end)
    H.eq(obs:subscribe(a, far, "hover", 0), false); assert(obs:subscribe(a, close, "health", 0))
    obs:tick(7); H.eq(next(obs.entities), nil)
end)
H.test("cooking returns all highest priority candidates without random choice", function()
    local cooking = { ingredients = { berries = { tags = { fruit = 1 } } }, recipes = { cookpot = {
        a = { priority = 1, test = function(_, names) return names.berries == 4 end },
        b = { priority = 1, test = function(_, _, tags) return tags.fruit == 4 end },
        c = { priority = 0, test = function() return true end },
    } } }
    local result = Recipes.query(cooking, "cookpot", { "berries", "berries", "berries", "berries" })
    H.eq(#result, 2); H.eq(result[1].name, "a"); H.eq(result[2].name, "b")
end)
H.test("idle cancellation and repeated pause do not send extra movement", function()
    local q, a = queue(); local cancelled = 0
    a.cancel = function() cancelled = cancelled + 1 end
    q:cancel("manual_control"); H.eq(cancelled, 0)
    q:add({}); q:tick(0); q:pause("input_focus"); q:pause("input_focus"); H.eq(cancelled, 1)
end)
H.test("observer revokes data when target stops being visible", function()
    local visible, a, target, invalidated = true, H.entity(1), H.entity(2), false
    local obs = Observer.new({ G = { CanEntitySeeTarget = function() return visible end }, config = config() },
        function(_, _, kind) if kind == "invalidate" then invalidated = true end end)
    assert(obs:subscribe(a, target, "health", 0)); obs:tick(0)
    visible = false; obs:tick(.1); assert(invalidated); H.eq(next(obs.entities), nil)
end)
H.test("farm grid aligns nine points inside one native tile", function()
    local a, b = Planner.bounds({ x = -2, z = -2 }, { x = 2, z = 2 }, 4 / 3, -4 / 3, -4 / 3)
    local points = Planner.grid(a, b, 4 / 3, 200, function() return true end)
    H.eq(#points, 9)
    for _, point in ipairs(points) do assert(math.abs(point.point.x) < 2 and math.abs(point.point.z) < 2) end
    H.eq(Planner.bounds({ x = 0, z = 0 }, { x = .1, z = .1 }, 1, .5, .5), nil)
end)
H.test("UI has both languages for every information field and stop reason", function()
    local text = require("wildwise/ui/strings").text
    for key in pairs(require("wildwise/services/facts").schema) do assert(text[key] and text[key][1] and text[key][2], key) end
    for _, key in ipairs({ "no_points", "inventory_full", "tool_missing", "materials_empty", "input_focus" }) do assert(text[key][1] and text[key][2]) end
end)
H.test("malformed saved pair is retained intact instead of half migrating", function()
    local saved = { version = 1, next_pair = 2, pairs = { broken = { id = 1 } }, preferences = {} }
    local map = Map.new("1"); H.eq(map:load(saved), false); H.eq(map:save(), saved)
end)
H.test("item spatial index releases removed targets and respects CPU budget", function()
    local service = itemservice(nil, {})
    local a = H.item(1, 0); service:mark(a, "world", 0); service:tick(1)
    assert(next(service.index)); service:forget(a); H.eq(next(service.index), nil)
    local time = 0
    service.env.clock = function() time = time + .0011; return time end
    for i = 2, 10 do service:mark(H.item(i, i * 10), "world", 1) end
    local before = service.processed; service:tick(2)
    H.eq(service.processed - before, 1); assert(service.tail >= service.head)
end)
