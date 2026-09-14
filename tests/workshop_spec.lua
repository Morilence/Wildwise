-- 第二轮工坊案例：先复现 Wildwise 的遗漏，再验证独立修复与降级边界。
local H = require("tests/harness")
local Config = require("wildwise/core/config")
local Facts = require("wildwise/services/facts")
local Observer = require("wildwise/services/observer")
local Recipes = require("wildwise/services/recipes")
local Protocol = require("wildwise/core/protocol")
local Lifetime = require("wildwise/core/lifetime")
local Format = require("wildwise/ui/format")
local json = require("cjson")

local function context()
    return { G = { TheWorld = { state = {}, components = {} } }, config = Config.copy(Config.defaults), now = 100 }
end

H.test("WW2-01 picked grass uses its remaining regeneration time", function()
    local plant = H.entity(1)
    plant.components.pickable = { canbepicked = false, targettime = 180 }
    H.eq(Facts.common(plant, context()).growth_time, 80)
end)

H.test("WW2-02 external regrowth timer receives its entity and is read only", function()
    local plant, calls = H.entity(1), 0
    plant.components.pickable = {
        canbepicked = false,
        useexternaltimer = true,
        getregentimertime = function(inst)
            H.eq(inst, plant)
            calls = calls + 1
            return 45
        end,
    }
    H.eq(Facts.common(plant, context()).growth_time, 45)
    H.eq(calls, 1)
end)

H.test("WW2-03 paused barren and harvest-ready plants have no running countdown", function()
    local plant = H.entity(1)
    for _, state in ipairs({ { paused = true }, { canbepicked = true }, { withered = true } }) do
        plant.components.pickable =
            { canbepicked = state.canbepicked or false, paused = state.paused, targettime = 180 }
        plant.tags.withered = state.withered
        H.eq(Facts.common(plant, context()).growth_time, nil)
    end
end)

H.test("WW2-04 failed snapshot remains fresh and retries unchanged fields", function()
    local p, target, attempts = H.entity(1), H.entity(2), 0
    target.components.health = { currenthealth = 10, maxhealth = 20 }
    local observer = Observer.new(context(), function(_, _, kind, data)
        attempts = attempts + 1
        H.eq(kind, "snapshot")
        H.eq(data.fields.health, 10)
        return attempts > 1
    end)
    observer:subscribe(p, target, "health", 0)
    observer:tick(0)
    observer:tick(0.1)
    H.eq(attempts, 2)
    H.eq(observer.players[p][target].fresh, false)
    observer:close()
end)

H.test("WW2-05 failed delta never advances the acknowledged cache", function()
    local p, target, accepted = H.entity(1), H.entity(2), true
    target.components.health = { currenthealth = 10, maxhealth = 20 }
    local observer = Observer.new(context(), function()
        return accepted
    end)
    observer:subscribe(p, target, "health", 0)
    observer:tick(0)
    accepted = false
    target.components.health.currenthealth = 5
    observer:tick(0.5)
    H.eq(observer.players[p][target].previous.health, 10)
    accepted = true
    observer:tick(1)
    H.eq(observer.players[p][target].previous.health, 5)
    observer:close()
end)

