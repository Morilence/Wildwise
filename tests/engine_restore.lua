-- 隔离专服已保存并重启、items_stack_loaded=true 后执行；使用真实恢复阶段与原版解包。
-- 普通启动不加载本文件。需在空测试服使用；结束时清除本测试生成的包裹与物品。
local G = _G
local world = assert(G.TheWorld.components.wildwise_world)
local config = require("wildwise/runtime/context").config
assert(config.items.stack_loaded, "restart the isolated server with items_stack_loaded=true")
assert(not G.POPULATING and not world.map.load_error, "world must have completed a valid reload")
local passed, failed = 0, 0

local function test(label, fn)
    local ok, reason = pcall(fn)
    if ok then
        passed = passed + 1
        print("[WW_RESTORE_PASS] " .. label)
    else
        failed = failed + 1
        print("[WW_RESTORE_FAIL] " .. label .. " " .. tostring(reason))
    end
end

test("WW-I04 saved ground items are recognized during real world population", function()
    local count = 0
    for entity, record in pairs(world.items.known) do
        if entity:IsValid() and record.source == "loaded" and not entity.components.inventoryitem.owner then
            count = count + 1
        end
    end
    assert(count > 0, "test save must contain ground inventory items")
    print("[WW_RESTORE_DATA] restored_ground_items=" .. count)
end)

local before = {}
for id in pairs(G.Ents) do
    before[id] = true
end
local bundle = assert(G.SpawnPrefab("bundle"))
bundle.components.unwrappable:WrapItems({ "flint" })
bundle.components.unwrappable:Unwrap(nil, true)
local items = {}
for id, entity in pairs(G.Ents) do
    if not before[id] and entity.prefab == "flint" then
        items[#items + 1] = entity
    end
end
G.TheWorld:DoTaskInTime(0.1, function()
    test("WW-I05 native unwrapping is not classified as world-load stacking", function()
        assert(#items == 1 and items[1]:IsValid(), "native unwrap must produce one flint")
        local record = world.items.known[items[1]]
        assert(not record or record.source ~= "loaded")
        assert(items[1].components.stackable:StackSize() == 1)
    end)
    for _, entity in ipairs(items) do
        if entity:IsValid() then
            entity:Remove()
        end
    end
    if bundle:IsValid() then
        bundle:Remove()
    end
    print(string.format("[WW_RESTORE_RESULT] passed=%d failed=%d build=%s", passed, failed, tostring(G.APP_VERSION)))
end)
