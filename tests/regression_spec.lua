-- 工坊反馈与本地审查的回归场景；WW 编号对应 docs/workshop-issues.md。
local H = require("tests/harness")
local Config = require("wildwise/core/config")
local Map = require("wildwise/services/map")
local Observer = require("wildwise/services/observer")
local Actions = require("wildwise/runtime/actions")
local Lifetime = require("wildwise/core/lifetime")
local Items = require("wildwise/services/items")
local Facts = require("wildwise/services/facts")
local Transfer = require("wildwise/core/map_transfer")
local Signs = require("wildwise/services/signs")
local json = require("cjson")

local function endpoint(key, x)
    return { key = key, prefab = "wormhole", x = x or 0, z = 0 }
end

H.test("WW-M01 saved pair coordinates and IDs must be valid before loading", function()
    local mutations = {
        function(s)
            s.pairs[1].a.x = 0 / 0
        end,
        function(s)
            s.pairs[1].b.prefab = nil
        end,
        function(s)
            s.next_pair = 1
        end,
        function(s)
            s.preferences.user = { exploration = "false" }
        end,
        function(s)
            s.pairs[2] = Config.copy(s.pairs[1])
            s.pairs[2].id = 2
            s.next_pair = 3
        end,
        function(s)
            s.exploration = { [2] = { x = 1, z = 1 } }
        end,
        function(s)
            s.worldid = "Caves"
        end,
    }
    for _, mutate in ipairs(mutations) do
        local map = Map.new("Master")
        map:discover("user", endpoint("a"), endpoint("b", 1), true)
        local saved = Config.copy(map:save())
        mutate(saved)
        local restored = Map.new("Master")
        H.eq(restored:load(saved), false)
        H.eq(restored:save(), saved)
        H.eq(restored:discover("user", endpoint("c"), endpoint("d", 2), true), nil)
        H.eq(restored:record_exploration(1, 2), false)
        H.eq(restored:set_preference("user", "position", false), false)
    end
end)

H.test("WW-M02 map load and save snapshots do not alias active data", function()
    local map = Map.new("1")
    map:discover("a", endpoint("a"), endpoint("b", 1), false)
    local saved = map:save()
    local restored = Map.new("1")
    assert(restored:load(saved))
    restored:discover("a", endpoint("a"), endpoint("b", 1), true)
    H.eq(saved.pairs[1].shared, false)
    H.eq(map.pairs[1].shared, false)
end)

