local Context = require("wildwise/runtime/context")
local Config = require("wildwise/core/config")
local Lifetime = require("wildwise/core/lifetime")
local Hooks = require("wildwise/core/hooks")
local U = require("wildwise/core/util")
local M = {}
function M.register(api, G, config)
    Context.G, Context.config, Context.api = G, config, api
    Context.conflicts = Config.compat(config, G.KnownModIndex:GetModsToLoad())
    local function server() return G.TheWorld and G.TheWorld.components.wildwise_world end
    api.AddPrefabPostInit("world", function(inst)
        if inst.ismastersim then inst:AddComponent("wildwise_world") end
    end)
    api.AddModRPCHandler("wildwise", "request", function(player, target, bytes)
        local service = server(); if service then service:Request(player, target, bytes) end
    end)
    api.AddClientModRPCHandler("wildwise", "message", function(target, bytes)
        if Context.client then Context.client:receive(target, bytes) end
    end)
    api.AddClientModRPCHandler("wildwise", "redirect", function(old, surviving, outcome)
        if Context.client then Context.client.queue:redirect(old, outcome, surviving) end
    end)
    api.AddShardModRPCHandler("wildwise", "presence", function(shard, bytes)
        local service = server(); if service then service:ShardPresence(shard, bytes) end
    end)
    api.AddPlayerPostInit(function(inst)
        if G.TheWorld.ismastersim then inst:DoTaskInTime(0, function() local s = server(); if s then s:AddPlayer(inst) end end) end
    end)
    if config.items.enabled then
        api.AddComponentPostInit("inventoryitem", function(component)
            if not G.TheWorld.ismastersim then return end
            local inst, scope = component.inst, Lifetime.new()
            local function mark(source)
                local s = server(); if s and s.items then s.items:mark(inst, source, G.GetTime()) end
            end
            scope:listen(inst, "on_loot_dropped", function() mark("world") end)
            scope:listen(inst, "stopfalling", function()
                local s = server()
                -- 落地事件晚于主动丢弃；已有来源不可被覆盖成自然掉落。
                if s and s.items and not s.items.known[inst] then mark("world") end
            end)
            scope:listen(inst, "onputininventory", function()
                local s = server(); if s and s.items then s.items:forget(inst) end
            end)
            scope:listen(inst, "on_landed", function()
                local s = server(); if s and s.items and s.items.known[inst] then s.items:enqueue(inst, G.GetTime() + .25) end
            end)
            scope:listen(inst, "onremove", function()
                local s = server(); if s and s.items then s.items:forget(inst) end
                scope:close()
            end)
            if config.items.stack_loaded then inst:DoTaskInTime(0, function()
                if not component.owner then mark("loaded") end
            end) end
        end)
        api.AddComponentPostInit("inventory", function(component)
            if not G.TheWorld.ismastersim then return end
            local scope = Lifetime.new()
            scope:listen(component.inst, "onremove", function() scope:close() end)
            Hooks.after(scope, component, "DropItem", function(result)
                local s, item = server(), result[1]
                if s and s.items and U.valid(item) then s.items:mark(item, "manual", G.GetTime()) end
            end)
        end)
    end
    if config.signs.enabled then
        local Signs = require("wildwise/services/signs")
        for prefab in pairs(Signs.supported) do
            -- 关闭类型在注册阶段退出，避免为宠物或冷藏容器创建无用监听／辅助实体。
            -- 辅助牌本身不持久化，修改配置并重启世界后不会留下旧牌。
            if Signs.enabled(prefab, config.signs) then
                api.AddPrefabPostInit(prefab, function(inst)
                    if G.TheWorld.ismastersim then require("wildwise/runtime/signs").attach(inst, G) end
                end)
            end
        end
    end
    if config.map.enabled and config.map.wormholes ~= false then
        -- 只处理有双向 target 的原版设施；不会把洞穴出入口当普通虫洞。
        for _, prefab in ipairs({ "wormhole", "tentacle_pillar", "wormhole_limited_1" }) do
            api.AddPrefabPostInit(prefab, function(inst)
                if not G.TheWorld.ismastersim then return end
                local scope = Lifetime.new()
                inst:DoTaskInTime(0, function()
                    local teleporter = inst.components.teleporter
                    if not teleporter then return end
                    local world = server(); if world then world:RegisterPortal(inst) end
                    Hooks.after(scope, teleporter, "Activate", function(result, _, doer)
                        if result[1] and doer and doer.userid then
                            local s = server(); if s then s:DiscoverPair(doer, inst, teleporter.targetTeleporter) end
                        end
                    end)
                end)
                scope:listen(inst, "onremove", function() scope:close() end)
            end)
        end
    end
    if config.map.enabled then
        for _, prefab in ipairs({ "campfire", "firepit", "coldfire", "coldfirepit" }) do
            api.AddPrefabPostInit(prefab, function(inst)
                if not G.TheWorld.ismastersim or not inst.components.fueled then return end
                local scope = Lifetime.new()
                scope:listen(inst, "onremove", function() scope:close() end)
                Hooks.wrap(scope, inst.components.fueled, "TakeFuelItem", function(original, component, item, ...)
                    local charcoal = U.valid(item) and item.prefab == "charcoal"
                    local result = U.pack(original(component, item, ...))
                    if charcoal and result[1] then local s = server(); if s then s.fires[inst] = true end end
                    return unpack(result, 1, result.n)
                end)
            end)
        end
        api.AddComponentPostInit("maprevealer", function(component)
            if not G.TheWorld.ismastersim then return end
            local scope = Lifetime.new()
            scope:listen(component.inst, "onremove", function() scope:close() end)
            Hooks.after(scope, component, "RevealMapToPlayer", function(_, _, player)
                local s = server()
                if s and player and player.userid and not s.map.load_error then
                    local _, enabled = Config.share(config, G.TheNet:GetServerGameMode(), G.TheNet:GetPVPEnabled())
                    if enabled and s.map:preferences_for(player.userid).exploration
                        and player._PostActivateHandshakeState_Server == G.POSTACTIVATEHANDSHAKE.READY
                        and player:CanSeePointOnMiniMap(component.inst.Transform:GetWorldPosition()) then
                        local x, _, z = component.inst.Transform:GetWorldPosition(); s.map:record_exploration(x, z)
                    end
                end
            end)
        end)
    end
    if not G.TheNet:IsDedicated() then require("wildwise/runtime/client").register(api, G, config) end
end
return M
