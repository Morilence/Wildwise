local Config = require("wildwise/core/config")
-- 仅由开发者在隔离专服控制台 dofile；不会随模组启动运行，也不会进入发布包。
-- 这些断言使用真实原版实体与组件，不把本测试称作远程客户端/双人验收。
local G = _G
local failures, passes, cleanup = 0, 0, {}
local function test(name_, fn)
    local ok, message = pcall(fn)
    if ok then passes = passes + 1; print("[WW_ENGINE_PASS] " .. name_)
    else failures = failures + 1; print("[WW_ENGINE_FAIL] " .. name_ .. " " .. tostring(message)) end
end
local function spawn(prefab, dx, dz)
    local e = G.SpawnPrefab(prefab); assert(e, "missing prefab " .. prefab)
    local portal
    for _, candidate in pairs(G.Ents) do if candidate.prefab == "multiplayer_portal" then portal = candidate; break end end
    assert(portal, "test world has no portal")
    local x, _, z = portal.Transform:GetWorldPosition()
    e.Transform:SetPosition(x + (dx or 0), 0, z + (dz or 0))
    if e.Physics then e.Physics:Stop() end
    if e.components.inventoryitem then e.components.inventoryitem:SetLanded(true) end
    cleanup[#cleanup + 1] = e
    return e
end
local context = require("wildwise/runtime/context")
local Facts = require("wildwise/services/facts")
local Signs = require("wildwise/services/signs")
local Observer = require("wildwise/services/observer")
local world = G.TheWorld.components.wildwise_world
test("world service loaded on dedicated server", function() assert(world and G.TheNet:IsDedicated()) end)
test("server does not load UI", function() assert(context.client == nil) end)
local viewer = spawn("wilson", 6, 0)
-- 存档可能已进入夜晚；用原版夜视能力固定可见性前提，不放宽生产服务的权限判断。
viewer.components.playervision:ForceNightVision(true)
local ctx = { G = G, config = Config.copy(context.config), cooking = require("cooking"), now = G.GetTime() }
for _, prefab in ipairs({ "beefalo", "berries", "axe", "armorwood", "strawhat", "icebox", "farm_plant_carrot",
    "meatballs", "raincoat", "lantern", "pigman", "firepit", "saddle_basic", "rope", "bundle" }) do
    test("facts:" .. prefab, function()
        local e = spawn(prefab, 10, 0)
        local fields = Facts.common(e, ctx)
        local personal = Facts.viewer(e, viewer, ctx)
        assert(type(fields) == "table" and type(personal) == "table")
    end)
end
test("food estimates match actual engine eating", function()
    local food = spawn("berries", 8, 1)
    viewer.components.health:SetPercent(.5); viewer.components.hunger:SetPercent(.5); viewer.components.sanity:SetPercent(.5)
    local expected = Facts.viewer(food, viewer, ctx)
    local health, hunger, sanity = viewer.components.health.currenthealth, viewer.components.hunger.current, viewer.components.sanity.current
    assert(viewer.components.eater:Eat(food))
    assert(math.abs(viewer.components.health.currenthealth - health - expected.food_health) < .05)
    assert(math.abs(viewer.components.hunger.current - hunger - expected.food_hunger) < .05)
    assert(math.abs(viewer.components.sanity.current - sanity - expected.food_sanity) < .05)
end)
test("native stack count conservation", function()
    local a, b = spawn("twigs", 15, 0), spawn("twigs", 16, 0)
    a.components.stackable:SetStackSize(5); b.components.stackable:SetStackSize(7)
    world.items:mark(a, "world", G.GetTime()); world.items:mark(b, "world", G.GetTime())
    world.items:process(a, G.GetTime() + 1); world.items:process(b, G.GetTime() + 1)
    assert(a.components.stackable:StackSize() == 12 and not b:IsValid())
end)
test("manual and unknown items protected as merge targets", function()
    local a, b = spawn("rocks", 22, 0), spawn("rocks", 23, 0)
    world.items:mark(a, "manual", G.GetTime()); world.items:mark(b, "world", G.GetTime())
    world.items:process(a, G.GetTime() + 1); world.items:process(b, G.GetTime() + 1)
    assert(a:IsValid() and b:IsValid() and a.components.stackable:StackSize() == 1)
end)
test("native icon resolves without copying assets", function()
    local food = spawn("berries", 0, 5)
    local name_, atlas = Signs.image(food, G)
    assert(name_ == "berries" and atlas)
    local sign = spawn("minisign", 0, 6)
    sign.components.drawable:OnDrawn(name_, nil, atlas)
    assert(sign.components.drawable:GetImage() == "berries")
end)
test("observer healthdelta produces delta and releases listeners", function()
    local pig, sent = spawn("pigman", 7, 0), {}
    local observer = Observer.new(ctx, function(_, _, kind, data) sent[#sent + 1] = { kind = kind, data = data } end)
    assert(observer:subscribe(viewer, pig, "hover", G.GetTime()))
    observer:tick(G.GetTime()); assert(sent[1].kind == "snapshot")
    pig.components.health:DoDelta(-10)
    observer:tick(G.GetTime() + .1); assert(sent[2].kind == "delta")
    observer:forget(viewer); assert(next(observer.entities) == nil); observer:close()
end)
test("native MapExplorer isolation", function()
    local entity = G.CreateEntity(); cleanup[#cleanup + 1] = entity
    entity.entity:AddTransform(); entity.entity:AddMapExplorer()
    entity.MapExplorer:RevealArea(viewer.Transform:GetWorldPosition())
    local recorded = entity.MapExplorer:RecordMap()
    assert(type(recorded) == "string", "dedicated explorer failed")
end)
test("persistent map round trip", function()
    local Map = require("wildwise/services/map")
    local map = Map.new("test"); local id = map:discover("tester", { key = "a", x = 1, z = 2 }, { key = "b", x = 3, z = 4 }, false)
    local restored = Map.new("test"); assert(restored:load(map:save()))
    assert(restored:visible_pairs("tester", false)[1].id == id)
end)
test("native partial inventory pickup preserves leftover stack", function()
    local receiver = spawn("wilson", 60, 0)
    local inv = receiver.components.inventory
    for slot = 1, inv.maxslots do
        local item = spawn(slot == 1 and "flint" or "rocks", 60, 0)
        item.components.stackable:SetStackSize(slot == 1 and 38 or item.components.stackable.maxsize)
        assert(inv:GiveItem(item, slot))
    end
    local item = spawn("flint", 61, 0); item.components.stackable:SetStackSize(5)
    local cfg = Config.copy(context.config); cfg.items.pickup_allowed = true
    local service = require("wildwise/services/items").new(cfg, {
        players = function() return { receiver } end, pickup = function() return true end,
        neighbors = function() return {} end, result = function() end,
    })
    service:mark(item, "world", G.GetTime()); service:process(item, G.GetTime() + 1)
    assert(inv:GetItemInSlot(1).components.stackable:StackSize() == 40)
    assert(item:IsValid() and not item.components.inventoryitem.owner and item.components.stackable:StackSize() == 3)
    service:close()
end)
test("native mount facts follow saddle and obedience values", function()
    local cow, saddle = spawn("beefalo", 65, 0), spawn("saddle_basic", 65, 0)
    cow.components.rideable:SetSaddleable(true); cow.components.rideable:SetSaddle(viewer, saddle)
    cow.components.domesticatable:DeltaObedience(.75 - cow.components.domesticatable:GetObedience())
    viewer.components.rider:Mount(cow, true)
    assert(viewer.components.rider:GetMount() == cow)
    local fields = Facts.common(cow, ctx)
    assert(fields.ride_time and fields.ride_time > 0)
    cow.components.domesticatable:DeltaObedience(.1)
    local renewed = Facts.common(cow, ctx)
    assert(math.abs(renewed.ride_time - G.GetTaskRemaining(cow._bucktask)) < .02)
    viewer.components.rider:Dismount()
    assert(fields.obedience == 75 and fields.saddle_uses == saddle.components.finiteuses:GetUses())
end)
for _, entity in ipairs(cleanup) do if entity:IsValid() then entity:Remove() end end
print(string.format("[WW_ENGINE_RESULT] passed=%d failed=%d build=%s", passes, failures, tostring(G.APP_VERSION)))