H.test("WW-X01 information and health subscriptions never grant another player's private map", function()
    local map, owner, other, target = Map.new("1"), H.entity(1), H.entity(2), H.entity(3)
    owner.userid, other.userid = "owner", "other"
    local id = map:discover(owner.userid, endpoint("a", 1), endpoint("b", 2), false)
    target.components.health = { currenthealth = 10, maxhealth = 10 }
    local context = {
        config = Config.copy(Config.defaults),
        G = {
            CanEntitySeeTarget = function(viewer)
                return viewer == owner
            end,
        },
    }
    local obs = Observer.new(context, function() end)
    assert(obs:subscribe(owner, target, "health", 0))
    assert(obs:subscribe(owner, target, "hover", 0))
    assert(not obs:subscribe(other, target, "hover", 0))
    obs:tick(0)
    H.eq(map:visible_pairs(owner.userid, false)[1].id, id)
    H.eq(#map:visible_pairs(other.userid, true), 0)
    H.eq(#map.exploration, 0)
    obs:close()
end)

H.test("WW-C01 malformed personal settings cannot break scale grids or bindings", function()
    local settings = Config.settings(Config.defaults)
    Config.restore(settings, {
        ui_scale = 0,
        menu_key = -1,
        queue = { farm_grid = 0 },
        healthbars = { limit = math.huge, scale = 0 / 0, hostile_scope = "unknown" },
        beefalo = { offset_x = 1e20 },
        language = "bad",
    })
    H.eq(settings.ui_scale, 1)
    H.eq(settings.menu_key, 288)
    H.eq(settings.queue.farm_grid, 3)
    H.eq(settings.healthbars.limit, 12)
    H.eq(settings.healthbars.scale, 1)
    H.eq(settings.healthbars.hostile_scope, "self")
    H.eq(settings.beefalo.offset_x, 0)
    H.eq(settings.language, "auto")
end)

H.test("WW-O01 broken information component cannot stop other observations", function()
    local viewer, bad, good, sent = H.entity(1), H.entity(2), H.entity(3), {}
    bad.components.fueled = {
        GetPercent = function()
            error("changed game API")
        end,
    }
    bad.components.health = { currenthealth = 4, maxhealth = 10 }
    good.components.health = { currenthealth = 7, maxhealth = 10 }
    local context = { G = { TheWorld = { state = {} } }, config = Config.copy(Config.defaults) }
    local obs = Observer.new(context, function(_, target, _, data)
        sent[target] = data.fields
    end)
    assert(obs:subscribe(viewer, bad, "hover", 0))
    assert(obs:subscribe(viewer, good, "health", 0))
    obs:tick(0)
    H.eq(sent[bad].health, 4)
    H.eq(sent[good].health, 7)
    assert(context.reader_errors and next(context.reader_errors))
    obs:close()
end)

H.test("WW-O02 hover immediately expands an existing health-only observation", function()
    local a, b, target, sent = H.entity(1), H.entity(2), H.entity(3), {}
    target.components.health = { currenthealth = 10, maxhealth = 10 }
    target.components.finiteuses = {
        GetUses = function()
            return 8
        end,
        GetPercent = function()
            return 0.8
        end,
        total = 10,
    }
    local obs = Observer.new({ G = {}, config = Config.copy(Config.defaults) }, function(p, _, _, data)
        sent[p] = data.fields
    end)
    obs:subscribe(a, target, "health", 0)
    obs:tick(0)
    obs:subscribe(b, target, "hover", 0.1)
    obs:tick(0.1)
    H.eq(sent[b].uses, 8)
    obs:close()
end)

H.test("WW-Q01 destroyed platform never falls back to the last world point", function()
    local player, platform = H.entity(1), H.entity(2)
    platform:Remove()
    player.components.playercontroller = {}
    player.replica.inventory = {}
    local adapter = Actions.create({ player = player }, {})
    local result = adapter.validate({ action = "TILL", plan = { platform = platform }, point = { x = 2, z = 2 } })
    H.eq(result, "skip")
end)

H.test("WW-Q02 Shift building placement and manual attacks reach native controls", function()
    local player, target, count, cancels = H.entity(1), H.entity(2), 0, 0
    local pc = {
        placer = {},
        OnLeftClick = function()
            count = count + 1
        end,
        OnRightClick = function()
            count = count + 1
        end,
        OnControl = function() end,
    }
    player.components.playercontroller = pc
    player.components.playeractionpicker = {
        GetLeftClickActions = function()
            return { { action = { id = "ATTACK" } } }
        end,
    }
    player.replica.inventory = { GetEquippedItem = function() end, GetActiveItem = function() end }
    local client = {
        player = player,
        scope = Lifetime.new(),
        config = Config.copy(Config.defaults),
        settings = Config.settings(Config.defaults),
        input_ready = function()
            return true
        end,
        queue = {
            cancel = function()
                cancels = cancels + 1
            end,
        },
        clear_preview = function() end,
    }
    local input = {
        GetHUDEntityUnderMouse = function() end,
        IsKeyDown = function()
            return true
        end,
        GetWorldPosition = function()
            return { x = 0, z = 0 }
        end,
        GetScreenPosition = function()
            return { x = 0, y = 0 }
        end,
        GetWorldEntityUnderMouse = function()
            return target
        end,
        AddKeyHandler = function()
            return { Remove = function() end }
        end,
    }
    require("wildwise/runtime/input").attach(client, {
        TheInput = input,
        EQUIPSLOTS = {},
        GetTime = function()
            return 0
        end,
    })
    pc:OnLeftClick(true)
    pc:OnLeftClick(false)
    H.eq(count, 2)
    H.eq(cancels, 1)
    pc.placer = nil
    pc:OnLeftClick(true)
    pc:OnLeftClick(false)
    H.eq(count, 4)
    H.eq(cancels, 2)
    client.scope:close()
end)

H.test("WW-M03 large map chunks respect protocol budgets and commit atomically", function()
    local data = { players = {}, pings = {}, pairs = {}, fires = {} }
    for i = 1, 700 do
        data.pairs[i] = { id = i, a = endpoint("a" .. i, i), b = endpoint("b" .. i, i + 1) }
    end
    local packets = assert(Transfer.pack(json, data, 1))
    assert(#packets > 2)
    local pending, snapshot
    for i, packet in ipairs(packets) do
        assert(require("wildwise/core/protocol").encode(json, packet.kind, "session", i, packet.data))
        pending, snapshot = Transfer.receive(pending, packet.kind, packet.data)
        if i < #packets then
            H.eq(snapshot, nil)
        end
    end
    H.eq(#snapshot.pairs, 700)
    pending = Transfer.receive(nil, "map_begin", packets[1].data)
    pending = Transfer.receive(pending, "map_chunk", packets[2].data)
    local _, incomplete = Transfer.receive(pending, "map_end", packets[#packets].data)
    H.eq(incomplete, nil)
    H.eq(Transfer.pack(json, { players = { { name = string.rep("x", 5000) } } }, 2), nil)
end)

H.test("WW-O03 broken health getter and nil mounts do not crash or invent stats", function()
    local entity = H.entity(1)
    entity.components.health = {
        GetMaxWithPenalty = function()
            error("removed")
        end,
    }
    local context = { G = {}, config = Config.copy(Config.defaults) }
    H.eq(next(Facts.health(entity, context)), nil)
    assert(context.reader_errors.health)
    entity.components = { rideable = { saddle = nil } }
    H.eq(Facts.common(entity, context).ride_time, nil)
end)

H.test("WW-O04 observation never invokes unknown food modifiers or changes damage", function()
    local viewer, target = H.entity(1), H.entity(2)
    viewer.components.eater = {
        PrefersToEat = function()
            return true
        end,
        custom_stats_mod_fn = function()
            error("must not run")
        end,
    }
    target.components.edible = { foodtype = "MEAT" }
    target.components.combat = { defaultdamage = 20 }
    target.components.planardamage = { basedamage = 15 }
    local context = { G = {}, config = Config.copy(Config.defaults) }
    H.eq(Facts.viewer(target, viewer, context).food_health, nil)
    Facts.common(target, context)
    H.eq(target.components.combat.defaultdamage, 20)
    H.eq(target.components.planardamage.basedamage, 15)
end)

H.test("WW-I01 loaded opt-in marks restored items only and preserves explicit drops", function()
    local callbacks, cfg = {}, Config.copy(Config.defaults)
    cfg.items.stack_loaded = true
    local service = Items.new(cfg, {})
    local G = {
        TheWorld = { ismastersim = true },
        POPULATING = true,
        GetTime = function()
            return 0
        end,
    }
    require("wildwise/runtime/items").register(
        {
            AddComponentPostInit = function(key, fn)
                callbacks[key] = fn
            end,
        },
        G,
        cfg,
        function()
            return { items = service }
        end
    )
    local item, tasks = H.item(1), {}
    function item.DoTaskInTime(_, _, fn)
        tasks[#tasks + 1] = fn
        return { Cancel = function() end }
    end
    function item.SetPersistData() end
    item.components.inventoryitem.inst = item
    callbacks.inventoryitem(item.components.inventoryitem)
    H.eq(service.known[item], nil)
    H.eq(#tasks, 0)
    item:SetPersistData({})
    tasks[1]()
    H.eq(service.known[item].source, "loaded")
    service:mark(item, "manual", 0)
    item:PushEvent("stopfalling")
    H.eq(service.known[item].source, "manual")
    service:forget(item)
    G.POPULATING = false
    item:SetPersistData({}) -- 原版运行期解包同样恢复保存记录，但不属于世界读档。
    H.eq(#tasks, 1)
    H.eq(service.known[item], nil)
    item:Remove()
    H.eq(service.known[item], nil)
end)

H.test("WW-I02 falling debris and protected targets never consume a safe ground stack", function()
    local cfg, a, b = Config.copy(Config.defaults), H.item(1, 0, 5), H.item(2, 1, 7)
    local service = Items.new(cfg, {
        players = function()
            return {}
        end,
        result = function() end,
    })
    service:mark(a, "world", 0)
    service:process(a, 1)
    b.Physics = {
        GetVelocity = function()
            return 0, -2, 0
        end,
    }
    service:mark(b, "world", 0)
    service:process(b, 1)
    H.eq(a.components.stackable:StackSize(), 5)
    assert(b.valid)
    b.Physics = nil
    b.platform = H.entity(3)
    b.platform.entity.WorldToLocalSpace = function(_, x, y, z)
        return x, y, z
    end
    service:process(b, 2)
    H.eq(a.components.stackable:StackSize(), 5)
    assert(b.valid)
    b.platform = nil
    service:process(b, 3)
    H.eq(a.components.stackable:StackSize(), 12)
    H.eq(b.valid, false)
end)

H.test("WW-I03 pickup permission cannot enable stacking of a disabled source", function()
    local cfg, a, b = Config.copy(Config.defaults), H.item(1, 0, 5), H.item(2, 1, 7)
    cfg.items.stack_world, cfg.items.stack_manual, cfg.items.pickup_allowed = false, true, true
    local service = Items.new(cfg, {
        players = function()
            return {}
        end,
        result = function() end,
    })
    service:mark(a, "world", 0)
    service:mark(b, "manual", 0)
    service:tick(1)
    H.eq(a.components.stackable:StackSize(), 5)
    H.eq(b.components.stackable:StackSize(), 7)
end)

H.test("WW-S01 bundled skins and spices resolve without spawning the contents", function()
    local item = H.entity(1)
    local G = {
        GetInventoryItemAtlas = function(name)
            return name .. ".xml"
        end,
        GetSkinInvIconName = function()
            return "skin_icon"
        end,
        SpawnPrefab = function()
            error("query must not spawn")
        end,
    }
    item.components.unwrappable = { itemdata = { { prefab = "meatballs_spice_chili" } } }
    local name, _, bg = Signs.image(item, G)
    H.eq(name, "spice_chili_over")
    H.eq(bg, "meatballs")
    item.components.unwrappable.itemdata[1] = { prefab = "axe", skinname = "skin" }
    H.eq(Signs.image(item, G), "skin_icon")
    item.components.unwrappable.itemdata[1] = {}
    H.eq(Signs.image(item, G), nil)
end)

H.test("WW-Q03 released action callbacks cannot complete a later queue task", function()
    local player, callbacks, sends = H.entity(1), {}, 0
    player.replica.builder = {
        MakeRecipeFromMenu = function()
            sends = sends + 1
        end,
    }
    local adapter = Actions.create({ player = player, send = function() end }, {
        GetTime = function()
            return 0
        end,
        AllRecipes = { rope = {} },
    })
    adapter.submit({ recipe = "rope", remaining = 2 }, "old", function()
        callbacks.old = true
    end)
    adapter.release()
    adapter.result({ token = "old", result = "success" })
    H.eq(callbacks.old, nil)
    H.eq(sends, 1)
end)
