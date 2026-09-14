local H = require("tests/harness")
local Config = require("wildwise/core/config")
local Items = require("wildwise/services/items")
local Actions = require("wildwise/runtime/actions")
local Details = require("wildwise/services/details")
local Facts = require("wildwise/services/facts")
local Format = require("wildwise/ui/format")
local Signs = require("wildwise/services/signs")
local Queue = require("wildwise/services/queue")

H.test("WW3-21 recipe weights and base times are visible with localized dish names", function()
    local result = Format.recipes({
        { name = "one", weight = 1, cooktime = 2 },
        { name = "two", weight = 3, cooktime = 1 },
    }, "zh", { time_style = "seconds" }, { ONE = "一", TWO = "二" }, 20)
    assert(result:find("一 · 25.0%% · 基础耗时 40 s"))
    assert(result:find("二 · 75.0%% · 基础耗时 20 s"))
end)

H.test("WW3-22 invalid saved mount appearance cannot break the native HUD", function()
    local settings = Config.settings(Config.defaults)
    Config.restore(settings, { beefalo = { layout = "bad_skin", background = -5 } })
    H.eq(settings.beefalo.layout, "badges")
    H.eq(settings.beefalo.background, 0.82)
    Config.restore(settings, { beefalo = { layout = "compact", background = 0 } })
    H.eq(settings.beefalo.layout, "compact")
    H.eq(settings.beefalo.background, 0)
end)

local function item_service(cfg, extra)
    local env = {
        players = function()
            return {}
        end,
        pickup = function()
            return false
        end,
        result = function() end,
    }
    for key, value in pairs(extra or {}) do
        env[key] = value
    end
    return Items.new(cfg or Config.copy(Config.defaults), env)
end

H.test("WW3-01 zero source radii inherit existing server settings", function()
    local cfg = Config.load(function(key)
        if key == "items_radius" then
            return 8
        end
    end)
    local service = item_service(cfg)
    H.eq(service:radius("world"), 8)
    H.eq(service:radius("manual"), 8)
    H.eq(service:radius("pickup"), 8)
    cfg.items.world_radius, cfg.items.manual_radius, cfg.items.pickup_radius = 2, 10, 1
    H.eq(service:radius("loaded"), 2)
    H.eq(service:cellsize(), 10)
    H.eq(service:radius("pickup"), 1)
end)

H.test("WW3-02 source radii do not leak through the shared spatial index", function()
    local cfg = Config.copy(Config.defaults)
    cfg.items.stack_manual, cfg.items.world_radius, cfg.items.manual_radius = true, 2, 10
    local old, world, manual = H.item(1, 0, 2), H.item(2, 5, 3), H.item(3, 7, 4)
    local service = item_service(cfg)
    service:mark(old, "manual", 0)
    service:tick(1)
    service:mark(world, "world", 1)
    service:tick(2)
    assert(world.valid)
    service:mark(manual, "manual", 2)
    service:tick(3)
    H.eq(old.components.stackable.size, 6)
    H.eq(world.components.stackable.size, 3)
end)

H.test("WW3-03 burning and smoldering objects cannot merge from either end", function()
    for _, mode in ipairs({ "tag", "burning", "smoldering" }) do
        local a, b = H.item(1, 0, 2), H.item(2, 1, 3)
        if mode == "tag" then
            a.tags.fire = true
        else
            a.components.burnable = {
                IsBurning = function()
                    return mode == "burning"
                end,
                IsSmoldering = function()
                    return mode == "smoldering"
                end,
            }
        end
        local service = item_service()
        service:mark(a, "world", 0)
        service:mark(b, "world", 0)
        service:tick(1)
        assert(a.valid and b.valid)
        H.eq(a.components.stackable.size, 2)
    end
end)

H.test("WW3-04 stack and pickup exclusion tags apply independently", function()
    local cfg = Config.copy(Config.defaults)
    cfg.items.pickup_allowed = true
    cfg.items.stack_manual = true
    local service, item = item_service(cfg), H.item(1)
    service:mark(item, "world", 0)
    item.tags.no_autostack_w = true
    H.eq(service:operation_allowed(item, "stack", 1), false)
    H.eq(service:operation_allowed(item, "pickup", 1), true)
    item.tags.no_autopickup = true
    H.eq(service:operation_allowed(item, "pickup", 1), false)
    service:mark(item, "manual", 0)
    H.eq(service:operation_allowed(item, "stack", 1), true)
    item.tags.no_autostack_m = true
    H.eq(service:operation_allowed(item, "stack", 1), false)
end)