H.test("WW2-06 escaped and multilingual facts fit the actual encoded packet budget", function()
    local fields = {}
    for key in pairs(Facts.schema) do
        fields[key] = string.rep('\1"中文', 300)
    end
    fields.health, fields.health_max = 30, 100
    local safe = Facts.filter(fields, "hover", Config.defaults)
    assert(Protocol.encode(json, "snapshot", string.rep("s", 96), 999, { fields = safe, removed = {} }))
    H.eq(safe.health, 30)
    local cleared = {}
    for key in pairs(Facts.schema) do
        cleared[#cleared + 1] = key
    end
    assert(Protocol.encode(json, "delta", string.rep("s", 96), 999, { fields = safe, removed = cleared }))
end)

H.test("WW2-07 text limits keep whole UTF-8 codepoints", function()
    local entity = H.entity(1)
    entity.components.follower = { leader = H.entity(2) }
    entity.components.follower.leader.GetDisplayName = function()
        return string.rep("牛", 700)
    end
    local value = Facts.common(entity, context()).leader
    H.eq(#value % 3, 0)
    assert(#value <= 1600)
end)

H.test("WW2-08 health and timer fields reject strings tables and infinities", function()
    local safe = Facts.filter(
        { health = "20", health_max = {}, growth_time = math.huge, burning = true },
        "hover",
        Config.defaults
    )
    H.eq(safe.health, nil)
    H.eq(safe.health_max, nil)
    H.eq(safe.growth_time, nil)
    H.eq(safe.burning, true)
    H.eq(Format.value(math.huge, Facts.schema.growth_time, "zh"), "")
    H.eq(Format.value({}, Facts.schema.health, "zh"), "")
end)

local function cooking()
    return {
        ingredients = { berries = { tags = { fruit = 0.5 } }, meat_cooked = { tags = { meat = 1 } } },
        recipes = {
            cookpot = {
                jam = {
                    priority = -1,
                    test = function(_, names, tags)
                        return names.berries == 4 and tags.fruit == 2
                    end,
                },
            },
        },
    }
end
local four = { "berries", "berries", "berries", "berries" }

H.test("WW2-09 cooked meat aliases match native ingredient names and tags", function()
    local cook = cooking()
    cook.recipes.cookpot.meat = {
        test = function(_, names, tags)
            return names.meat_cooked == 4 and tags.meat == 4
        end,
    }
    local result = assert(Recipes.query(cook, "cookpot", { "cookedmeat", "cookedmeat", "cookedmeat", "cookedmeat" }))
    H.eq(result[1].name, "meat")
end)

H.test("WW2-10 ingredient requests must contain exactly four dense slots", function()
    local input = Config.copy(four)
    input.extra = "meat_cooked"
    local result, reason = Recipes.query(cooking(), "cookpot", input)
    H.eq(result, nil)
    H.eq(reason, "four_ingredients")
end)

H.test("WW2-11 invalid ingredient tags fail explicitly without arithmetic errors", function()
    local cook = cooking()
    cook.ingredients.berries.tags.fruit = "0.5"
    local result, reason = Recipes.query(cook, "cookpot", four)
    H.eq(result, nil)
    H.eq(reason, "invalid_ingredient")
end)

H.test("WW2-12 malformed recipe ranking is not reported as a valid dish", function()
    for _, key in ipairs({ "priority", "weight", "cooktime" }) do
        local cook = cooking()
        cook.recipes.cookpot.jam[key] = "bad"
        local result, reason = Recipes.query(cook, "cookpot", four)
        H.eq(result, nil)
        H.eq(reason, "invalid_recipe")
    end
end)

H.test("WW2-13 a failing predicate does not silently select a lower priority meal", function()
    local cook = cooking()
    cook.recipes.cookpot.broken = {
        priority = 100,
        test = function()
            error("changed API")
        end,
    }
    local result, reason = Recipes.query(cook, "cookpot", four)
    H.eq(result, nil)
    H.eq(reason, "invalid_recipe")
end)

H.test("WW2-14 recipe predicates cannot corrupt each other's ingredient tables", function()
    local cook = cooking()
    cook.recipes.cookpot.mutator = {
        priority = -2,
        test = function(_, names, tags)
            names.berries = 0
            tags.fruit = 0
            return true
        end,
    }
    local oldpairs = pairs
    -- 固定先执行会修改输入的配方，避免依赖 Lua 哈希迭代顺序。
    local sequence = { "mutator", "jam" }
    _G.pairs = function(t)
        if t ~= cook.recipes.cookpot then
            return oldpairs(t)
        end
        local i = 0
        return function()
            i = i + 1
            local key = sequence[i]
            if key then
                return key, t[key]
            end
        end
    end
    local ok, result = pcall(Recipes.query, cook, "cookpot", four)
    _G.pairs = oldpairs
    assert(ok, result)
    H.eq(result[1].name, "jam")
    H.eq(cook.ingredients.berries.tags.fruit, 0.5)
end)

H.test("WW2-15 ingredient choices include the cursor and exclude removed backpack items", function()
    local player, dead, active = H.entity(1), H.entity(2), H.entity(3)
    dead.prefab, active.prefab = "berries", "cookedmeat"
    dead:Remove()
    player.replica.inventory = {
        GetItems = function()
            return {}
        end,
        GetActiveItem = function()
            return active
        end,
        GetOverflowContainer = function()
            return {
                GetItems = function()
                    return { dead }
                end,
            }
        end,
    }
    local choices = Recipes.inventory_choices(player, cooking())
    H.eq(#choices, 1)
    H.eq(choices[1], "cookedmeat")
end)

H.test("WW2-16 Shift crafting while a text menu has focus stays native", function()
    local player, native, added = H.entity(1), 0, 0
    player.components.playercontroller =
        { OnControl = function() end, OnLeftClick = function() end, OnRightClick = function() end }
    player.replica.builder = {
        MakeRecipeFromMenu = function()
            native = native + 1
        end,
    }
    local client = {
        player = player,
        scope = Lifetime.new(),
        config = Config.defaults,
        settings = Config.settings(Config.defaults),
        input_ready = function()
            return false
        end,
        adapter = { set_recipe_original = function() end },
        queue = {
            add = function()
                added = added + 1
            end,
        },
    }
    require("wildwise/runtime/input").attach(client, {
        TheInput = {
            IsKeyDown = function()
                return true
            end,
            AddKeyHandler = function()
                return { Remove = function() end }
            end,
        },
    })
    player.replica.builder:MakeRecipeFromMenu({ name = "rope" })
    H.eq(native, 1)
    H.eq(added, 0)
    client.scope:close()
end)

H.test("WW2-17 finder reads sealed contents without spawning or opening anything", function()
    local Containers = require("wildwise/services/containers")
    local bundle, chest = H.entity(1), H.entity(2)
    bundle.components.unwrappable = { itemdata = { { prefab = "honey", data = { stackable = { stack = 3 } } } } }
    chest.components.container = {
        numslots = 1,
        GetItemInSlot = function()
            return bundle
        end,
    }
    assert(Containers.matches(chest, "honey", { remaining = 100 }))
    assert(not Containers.matches(chest, "meat", { remaining = 100 }))
    chest.components.container.canbeopened = false
    assert(not Containers.matches(chest, "honey", { remaining = 100 }))
    H.eq(bundle.components.unwrappable.itemdata[1].data.stackable.stack, 3)
end)

H.test("WW2-18 finder stops on malformed records removed items and exhausted budget", function()
    local Containers = require("wildwise/services/containers")
    local bundle = H.entity(1)
    bundle.components.unwrappable = { itemdata = { false, { prefab = "honey" } } }
    assert(not Containers.matches(bundle, "honey", { remaining = 0 }))
    assert(Containers.matches(bundle, "honey", { remaining = 100 }))
    bundle:Remove()
    assert(not Containers.matches(bundle, "honey", { remaining = 100 }))
end)

H.test("WW2-19 planar damage and defense use current native getters", function()
    local item = H.entity(1)
    item.components.planardamage = {
        GetDamage = function()
            return 27.5
        end,
    }
    item.components.planardefense = {
        GetDefense = function()
            return 12
        end,
    }
    local fields = Facts.common(item, context())
    H.eq(fields.planar_damage, 27.5)
    H.eq(fields.planar_defense, 12)
end)

H.test("WW2-20 broken farm localization cannot erase container or world information", function()
    local entity, item = H.entity(1), H.item(2)
    entity.components.farmplantstress = {
        GetStressDescription = function()
            error("missing translation")
        end,
    }
    entity.components.container = {
        numslots = 1,
        GetItemInSlot = function()
            return item
        end,
    }
    local ctx = context()
    ctx.G.TheWorld.state.cycles = 42
    ctx.config.info.container_contents = true
    local fields = Facts.viewer(entity, entity, ctx)
    H.eq(fields.day, 43)
    assert(fields.contents:find("twigs", 1, true))
    H.eq(fields.stress, nil)
end)

H.test("WW2-21 pocket container search follows the current public master reference", function()
    local Containers = require("wildwise/services/containers")
    local proxy, master, honey = H.entity(1), H.entity(2), H.entity(3)
    honey.prefab = "honey"
    master.components.container = {
        numslots = 1,
        GetItemInSlot = function()
            return honey
        end,
    }
    proxy.components.container_proxy = {
        CanBeOpened = function()
            return true
        end,
        GetMaster = function()
            return master
        end,
    }
    assert(Containers.matches(proxy, "honey", { remaining = 100 }))
    master:Remove()
    assert(not Containers.matches(proxy, "honey", { remaining = 100 }))
end)

H.test("WW2-22 repeated component failures log once per reader", function()
    local entity, calls, ctx = H.entity(1), 0, context()
    ctx.config.diagnostics = true
    entity.components.farmplantstress = {
        GetStressDescription = function()
            error("missing translation")
        end,
    }
    local oldprint = print
    _G.print = function()
        calls = calls + 1
    end
    local ok, err = pcall(function()
        for _ = 1, 100 do
            Facts.viewer(entity, entity, ctx)
        end
    end)
    _G.print = oldprint
    assert(ok, err)
    H.eq(calls, 1)
    H.eq(require("wildwise/core/util").count(ctx.reader_errors), 1)
end)

H.test("WW2-23 food affinity is queried with the current viewer without eating", function()
    local food, viewer, queried = H.entity(1), H.entity(2), nil
    viewer.components.hunger = {}
    viewer.components.eater = {
        hungerabsorption = 1,
        PrefersToEat = function()
            return true
        end,
    }
    food.components.edible = {
        foodtype = "VEGGIE",
        GetHunger = function(_, eater)
            queried = eater
            return 30
        end,
    }
    local fields = Facts.viewer(food, viewer, context())
    H.eq(fields.food_hunger, 30)
    H.eq(queried, viewer)
end)

H.test("WW2-24 information never invokes preserver callbacks to guess wall-clock expiry", function()
    local item, owner = H.entity(1), H.entity(2)
    owner.components.preserver = {
        GetPerishRateMultiplier = function()
            error("must not run")
        end,
    }
    item.components.inventoryitem = { owner = owner }
    item.components.perishable = {
        GetPercent = function()
            return 0.5
        end,
        perishremainingtime = 300,
    }
    local fields = Facts.common(item, context())
    H.eq(fields.freshness, 50)
    H.eq(fields.perish_time, 300)
    H.eq(Format.value(fields.freshness, Facts.schema.freshness, "zh"), "50%")
end)

H.test("WW2-25 cyclic UI data is rejected before invoking a JSON encoder", function()
    local parent = {}
    parent.children = { { parent = parent } }
    local encoder = {
        encode = function()
            error("encoder must not see cyclic UI")
        end,
    }
    H.eq(Protocol.encode(encoder, "snapshot", "s", 1, parent), nil)
end)

H.test("WW2-26 mounted work cannot repeatedly equip a tool to force a missing native action", function()
    local player, target = H.entity(1), H.entity(2)
    player.components.playercontroller = {}
    player.components.playeractionpicker = {
        GetRightClickActions = function()
            return {}
        end,
    }
    player.replica.inventory = {
        GetActiveItem = function() end,
        GetItems = function()
            error("must not equip while riding")
        end,
    }
    player.replica.rider = {
        IsRiding = function()
            return true
        end,
    }
    local adapter = require("wildwise/runtime/actions").create({ player = player }, {
        Vector3 = function(x, y, z)
            return { x = x, y = y, z = z }
        end,
    })
    local state, reason = adapter.validate({ target = target, right = true, action = "TILL" })
    H.eq(state, "pause")
    H.eq(reason, "unsupported_state")
end)

H.test("WW2-27 Woby uses the inherited dryingrack snapshot interface", function()
    local woby = H.entity(1)
    woby.components.wobyrack = {
        GetDryingInfoSnapshot = function()
            return { [1] = 125, [2] = 30 }
        end,
    }
    H.eq(Facts.common(woby, context()).dry_time, 30)
end)

H.test("WW2-28 max health changes refresh without waiting for damage or eating", function()
    local viewer, target, sent = H.entity(1), H.entity(2), {}
    target.components.health = { currenthealth = 125, maxhealth = 125 }
    local observer = Observer.new(context(), function(_, _, _, data)
        for k, v in pairs(data.fields or {}) do
            sent[k] = v
        end
    end)
    observer:subscribe(viewer, target, "health", 0)
    observer:tick(0)
    target.components.health.maxhealth, target.components.health.currenthealth = 575, 575
    observer:tick(0.5)
    H.eq(sent.health_max, 575)
    H.eq(sent.health, 575)
    observer:close()
end)

H.test("WW2-29 malformed client health fields cannot reach healthbar arithmetic", function()
    package.loaded.json = json
    local Client = require("wildwise/runtime/client")
    local target = H.entity(1)
    local client = setmetatable(
        { session = "s", received = 0, subscribed = { [target] = true }, cache = require("wildwise/core/lru").new(4) },
        Client
    )
    client:receive(
        target,
        assert(Protocol.encode(json, "snapshot", "s", 1, { fields = { health = 30, health_max = 100 } }))
    )
    H.eq(client.cache:peek(target).health, 30)
    client:receive(
        target,
        assert(
            Protocol.encode(json, "delta", "s", 2, { fields = { health = {}, health_max = "100" }, removed = false })
        )
    )
    H.eq(client.cache:peek(target).health, nil)
    H.eq(client.cache:peek(target).health_max, nil)
    client.closed = true
    client:receive(target, assert(Protocol.encode(json, "snapshot", "s", 3, { fields = { health = 90 } })))
    H.eq(client.cache:peek(target).health, nil)
end)

H.test("WW2-30 cooking responses cannot overwrite a newer ingredient selection", function()
    local Client = require("wildwise/runtime/client")
    local client = setmetatable({ session = "s", received = 0 }, Client)
    client:clear_recipe_results()
    local old = client.recipe_request
    client:clear_recipe_results()
    client:receive(
        nil,
        assert(Protocol.encode(json, "recipes", "s", 1, { request = old, results = { { name = "jam" } } }))
    )
    H.eq(client.recipe_results, nil)
    client:receive(
        nil,
        assert(
            Protocol.encode(
                json,
                "recipes",
                "s",
                2,
                { request = client.recipe_request, results = {}, reason = "invalid_recipe" }
            )
        )
    )
    H.eq(client.recipe_results.reason, "invalid_recipe")
end)

H.test("WW2-31 portable cooker selection is included in each explicit query", function()
    local Client = require("wildwise/runtime/client")
    local sent
    local client = setmetatable({
        recipe_cooker = "portablecookpot",
        recipe_slots = four,
        send = function(_, _, _, data)
            sent = data
        end,
    }, Client)
    client:query_recipes()
    H.eq(sent.cooker, "portablecookpot")
    H.eq(sent.request, client.recipe_request)
    H.eq(#sent.ingredients, 4)
end)
