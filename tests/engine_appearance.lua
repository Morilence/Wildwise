-- 隔离原版实体/外观生命周期。皮肤名称传参使用受控替身，不代表拥有皮肤的图形渲染验收。
local G = _G
return function()
    local Runtime = require("wildwise/runtime/signs")
    local chest, food, skin_item =
        G.SpawnPrefab("treasurechest"), G.SpawnPrefab("meatballs_spice_chili"), G.SpawnPrefab("minisign_item")
    chest.Transform:SetPosition(0, 0, 0)
    if chest._wildwise_sign_scope then
        chest._wildwise_sign_scope:close()
    end
    local spawned, passed, failed = {}, 0, 0
    local proxy = setmetatable({
        SpawnPrefab = function(prefab, skin, id)
            spawned[#spawned + 1] = { prefab = prefab, skin = skin, id = id }
            -- 只对皮肤资产入口使用替身；实体、drawable、库存事件和所有移除任务均为原版。
            return G.SpawnPrefab(prefab)
        end,
    }, { __index = G })
    local scope = Runtime.attach(chest, proxy, { scale = 0.8, body_skins = true })
    chest.components.container:GiveItem(food, 1)
    chest.components.container:GiveItem(skin_item, 2)
    local function find()
        local result
        for _, entity in pairs(G.Ents) do
            if entity.prefab == "minisign" and entity.entity:GetParent() == chest then
                assert(not result, "duplicate helper")
                result = entity
            end
        end
        return result
    end
    local function test(label, fn)
        local ok, reason = pcall(fn)
        if ok then
            passed = passed + 1
            print("[WW3_APPEARANCE_PASS] " .. label)
        else
            failed = failed + 1
            print("[WW3_APPEARANCE_FAIL] " .. label .. " " .. tostring(reason))
        end
    end
    local steps = {
        function()
            test("native spice drawing and helper scale", function()
                local sign = assert(find())
                assert(sign.components.drawable:GetImage() == "spice_chili_over")
                local x, y, z = sign.Transform:GetScale()
                assert(math.abs(x - 0.8) < 0.001 and x == y and y == z)
            end)
            skin_item.linked_skinname, skin_item.skin_id = "fixture_linked_skin", 17
            chest:PushEvent("onclose")
        end,
        function()
            test("linked skin arguments rebuild helper without duplicate entities (asset stub)", function()
                assert(find() and #spawned == 2)
                assert(spawned[2].skin == "fixture_linked_skin" and spawned[2].id == 17)
            end)
            skin_item.linked_skinname, skin_item.skin_id = nil, nil
            chest:PushEvent("onclose")
        end,
        function()
            test("removing linked skin returns helper to native default (asset stub)", function()
                assert(find() and #spawned == 3 and spawned[3].skin == nil)
            end)
            chest._wildwise_sign_hidden = true
            chest:PushEvent("wildwise_sign_refresh")
        end,
        function()
            test("per-container hide removes helper and preserves all contents", function()
                assert(not find())
                assert(chest.components.container:GetItemInSlot(1) == food)
                assert(chest.components.container:GetItemInSlot(2) == skin_item)
            end)
            chest._wildwise_sign_hidden = false
            chest:PushEvent("wildwise_sign_refresh")
        end,
        function()
            test("show recreates one helper which follows container movement", function()
                local sign = assert(find())
                chest.Transform:SetPosition(12, 0, 20)
                local x, _, z = sign.Transform:GetWorldPosition()
                assert(math.abs(x - 12) < 0.01 and math.abs(z - 20.7) < 0.01)
            end)
            chest:PushEvent("onburnt")
        end,
        function()
            test("burn event closes owned listeners and destroys the helper", function()
                assert(scope.closed and not find())
            end)
            for _, item in ipairs({ skin_item, food, chest }) do
                if item:IsValid() then
                    item:Remove()
                end
            end
            print(
                string.format(
                    "[WW3_APPEARANCE_RESULT] passed=%d failed=%d no_graphics=true skin_asset_stub=true",
                    passed,
                    failed
                )
            )
        end,
    }
    local function step(index)
        steps[index]()
        if steps[index + 1] then
            G.TheWorld:DoTaskInTime(0.2, function()
                step(index + 1)
            end)
        end
    end
    G.TheWorld:DoTaskInTime(0.2, function()
        step(1)
    end)
end