H.test("WW3-05 ash manure and seed filters are independent per operation", function()
    local cfg = Config.copy(Config.defaults)
    cfg.items.pickup_allowed = true
    cfg.items.stack_manual = true
    local service = item_service(cfg)
    for _, name in ipairs({ "ash", "poop", "seeds", "carrot_seeds" }) do
        cfg.items.world_ash, cfg.items.world_poop, cfg.items.world_seeds = false, false, false
        local item = H.item(1)
        item.prefab = name
        service:mark(item, "world", 0)
        H.eq(service:operation_allowed(item, "stack", 1), false)
        H.eq(service:operation_allowed(item, "pickup", 1), false)
        local key = name == "carrot_seeds" and "seeds" or name
        cfg.items["world_" .. key] = true
        H.eq(service:operation_allowed(item, "stack", 1), true)
        H.eq(service:operation_allowed(item, "pickup", 1), false)
        service:mark(item, "manual", 0)
        H.eq(service:operation_allowed(item, "stack", 1), false)
    end
end)

H.test("WW3-06 natural twiggy drops retain entity counts and manual drops remain explicit", function()
    local cfg = Config.copy(Config.defaults)
    cfg.items.stack_manual = true
    local service = item_service(cfg, {
        near_twiggy = function()
            return true
        end,
    })
    local a, b = H.item(1, 0, 1), H.item(2, 1, 1)
    service:mark(a, "world", 0)
    service:mark(b, "loaded", 0)
    service:tick(1)
    assert(a.valid and b.valid)
    service:mark(a, "manual", 1)
    service:mark(b, "manual", 1)
    service:tick(2)
    H.eq(a.components.stackable.size, 2)
end)

H.test("WW3-07 automation cannot target players or arbitrary activation containers", function()
    local player, other, chest, rack = H.entity(1), H.entity(2), H.entity(3), H.entity(4)
    player.tags.player, other.tags.player = true, true
    chest.prefab, rack.prefab = "treasurechest", "meatrack"
    for _, id in ipairs({ "GIVE", "GIVEALLTOPLAYER", "ATTACK", "CASTSPELL", "STORE" }) do
        H.eq(Actions.accepts(player, id, other), false)
    end
    assert(Actions.accepts(player, "HEAL", player))
    H.eq(Actions.accepts(player, "ACTIVATE", chest), false)
    H.eq(Actions.accepts(player, "RUMMAGE", chest), false)
    assert(Actions.accepts(player, "RUMMAGE", rack))
    H.eq(Actions.allowed.ROW_FAIL, nil)
end)

H.test("WW3-08 selecting an allowed secondary action preserves the desired action", function()
    local player, target = H.entity(1), H.entity(2)
    player.components.playeractionpicker = {
        GetLeftClickActions = function()
            return { { action = { id = "ATTACK" } }, { action = { id = "PICKUP" } }, { action = { id = "PICK" } } }
        end,
    }
    H.eq(Actions.pick(player, target, {}, false, "PICK").action.id, "PICK")
    target.tags.fire = true
    H.eq(Actions.pick(player, target, {}, false, "PICKUP"), nil)
end)

H.test("WW3-09 agricultural plans choose native tool and tile modes", function()
    local tool, active = H.item(1), H.item(2)
    tool.prefab = "pitchfork"
    H.eq(Actions.plan_mode(nil, tool), "TERRAFORM")
    tool.prefab = "wateringcan"
    tool.tags.wateringcan = true
    H.eq(Actions.plan_mode(nil, tool), "POUR_WATER_GROUNDTILE")
    active.tags.tile_deploy = true
    H.eq(Actions.plan_mode(active, tool), "DEPLOY_TILEARRIVE")
    active.tags.tile_deploy = nil
    H.eq(Actions.plan_mode(active, tool), "DEPLOY")
    tool.tags.wateringcan = nil
    tool.HasActionComponent = function(_, name)
        return name == "farmtiller"
    end
    H.eq(Actions.plan_mode(nil, tool), "TILL")
end)

