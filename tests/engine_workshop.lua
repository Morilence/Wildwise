-- 在隔离专服执行第二轮工坊回归；使用当前游戏真实 prefab、组件和 JSON。
-- 只覆盖无画面组件合约，不代替战斗全过程、远程联机或手柄验收。
local G = _G
local Context = require("wildwise/runtime/context")
local Config = require("wildwise/core/config")
local Facts = require("wildwise/services/facts")
local Recipes = require("wildwise/services/recipes")
local Containers = require("wildwise/services/containers")
local Observer = require("wildwise/services/observer")
local Protocol = require("wildwise/core/protocol")
local Items = require("wildwise/services/items")
local cooking, json = require("cooking"), require("json")
local passed, failed, cleanup = 0, 0, {}
local function test(label, fn)
    local ok, reason = pcall(fn)
    if ok then
        passed = passed + 1
        print("[WW2_ENGINE_PASS] " .. label)
    else
        failed = failed + 1
        print("[WW2_ENGINE_FAIL] " .. label .. " " .. tostring(reason))
    end
end
local function spawn(prefab)
    local inst = assert(G.SpawnPrefab(prefab), prefab)
    cleanup[#cleanup + 1] = inst
    inst.Transform:SetPosition(0, 0, 0)
    if inst.Physics then
        inst.Physics:Stop()
    end
    return inst
end
local config = Config.copy(Context.config)
config.info.container_contents = true
local ctx = { G = G, config = config, cooking = cooking, now = G.GetTime() }
local viewer = spawn("wilson")
viewer.components.playervision:ForceNightVision(true)

-- 同一断言检查不同原生组件形态；每个名字都对应实际采集到的触发实体。
for _, prefab in ipairs({
    "merm_tool",
    "merm_tool_upgraded",
    "shieldofterror",
    "wathgrithr_shield",
    "voidcloth_boomerang",
    "rabbitkingspear",
    "rabbitkinghorn",
    "horseshoe",
    "cotl_trinket",
    "slingshot",
    "slingshotammo_rock",
    "alterguardian_phase4_lunarrift",
    "mutateddeerclops",
    "mutatedbearger",
    "mutatedwarg",
    "lunarthrall_plant",
    "worm_boss",
    "oceanfishingrod",
    "wobybig",
    "chester",
    "wx78_scanner",
    "horn",
    "goldenaxe",
}) do
    test("WWE-01 " .. prefab .. " read-only inspection and retirement", function()
        local inst = spawn(prefab)
        local c = inst.components
        local hp, condition, uses =
            c.health and c.health.currenthealth, c.armor and c.armor.condition, c.finiteuses and c.finiteuses:GetUses()
        local common = Facts.common(inst, ctx)
        local personal = Facts.viewer(inst, viewer, ctx)
        for k, v in pairs(personal) do
            common[k] = v
        end
        local fields = Facts.filter(common, "hover", config)
        assert(Protocol.encode(json, "snapshot", "workshop", 1, { fields = fields, removed = {} }))
        if c.health then
            assert(fields.health == math.floor(hp * 100 + 0.5) / 100 and c.health.currenthealth == hp)
        end
        if c.armor then
            assert(c.armor.condition == condition)
        end
        if c.finiteuses then
            assert(c.finiteuses:GetUses() == uses and fields.uses == uses)
        end
        if c.planardamage then
            assert(fields.planar_damage == c.planardamage:GetDamage())
        end
        if c.planardefense then
            assert(fields.planar_defense == c.planardefense:GetDefense())
        end
        inst:Remove()
        assert(not Containers.matches(inst, "twigs", { remaining = 50 }))
    end)
end

for _, prefab in ipairs({ "grass", "sapling", "berrybush" }) do
    test("WWE-02 " .. prefab .. " regeneration follows the live timer", function()
        local plant = spawn(prefab)
        plant.components.pickable:Pick(viewer)
        local p = plant.components.pickable
        local expected = p.useexternaltimer and p.getregentimertime(plant) or p.targettime - G.GetTime()
        local fields = Facts.common(plant, ctx)
        assert(fields.growth_time and math.abs(fields.growth_time - expected) < 0.05)
        p:Pause()
        assert(Facts.common(plant, ctx).growth_time == nil)
        p:Resume()
        assert(Facts.common(plant, ctx).growth_time > 0)
    end)
end

test("WWE-03 California roll and Warly recipes agree with native cooking", function()
    local inputs = {
        { "kelp", "kelp", "fishmeat", "ice" },
        { "boneshard", "boneshard", "onion", "meat" },
        { "drumstick", "drumstick", "meat", "carrot" },
        { "berries", "berries", "berries", "berries" },
        { "cookedmeat", "cookedmeat", "cookedsmallmeat", "cookedmonstermeat" },
        { "boneshard", "boneshard", "twigs", "meat" },
    }
    for _, cooker in ipairs({ "cookpot", "portablecookpot" }) do
        for _, ingredients in ipairs(inputs) do
            local results, reason = Recipes.query(cooking, cooker, ingredients)
            assert(results, reason)
            local native = cooking.CalculateRecipe(cooker, ingredients)
            local found = false
            for _, result in ipairs(results) do
                found = found or result.name == native
            end
            assert(found, cooker .. ": " .. tostring(native))
        end
    end
    assert(Recipes.query(cooking, "cookpot", inputs[1])[1].name == "californiaroll")
end)

test("WWE-04 Wolfgang favorite food uses current affinity instead of an old hunger formula", function()
    local wolfgang, potato = spawn("wolfgang"), spawn("potato_cooked")
    wolfgang.components.hunger:SetCurrent(1)
    local predicted = assert(Facts.viewer(potato, wolfgang, ctx).food_hunger)
    local before = wolfgang.components.hunger.current
    assert(wolfgang.components.eater:Eat(potato))
    assert(math.abs(wolfgang.components.hunger.current - before - predicted) < 0.05)
end)

test("WWE-05 sealed bundle is found and described without unwrapping", function()
    local bundle, honey, chest = spawn("bundle"), spawn("honey"), spawn("treasurechest")
    bundle.components.unwrappable:WrapItems({ honey }, viewer)
    assert(chest.components.container:GiveItem(bundle, 1))
    assert(Containers.matches(chest, "honey", { remaining = 2048 }))
    assert(Facts.viewer(bundle, viewer, ctx).bundle:find("honey", 1, true))
    assert(bundle:IsValid() and chest.components.container:GetItemInSlot(1) == bundle)
end)

test("WWE-06 horseshoe loot processing keeps native quantity and components", function()
    local horseshoe = spawn("horseshoe")
    local cfg = Config.copy(config)
    cfg.items.pickup_allowed = false
    local items = Items.new(cfg, {
        players = function()
            return {}
        end,
        clock = os.clock,
    })
    local before = horseshoe.components.stackable and horseshoe.components.stackable:StackSize()
    items:mark(horseshoe, "world", 0)
    items:tick(1)
    assert(horseshoe:IsValid())
    if before then
        assert(horseshoe.components.stackable:StackSize() == before)
    end
    items:close()
end)

test("WWE-07 Abigail regeneration keeps native health method and observer lifecycle", function()
    local abigail = spawn("abigail")
    local method = abigail.components.health.DoDelta
    abigail.components.health:SetPercent(0.5)
    local before = abigail.components.health.currenthealth
    local observer = Observer.new(ctx, function()
        return true
    end)
    assert(observer:subscribe(viewer, abigail, "health", G.GetTime()))
    abigail.components.health:DoDelta(2, true, "ghostlyelixir_fastregen_buff", true)
    observer:tick(G.GetTime())
    assert(abigail.components.health.currenthealth == before + 2 and abigail.components.health.DoDelta == method)
    abigail:Remove()
    assert(next(observer.entities) == nil)
    observer:close()
end)

test("WWE-08 encoded facts retain health under worst-case text expansion", function()
    local fields = {}
    for key, schema in pairs(Facts.schema) do
        fields[key] = schema.value_type == "number" and 1e100 or string.rep('\1"牛', 500)
    end
    fields.health, fields.health_max = 20, 50
    local safe = Facts.sanitize(fields)
    assert(Protocol.encode(json, "snapshot", string.rep("s", 96), 10000, { fields = safe, removed = {} }))
    assert(safe.health == 20)
end)

test("WWE-09 World propagates transport failure and wormhole cancellation", function()
    local world = G.TheWorld.components.wildwise_world
    local oldid, oldclient = viewer.userid, Context.client
    viewer.userid = "wildwise-workshop-test"
    local received = {}
    local migrate, original_listen = nil, world.inst.ListenForEvent
    world.inst.ListenForEvent = function(inst, event, fn, source)
        if event == "ms_playerdespawnandmigrate" then
            migrate = fn
        end
        return original_listen(inst, event, fn, source)
    end
    Context.client = {
        player = viewer,
        receive = function(_, _, bytes)
            received[#received + 1] = assert(Protocol.decode(json, bytes))
        end,
    }
    local ok, reason = pcall(function()
        world:AddPlayer(viewer)
        world.inst.ListenForEvent = original_listen
        assert(world.observer.send(viewer, nil, "snapshot", { bad = string.rep("x", 13000) }) == false)
        world.players[viewer].action = { token = "old" }
        viewer:PushEvent("wormholetravel")
        assert(world.players[viewer].action == nil)
        assert(received[#received].kind == "cancel" and received[#received].data.reason == "wormholetravel")
        world.players[viewer].action = { token = "current" }
        assert(migrate, "migration must be listened on the world")
        -- 只调用本模组登记的回调，不真的把夹具角色迁往未启动的 Caves。
        migrate(world.inst, { player = {} })
        assert(world.players[viewer].action.token == "current")
        migrate(world.inst, { player = viewer })
        assert(world.players[viewer].action == nil)
        assert(received[#received].data.reason == "ms_playerdespawnandmigrate")
    end)
    world.inst.ListenForEvent = original_listen
    world:RemovePlayer(viewer)
    Context.client, viewer.userid = oldclient, oldid
    assert(ok, reason)
end)

test("WWE-10 Woby rack uses the native dryingrack compatibility component", function()
    local woby, meat = spawn("wobybig"), spawn("meat")
    woby:AddComponent("wobyrack")
    woby.components.wobyrack:EnableDrying()
    assert(woby.components.wobyrack:GetContainer():GiveItem(meat, 1))
    assert(Facts.common(woby, ctx).dry_time > 0)
end)

for _, inst in ipairs(cleanup) do
    if inst:IsValid() then
        inst:Remove()
    end
end
print(string.format("[WW2_ENGINE_RESULT] passed=%d failed=%d", passed, failed))
