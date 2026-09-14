-- 仅用于隔离专服；真实组件回归，不代表远程联机或图形验收。
local G = _G
local Context = require("wildwise/runtime/context")
local Facts = require("wildwise/services/facts")
local Actions = require("wildwise/runtime/actions")
local Signs = require("wildwise/runtime/signs")
local Observer = require("wildwise/services/observer")
local passed, failed, cleanup = 0, 0, {}
local function test(label, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print("[WW_REG_PASS] " .. label)
    else
        failed = failed + 1
        print("[WW_REG_FAIL] " .. label .. " " .. tostring(err))
    end
end
local function spawn(prefab)
    local entity = assert(G.SpawnPrefab(prefab), prefab)
    cleanup[#cleanup + 1] = entity
    entity.Transform:SetPosition(0, 0, 0)
    if entity.Physics then
        entity.Physics:Stop()
    end
    return entity
end
local ctx = { G = G, config = Context.config, cooking = require("cooking"), now = G.GetTime() }
local viewer = spawn("wilson")
viewer.components.playervision:ForceNightVision(true)
-- 没有远程客户端的专服角色不自动带本地动作选择器；这里显式挂原版组件用于合约测试。
viewer:AddComponent("playeractionpicker")
viewer:AddComponent("playercontroller")

test("WW-B01 Woby and missing mount are safe", function()
    local woby = spawn("wobybig")
    assert(Facts.common(woby, ctx).domestication == nil)
    assert(viewer.components.rider:GetMount() == nil)
    assert(Facts.viewer(viewer, viewer, ctx))
end)

test("WW-X02 beefalo and information readers preserve native player state", function()
    local beefalo, food = spawn("beefalo"), spawn("berries")
    local c = viewer.components
    local hp, hunger, sanity, temperature =
        c.health.currenthealth, c.hunger.current, c.sanity.current, c.temperature.current
    local eater, damage = c.eater.Eat, c.combat.defaultdamage
    for _ = 1, 20 do
        Facts.common(beefalo, ctx)
        Facts.viewer(food, viewer, ctx)
        Facts.health(viewer, ctx)
    end
    assert(c.health.currenthealth == hp and c.hunger.current == hunger and c.sanity.current == sanity)
    assert(c.temperature.current == temperature and c.eater.Eat == eater and c.combat.defaultdamage == damage)
end)

test("WW-O05 new dryingrack snapshot and queue do not toggle container", function()
    local rack, meat = spawn("meatrack"), spawn("meat")
    assert(rack.components.dryingrack and rack.components.container)
    assert(rack.components.container:GiveItem(meat, 1))
    local fields = Facts.common(rack, ctx)
    assert(fields.dry_time and fields.dry_time > 0)
    local choices = viewer.components.playeractionpicker:GetLeftClickActions(rack:GetPosition(), rack)
    local rummage = false
    for _, action in ipairs(choices) do
        if action.action.id == "RUMMAGE" then
            rummage = true
        end
    end
    assert(rummage, "native rack action changed")
    assert(Actions.pick(viewer, rack, rack:GetPosition(), false) == nil, "queue must not loop RUMMAGE")
end)

test("WW-H01 removing a parasite target releases combined subscriptions", function()
    local target, sent = spawn("shadowthrall_parasite"), 0
    local observer = Observer.new(ctx, function()
        sent = sent + 1
    end)
    assert(observer:subscribe(viewer, target, "health", G.GetTime()))
    observer:tick(G.GetTime())
    target:Remove()
    assert(next(observer.entities) == nil and sent >= 1)
    observer:close()
end)

test("WW-M04 reciprocal wormholes work independently of forest-only components", function()
    local a, b = spawn("wormhole"), spawn("wormhole")
    b.Transform:SetPosition(5, 0, 0)
    a.components.teleporter:Target(b)
    b.components.teleporter:Target(a)
    local world = G.TheWorld.components.wildwise_world
    local old_userid = viewer.userid
    viewer.userid = "wildwise-regression"
    world:DiscoverPair(viewer, a, b)
    local pairs_ = world.map:visible_pairs(viewer.userid, false)
    assert(#pairs_ > 0)
    world.map:remove_pair(pairs_[#pairs_].id)
    world.map.discoveries[viewer.userid] = nil
    viewer.userid = old_userid
end)

local chest, berry = spawn("treasurechest"), spawn("berries")
chest.components.container:GiveItem(berry, 1)
local scope = Signs.attach(chest, G)
test("WW-S02 repeated attachment shares one lifetime", function()
    assert(Signs.attach(chest, G) == scope)
end)

local function sign_for()
    for _, entity in pairs(G.Ents) do
        if entity.prefab == "minisign" and entity.entity:GetParent() == chest then
            return entity
        end
    end
end

G.TheWorld:DoTaskInTime(0.2, function()
    test("WW-S03 signs are decorative and do not own item actions", function()
        local sign = assert(sign_for())
        assert(sign:HasTag("NOCLICK") and sign:HasTag("FX") and not sign.persists)
        assert(not sign.components.workable and not sign.components.lootdropper)
        assert(sign.components.drawable:GetImage() == "berries")
        berry.components.inventoryitem:ChangeImageName("berries_cooked")
    end)
    G.TheWorld:DoTaskInTime(0.2, function()
        test("WW-S04 first-slot imagechange refreshes without reopening chest", function()
            assert(sign_for().components.drawable:GetImage() == "berries_cooked")
            chest.components.container:RemoveItem(berry, true)
        end)
        G.TheWorld:DoTaskInTime(0.2, function()
            test("WW-S05 empty chest and teardown remove stale signs", function()
                assert(sign_for() == nil)
                chest:Remove()
                assert(scope.closed)
            end)
            for _, entity in ipairs(cleanup) do
                if entity:IsValid() then
                    entity:Remove()
                end
            end
            print(
                string.format("[WW_REG_RESULT] passed=%d failed=%d build=%s", passed, failed, tostring(G.APP_VERSION))
            )
        end)
    end)
end)
