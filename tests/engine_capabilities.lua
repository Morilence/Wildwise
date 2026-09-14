-- 在隔离专服验证真实组件/容器操作及无画面 HUD；人工角色与同步动作夹具不代表远程输入验收。
local G = _G
local Config = require("wildwise/core/config")
local Context = require("wildwise/runtime/context")
local Facts = require("wildwise/services/facts")
local Details = require("wildwise/services/details")
local Actions = require("wildwise/runtime/actions")
local Signs = require("wildwise/services/signs")
local Items = require("wildwise/services/items")
local passed, failed, cleanup = 0, 0, {}
local function test(name, fn)
    local ok, reason = pcall(fn)
    if ok then
        passed = passed + 1
        print("[WW3_ENGINE_PASS] " .. name)
    else
        failed = failed + 1
        print("[WW3_ENGINE_FAIL] " .. name .. " " .. tostring(reason))
    end
end
local function spawn(name)
    local item = assert(G.SpawnPrefab(name), name)
    cleanup[#cleanup + 1] = item
    item.Transform:SetPosition(0, 0, 0)
    if item.Physics then
        item.Physics:Stop()
    end
    return item
end
local cfg = Config.copy(Context.config)
local ctx = { G = G, config = cfg, cooking = require("cooking"), now = G.GetTime() }
local viewer = spawn("wilson")
viewer.components.playervision:ForceNightVision(true)
local old_player = G.ThePlayer
G.ThePlayer = viewer
viewer.userid = "wildwise_capability_fixture"
viewer.components.inventory:Open()
if not viewer.components.playeractionpicker then
    viewer:AddComponent("playeractionpicker")
end
if not viewer.components.playercontroller then
    viewer:AddComponent("playercontroller")
end
local client = {
    player = viewer,
    config = cfg,
    settings = Config.settings(cfg),
    session = "fixture",
    input_ready = function()
        return true
    end,
    send = function() end,
}
local adapter = Actions.create(client, G)

test("real spoilage getter observes fridge multiplier without consuming food", function()
    local food, box = spawn("carrot"), spawn("icebox")
    local initial = food.components.perishable.perishremainingtime
    local ground, state = Details.perish(food, G)
    assert(ground and state == "environment_estimate")
    box.components.container:GiveItem(food)
    local stored = Details.perish(food, G)
    assert(stored and stored > ground)
    assert(food.components.perishable.perishremainingtime == initial)
end)

test("native recharge cooldown sewing and timer details", function()
    local item = spawn("spear")
    item:AddComponent("rechargeable")
    item.components.rechargeable:Discharge(30)
    item:AddComponent("timer")
    item.components.timer:StartTimer("cooldown", 40, true)
    local before = item.components.timer.timers.cooldown.timeleft
    local fields = Facts.common(item, ctx)
    assert(fields.cooldown_time == 30 and fields.recharge == 0)
    assert(fields.timers:find("cooldown:40:paused", 1, true))
    assert(item.components.timer.timers.cooldown.timeleft == before)
    local kit = spawn("sewing_kit")
    assert(Facts.common(kit, ctx).sew_value == kit.components.sewing.repair_value)
end)

test("plant stress details read recorded state without invoking stress tests", function()
    local plant = spawn("farm_plant_carrot")
    local stress = plant.components.farmplantstress
    stress:SetStressed("nutrients", true)
    local before = stress.stress_points
    local fields = Facts.common(plant, ctx)
    assert(fields.stress_points == before and fields.stress_sources:find("nutrients", 1, true))
    assert(stress.stress_points == before)
end)

test("display day agrees with native clock cycle plus one", function()
    assert(Facts.viewer(viewer, viewer, ctx).day == G.TheWorld.state.cycles + 1)
end)

test("native cooked dish is identified from the stewer state", function()
    local pot = spawn("cookpot")
    pot.components.stewer.product = "meatballs"
    local fields = Facts.common(pot, ctx)
    assert(fields.cook_product == "meatballs" and fields.process_state == "ready_to_harvest")
end)

test("original pitchfork and watering can expose agricultural modes", function()
    local fork, can, hoe = spawn("pitchfork"), spawn("wateringcan"), spawn("farm_hoe")
    assert(Actions.plan_mode(nil, fork) == "TERRAFORM")
    assert(Actions.plan_mode(nil, can) == "POUR_WATER_GROUNDTILE")
    assert(Actions.plan_mode(nil, hoe) == "TILL")
    local poop = spawn("poop")
    assert(Actions.plan_mode(poop, nil) == "DEPLOY_TILEARRIVE")
end)

test("native agricultural plan tills one explicit tile and consumes a tool use", function()
    local map, point = G.TheWorld.Map, nil
    for _, entity in pairs(G.Ents) do
        if entity.prefab == "multiplayer_portal" then
            point = entity:GetPosition()
            break
        end
    end
    assert(point)
    local x, z = map:GetTileCoordsAtPoint(point.x + 20, 0, point.z + 20)
    local before = map:GetTile(x, z)
    local px, _, pz = map:GetTileCenterPoint(point.x + 20, 0, point.z + 20)
    local function soils(remove)
        local count = 0
        for _, entity in pairs(G.Ents) do
            if entity.prefab == "farm_soil" and entity:GetDistanceSqToPoint(px, 0, pz) < 0.25 then
                count = count + 1
                if remove then
                    entity:Remove()
                end
            end
        end
        return count
    end
    soils(true)
    local fork = spawn("farm_hoe")
    viewer.components.inventory:Equip(fork)
    map:SetTile(x, z, G.WORLD_TILES.FARMING_SOIL)
    local ok, reason = pcall(function()
        local plan = { plan = { point = { x = px, y = 0, z = pz } }, action = "TILL", right = true }
        local uses = fork.components.finiteuses:GetUses()
        assert(adapter.validate(plan) == "ready" and plan.right)
        assert(plan.buffered.action == G.ACTIONS.TILL and plan.buffered:Do())
        assert(fork.components.finiteuses:GetUses() == uses - 1)
        assert(soils(false) == 1, "native action did not create exactly one soil entity")
    end)
    soils(true)
    map:SetTile(x, z, before)
    viewer.components.inventory:Unequip(G.EQUIPSLOTS.HANDS)
    assert(ok, reason)
end)

test("native container transfer frees a drying slot before hanging new meat", function()
    local rack, jerky, meat = spawn("meatrack"), spawn("meat_dried"), spawn("meat")
    rack.components.container:GiveItem(jerky, 1)
    viewer.components.inventory:GiveActiveItem(meat)
    local task = { rack = true, action = "STORE", target = rack, right = true, material = "meat" }
    assert(adapter.validate(task) == "ready" and task.action == "RUMMAGE")
    assert(task.buffered:Do(), "native opening failed")
    assert(rack.replica.container:IsOpenedBy(viewer))
    assert(adapter.validate(task) == "wait", "expected one transfer request")
    assert(viewer.components.inventory:Has("meat_dried", 1), "finished meat was not transferred")
    assert(adapter.validate(task) == "ready" and task.action == "STORE", "expected rehang action")
    assert(task.buffered:Do(), "native store failed")
    assert(rack.components.container:Has("meat", 1), "fresh meat was not stored")
    assert(viewer.components.inventory:Has("meat_dried", 1), "finished meat lost")
    rack.components.container:Close(viewer)
end)

test("drying queue leaves still-drying items untouched", function()
    local rack, meat = spawn("meatrack"), spawn("meat")
    rack.components.container:GiveItem(meat, 1)
    rack.components.container:Open(viewer)
    local task = { rack = true, action = "RUMMAGE", target = rack, right = false }
    assert(adapter.validate(task) == "done")
    assert(rack.components.container:GetItemInSlot(1) == meat)
    rack.components.container:Close(viewer)
end)

test("ordinary chests and players cannot enter rack or gifting automation", function()
    local chest, other = spawn("treasurechest"), spawn("wilson")
    assert(not Actions.accepts(viewer, "RUMMAGE", chest))
    assert(not Actions.accepts(viewer, "GIVE", other))
    assert(not Actions.accepts(viewer, "ACTIVATE", chest))
end)

test("burning native twigs remain separate", function()
    local a, b = spawn("twigs"), spawn("twigs")
    a.components.burnable:Ignite()
    local service = Items.new(cfg, {
        players = function()
            return {}
        end,
        pickup = function()
            return false
        end,
        result = function() end,
    })
    service:mark(a, "world", ctx.now)
    service:mark(b, "world", ctx.now)
    service:tick(ctx.now + 1)
    assert(a:IsValid() and b:IsValid())
    service:close()
    a.components.burnable:Extinguish()
end)

test("native bundle display respects independent content permission", function()
    local bundle, food = spawn("bundle"), spawn("carrot")
    bundle.components.unwrappable:WrapItems({ food })
    local name = Signs.image(bundle, G, { bundle_contents = false })
    assert(name == bundle.components.inventoryitem.imagename)
    assert(Signs.image(bundle, G, { bundle_contents = true }) == "carrot")
end)

test("native mount badge percentages and scale render into real Widgets", function()
    local mount = spawn("beefalo")
    local c = {
        player = viewer,
        config = cfg,
        settings = Config.settings(cfg),
        cache = require("wildwise/core/lru").new(256),
        lang = "zh",
        map = { players = {}, pairs = {}, pings = {} },
        queue = { tasks = {}, state = "idle" },
        found = {},
        selected = {},
        mount = mount,
        L = function(_, key)
            return require("wildwise/ui/strings").get(key, "zh")
        end,
    }
    c.settings.beefalo.scale = 1.25
    c.cache:set(mount, { health = 500, health_max = 1000, hunger = 100, hunger_max = 375 })
    local hud = require("wildwise/ui/hud")(c)
    local ok, reason = pcall(function()
        hud:OnUpdate()
        assert(hud.mount_health.percent == 0.5)
        assert(hud.mount_hunger.percent == 100 / 375)
        c.settings.beefalo.show_hunger = false
        hud:OnUpdate()
        assert(not hud.mount_hunger.shown)
        c.settings.beefalo.layout = "compact"
        c.settings.beefalo.background = 0
        hud:OnUpdate()
        assert(not hud.mount_health.shown and hud.mount.shown)
    end)
    hud:Kill()
    assert(ok, reason)
end)

test("native drying rack reports product and pause without advancing its timer", function()
    local rack, meat = spawn("meatrack"), spawn("meat")
    rack.components.container:GiveItem(meat, 1)
    rack.components.dryingrack:PauseDrying()
    local before = rack.components.dryingrack:GetDryingInfoSnapshot()[meat]
    local facts = Facts.common(rack, ctx)
    assert(facts.dry_product == "meat_dried" and facts.process_state == "paused")
    assert(rack.components.dryingrack:GetDryingInfoSnapshot()[meat] == before)
end)

test("native seasoned food preserves the dish and spice drawable layers", function()
    local food = spawn("meatballs_spice_chili")
    local name, atlas, background, bgatlas = Signs.image(food, G)
    assert(name == "spice_chili_over" and background == "meatballs")
    assert(type(atlas) == "string" and type(bgatlas) == "string")
end)

test("native map wheel keeps its opening coordinates and deletes only own ping", function()
    local Screen = require("widgets/screen")
    local screen = Screen("WildwiseMapFixture")
    local x, z, requests = 10, 20, {}
    screen.GetWorldPositionAtCursor = function()
        return x, 0, z
    end
    screen.OnUpdate, screen.OnDestroy = function() end, function() end
    screen.OnControl = function()
        return false
    end
    local proxy = setmetatable(
        { TheInput = {
            IsKeyDown = function()
                return true
            end,
        } },
        { __index = G }
    )
    local c = {
        player = viewer,
        config = cfg,
        settings = Config.settings(cfg),
        map = { pings = {} },
        L = function(_, key)
            return key
        end,
        set = function(self, key, value)
            Config.set(self.settings, key, value)
        end,
        send = function(_, kind, _, data)
            requests[#requests + 1] = { kind = kind, data = data }
        end,
    }
    local scope = require("wildwise/ui/map").attach(screen, c, proxy)
    local ok, reason = pcall(function()
        screen:OnControl(G.CONTROL_PRIMARY, true)
        assert(scope.wheel.shown and #requests == 0)
        x, z = 100, 200
        scope.wheel.buttons[2].onclick()
        assert(not scope.wheel.shown and requests[1].data.x == 10 and requests[1].data.z == 20)
        assert(requests[1].data.kind == "danger" and c.settings.map.ping_kind == "danger")
        c.map.pings =
            { { id = 1, x = 100, z = 200, owner = "other" }, { id = 2, x = 101, z = 200, owner = viewer.userid } }
        screen:OnControl(G.CONTROL_SECONDARY, true)
        assert(requests[2].kind == "delete_ping" and requests[2].data.id == 2)
        screen:OnControl(G.CONTROL_PRIMARY, true)
        screen:OnControl(G.CONTROL_CANCEL, false)
        assert(not scope.wheel.shown and #requests == 2)
    end)
    scope:close()
    screen:Kill()
    assert(ok, reason)
end)

test("sign display RPC enforces distance and supported container type", function()
    local world = G.TheWorld.components.wildwise_world
    world:AddPlayer(viewer)
    local state = world.players[viewer]
    local chest, wrong = spawn("treasurechest"), spawn("cookpot")
    local function toggle(target)
        local bytes =
            require("wildwise/core/protocol").encode(require("json"), "toggle_sign", state.session, state.seq + 1, {})
        world:Request(viewer, target, bytes)
    end
    toggle(chest)
    assert(chest._wildwise_sign_hidden == true)
    chest.Transform:SetPosition(100, 0, 0)
    toggle(chest)
    assert(chest._wildwise_sign_hidden == true)
    toggle(wrong)
    assert(not wrong._wildwise_sign_hidden)
    chest.Transform:SetPosition(0, 0, 0)
    toggle(chest)
    assert(chest._wildwise_sign_hidden == false)
end)

G.ThePlayer = old_player
for i = #cleanup, 1, -1 do
    if cleanup[i]:IsValid() then
        cleanup[i]:Remove()
    end
end
print(
    string.format(
        "[WW3_ENGINE_RESULT] passed=%d failed=%d build=%s no_graphics=true no_remote_players=true",
        passed,
        failed,
        tostring(G.APP_VERSION)
    )
)