H.test("WW3-10 plan checks native terrain without modifying the map", function()
    local G = {
        TheWorld = {
            Map = {
                CanTerraformAtPoint = function(_, x)
                    return x == 4
                end,
                IsFarmableSoilAtPoint = function(_, x)
                    return x == 8
                end,
            },
        },
    }
    assert(Actions.plan_valid("TERRAFORM", { x = 4, z = 0 }, nil, nil, G))
    H.eq(Actions.plan_valid("TERRAFORM", { x = 8, z = 0 }, nil, nil, G), false)
    assert(Actions.plan_valid("POUR_WATER_GROUNDTILE", { x = 8, z = 0 }, nil, nil, G))
end)

H.test("WW3-11 source flags and public config do not override saved personal choices", function()
    local settings = Config.settings(Config.defaults)
    Config.restore(settings, {
        info = { food_values = false, max_lines = 20 },
        beefalo = { scale = 1.25, show_hunger = false },
        map = { show_fires = false },
        queue = { double_click_speed = 0.5 },
    })
    H.eq(settings.info.food_values, false)
    H.eq(settings.info.max_lines, 20)
    H.eq(settings.beefalo.show_hunger, false)
    H.eq(settings.map.show_fires, false)
    H.eq(settings.queue.double_click_speed, 0.5)
    Config.restore(
        settings,
        { info = { max_lines = 1000 }, beefalo = { scale = 0 }, queue = { double_click_speed = -1 } }
    )
    H.eq(settings.info.max_lines, 20)
    H.eq(settings.beefalo.scale, 1.25)
    H.eq(settings.queue.double_click_speed, 0.5)
end)

H.test("WW3-12 information permissions and personal toggles suppress exact groups", function()
    local cfg = Config.copy(Config.defaults)
    cfg.info.perishable = false
    cfg.info.cooldowns = false
    local filtered =
        Facts.filter({ freshness = 50, perish_estimate = 10, food_health = 5, cooldown_time = 3 }, "hover", cfg)
    H.eq(filtered.freshness, nil)
    H.eq(filtered.perish_estimate, nil)
    H.eq(filtered.food_health, 5)
    H.eq(filtered.cooldown_time, nil)
    local settings = Config.settings(cfg)
    settings.info.food_values = false
    H.eq(Format.lines({ food_health = 5 }, settings, "en", true, false), "")
end)

H.test("WW3-13 truncation is explicit and time units preserve a game day", function()
    local settings = Config.settings(Config.defaults)
    settings.info.max_lines = 4
    local value = Format.lines(
        { health = 1, health_max = 2, damage = 3, armor = 4, absorption = 5 },
        settings,
        "en",
        false,
        false
    )
    assert(value:find("more; hold Inspect", 1, true))
    H.eq(Format.value(480, { unit = "s" }, "en", { time_style = "days" }), "1.00 game days")
    H.eq(Format.value(70, { id = "temperature", unit = "" }, "en", { temperature_units = "celsius" }), "35.0 °C")
end)

H.test("WW3-14 timers preserve paused remaining values without mutating components", function()
    local e = H.entity(1)
    e.components.timer = {
        timers = {
            cooldown = { end_time = 30, timeleft = 50 },
            regen = { paused = true, timeleft = 12 },
            secret = {
                end_time = 99,
            },
        },
    }
    local text = Details.timers(e, 10)
    assert(text:find("cooldown:20:running", 1, true))
    assert(text:find("regrowth:12:paused", 1, true))
    assert(not text:find("secret", 1, true))
    H.eq(e.components.timer.timers.cooldown.timeleft, 50)
end)

