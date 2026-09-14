-- 仅在隔离专服控制台执行：dofile('../mods/Wildwise/tests/engine_signs_smoke.lua')()
-- 第二轮可传入覆盖后的预期类型表。验证真实辅助实体及 drawable 数据，不验证贴图外观。
local G = _G
return function(overrides)
    local expected = { treasurechest = true, dragonflychest = true, boat_ancient_container = true,
        chester = false, hutch = false, icebox = false, saltbox = false, fish_box = false }
    for prefab, enabled in pairs(overrides or {}) do expected[prefab] = enabled end
    local created, records, passed, failed = {}, {}, 0, 0
    local function result(prefab, ok, message)
        if ok then passed = passed + 1; print("[WW_SIGN_PASS] " .. prefab .. " expected=" .. tostring(expected[prefab]))
        else failed = failed + 1; print("[WW_SIGN_FAIL] " .. prefab .. " " .. tostring(message)) end
    end
    for prefab in pairs(expected) do
        local ok, message = pcall(function()
            local container = assert(G.SpawnPrefab(prefab), "missing container")
            created[#created + 1] = container
            local item = assert(G.SpawnPrefab(prefab == "fish_box" and "oceanfish_medium_1_inv" or "meat"))
            created[#created + 1] = item
            assert(container.components.container, "missing container component")
            container.components.container:GiveItem(item, 1)
            assert(container.components.container:GetItemInSlot(1) == item, "fixture item was rejected")
            records[prefab] = { container = container, item = item }
        end)
        if not ok then result(prefab, false, message) end
    end
    -- 模组将库存变化合并到下一帧；等待任务执行后再检查，不能只验证配置表本身。
    G.TheWorld:DoTaskInTime(1, function()
        for prefab, record in pairs(records) do
            local ok, message = pcall(function()
                local sign
                for _, entity in pairs(G.Ents) do
                    if entity.prefab == "minisign" and entity.entity:GetParent() == record.container and not entity.persists then
                        assert(not sign, "duplicate helper signs"); sign = entity
                    end
                end
                assert((sign ~= nil) == expected[prefab], "helper sign presence does not match type switch")
                if sign then assert(sign.components.drawable:GetImage() == record.item.prefab, "wrong inventory icon") end
            end)
            result(prefab, ok, message)
        end
        for _, entity in ipairs(created) do if entity:IsValid() then entity:Remove() end end
        print(string.format("[WW_SIGN_RESULT] passed=%d failed=%d build=%s", passed, failed, tostring(G.APP_VERSION)))
    end)
end
