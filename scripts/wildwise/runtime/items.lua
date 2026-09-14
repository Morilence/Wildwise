local Lifetime = require("wildwise/core/lifetime")
local Hooks = require("wildwise/core/hooks")
local U = require("wildwise/core/util")
local M = {}

-- 挂接物品来源与库存事件；服务层只接收明确来源，不依赖 SpawnPrefab 的创建时机猜测。
-- 接入掉落、落地、入包和真实存档恢复事件，向物品服务报告来源。
function M.register(api, G, config, server)
    api.AddComponentPostInit("inventoryitem", function(component)
        if not G.TheWorld.ismastersim then
            return
        end
        local inst, scope = component.inst, Lifetime.new()

        local function service()
            local world = server()
            return world and world.items
        end

        local function mark(source)
            local items = service()
            if items then
                items:mark(inst, source, G.GetTime())
            end
        end
        scope:listen(inst, "on_loot_dropped", function()
            mark("world")
        end)
        scope:listen(inst, "stopfalling", function()
            local items = service()
            -- 落地通知只能补未知来源；不能覆盖主动丢弃和读档标记。
            if items and not items.known[inst] then
                mark("world")
            end
        end)
        scope:listen(inst, "onputininventory", function()
            local items = service()
            if items then
                items:forget(inst)
            end
        end)
        scope:listen(inst, "on_no_longer_landed", function()
            local items = service()
            if items then
                items:unindex(inst)
            end
        end)
        scope:listen(inst, "on_landed", function()
            local items = service()
            if items and items.known[inst] then
                items:enqueue(inst, G.GetTime() + 0.25)
            end
        end)
        scope:listen(inst, "onremove", function()
            local items = service()
            if items then
                items:forget(inst)
            end
            scope:close()
        end)
        -- 原版解包也会调用 SetPersistData，必须限定在世界 POPULATING 恢复阶段。
        -- 延后一帧等 owner 和位置恢复，并且不覆盖同期的明确掉落来源。
        if config.items.stack_loaded then
            Hooks.after(scope, inst, "SetPersistData", function()
                if not G.POPULATING then
                    return
                end
                scope:task(inst:DoTaskInTime(0, function()
                    local items = service()
                    if items and not component.owner and not items.known[inst] then
                        mark("loaded")
                    end
                end))
            end)
        end
    end)
    api.AddComponentPostInit("inventory", function(component)
        if not G.TheWorld.ismastersim then
            return
        end
        local scope = Lifetime.new()
        scope:listen(component.inst, "onremove", function()
            scope:close()
        end)
        Hooks.after(scope, component, "DropItem", function(result)
            local world, item = server(), result[1]
            if world and world.items and U.valid(item) then
                world.items:mark(item, "manual", G.GetTime())
            end
        end)
    end)
end

return M