local function perish_context()
    return {
        TheWorld = { state = { temperature = 20 } },
        TUNING = {
            PERISH_GROUND_MULT = 1.5,
            PERISH_FRIDGE_MULT = 0.5,
            PERISH_COLD_FROZEN_MULT = 0,
            PERISH_FOOD_PRESERVER_MULT = 0.75,
            PERISH_CAGE_MULT = 0.5,
            PERISH_WET_MULT = 1.3,
            PERISH_WINTER_MULT = 0.75,
            PERISH_FROZEN_FIRE_MULT = 20,
            PERISH_SUMMER_MULT = 1.25,
            OVERHEAT_TEMP = 70,
            PERISH_GLOBAL_MULT = 1,
        },
    }
end

H.test("WW3-15 spoilage estimates follow ground fridge wetness and local modifiers", function()
    local item, G = H.item(1), perish_context()
    item.components.perishable = { perishremainingtime = 120, localPerishMultiplyer = 1, updatetask = {} }
    H.eq(Details.perish(item, G), 80)
    local fridge = H.entity(2)
    fridge.tags.fridge = true
    item.components.inventoryitem.owner = fridge
    H.eq(Details.perish(item, G), 240)
    item.components.perishable.localPerishMultiplyer = 2
    H.eq(Details.perish(item, G), 120)
end)

H.test("WW3-16 unknown preservation callbacks and acid rain produce no misleading estimate", function()
    local item, G = H.item(1), perish_context()
    item.components.perishable = { perishremainingtime = 120, updatetask = {} }
    local owner = H.entity(2)
    owner.components.preserver = {
        perish_rate_multiplier = function()
            error("must not run")
        end,
    }
    item.components.inventoryitem.owner = owner
    local eta, state = Details.perish(item, G)
    H.eq(eta, nil)
    H.eq(state, "custom_modifier")
    item.components.inventoryitem.owner = nil
    G.TheWorld.state.isacidraining = true
    eta, state = Details.perish(item, G)
    H.eq(eta, nil)
    H.eq(state, "acid_rain")
    item.components.perishable.updatetask = nil
    eta, state = Details.perish(item, G)
    H.eq(eta, nil)
    H.eq(state, "paused")
end)

H.test("WW3-17 completed validation does not submit an extra native action", function()
    local sent, finished = 0, 0
    local queue = Queue.new({
        ready = function()
            return true
        end,
        validate = function()
            return "done"
        end,
        release = function() end,
        submit = function()
            sent = sent + 1
        end,
        finished = function()
            finished = finished + 1
        end,
    })
    queue:add({})
    queue:tick(0)
    H.eq(sent, 0)
    H.eq(finished, 1)
    H.eq(queue.state, "idle")
end)

H.test("WW3-18 a completion hook can enqueue bounded follow-up work", function()
    local queue
    queue = Queue.new({
        ready = function()
            return true
        end,
        validate = function()
            return "done"
        end,
        release = function() end,
        finished = function(task)
            if task.work then
                queue:add({ key = "loot" })
            end
        end,
    })
    queue:add({ work = true })
    queue:tick(0)
    H.eq(#queue.tasks, 1)
    H.eq(queue.state, "running")
    queue:tick(1)
    H.eq(queue.state, "idle")
end)

H.test("WW3-19 sign skin uses only the stored item's linked native skin", function()
    local item = H.item(1)
    item.prefab = "minisign_item"
    item.linked_skinname = "minisign_test"
    item.skin_id = 17
    local container = {
        numslots = 2,
        GetItemInSlot = function(_, slot)
            if slot == 2 then
                return item
            end
        end,
    }
    local skin, id = Signs.skin(container, { body_skins = true })
    H.eq(skin, "minisign_test")
    H.eq(id, 17)
    H.eq(Signs.skin(container, { body_skins = false }), nil)
    item.prefab = "other"
    H.eq(Signs.skin(container), nil)
end)

H.test("WW3-20 disabling bundled content shows the wrapper's own native inventory image", function()
    local item = H.item(1)
    item.prefab = "bundle"
    item.components.inventoryitem.imagename = "bundle"
    item.components.unwrappable = { itemdata = { { prefab = "carrot" } } }
    local G = {
        GetInventoryItemAtlas = function(tex)
            return "atlas:" .. tex
        end,
    }
    H.eq(Signs.image(item, G, { bundle_contents = false }), "bundle")
    H.eq(Signs.image(item, G, { bundle_contents = true }), "carrot")
end)
