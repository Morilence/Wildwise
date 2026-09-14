-- 隔离测试存档的真实异步掉落：必须等原版弹跳、落地事件完成后检查。
local G = _G
local world = G.TheWorld.components.wildwise_world
assert(world and world.items, "enable Wildwise item service first")
local portal
for _, e in pairs(G.Ents) do
    if e.prefab == "multiplayer_portal" then
        portal = e
        break
    end
end
local origin = portal:GetPosition()
local pig = G.SpawnPrefab("pigman")
pig.Transform:SetPosition(origin.x + 30, 0, origin.z + 30)
local a = pig.components.lootdropper:SpawnLootPrefab("flint")
local b = pig.components.lootdropper:SpawnLootPrefab("flint")
local player = G.SpawnPrefab("wilson")
player.Transform:SetPosition(origin.x + 45, 0, origin.z + 30)
local manual = G.SpawnPrefab("flint")
player.components.inventory:GiveItem(manual)
manual = player.components.inventory:DropItem(manual, true, true)
local expected = world.items.known[manual] and world.items.known[manual].source
local tree = G.SpawnPrefab("twiggytree")
tree.Transform:SetPosition(origin.x + 60, 0, origin.z + 60)
local twig_a = tree.components.lootdropper:SpawnLootPrefab("twigs")
local twig_b = tree.components.lootdropper:SpawnLootPrefab("twigs")
G.TheWorld:DoTaskInTime(6, function()
    local passed, failed = 0, 0
    local function test(name_, fn)
        local ok, message = pcall(fn)
        if ok then
            passed = passed + 1
            print("[WW_EVENT_PASS] " .. name_)
        else
            failed = failed + 1
            print("[WW_EVENT_FAIL] " .. name_ .. " " .. tostring(message))
        end
    end
    test("real lootdropper events land and merge with count conservation", function()
        local count = (a:IsValid() and a.components.stackable:StackSize() or 0)
            + (b:IsValid() and b.components.stackable:StackSize() or 0)
        assert(count == 2)
        assert(a:IsValid() ~= b:IsValid(), "drops have not merged")
    end)
    test("manual DropItem remains protected after landing", function()
        assert(expected == "manual" and manual:IsValid())
        assert(world.items.known[manual].source == "manual")
        assert(not world.items:eligible(manual, G.GetTime()))
    end)
    test("twiggy tree's real landed drops preserve the native entity count", function()
        assert(tree.build == "twiggy" and world.items.env.near_twiggy(twig_a))
        assert(twig_a:IsValid() and twig_b:IsValid())
        assert(twig_a.components.stackable:StackSize() == 1 and twig_b.components.stackable:StackSize() == 1)
        assert(not world.items:operation_allowed(twig_a, "stack", G.GetTime()))
    end)
    for _, e in ipairs({ a, b, manual, pig, player, twig_a, twig_b, tree }) do
        if e:IsValid() then
            e:Remove()
        end
    end
    print(string.format("[WW_EVENT_RESULT] passed=%d failed=%d build=%s", passed, failed, tostring(G.APP_VERSION)))
end)
