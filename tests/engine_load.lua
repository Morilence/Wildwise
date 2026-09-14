-- 开发专服负载探针：统计 Wildwise 世界 Tick 的 CPU 时间，不代表全游戏逻辑帧或客户端帧率。
-- 在隔离存档控制台 dofile，约 60 秒结束；不会随模组启动运行，也不进入发布包。
local G = _G
local world = assert(G.TheWorld.components.wildwise_world)
assert(world.items and os.clock)
local original, samples, entities = world.Tick, {}, {}
world.Tick = function(self, ...)
    local before = os.clock()
    local result = original(self, ...)
    samples[#samples + 1] = (os.clock() - before) * 1000
    return result
end
local portal
for _, e in pairs(G.Ents) do
    if e.prefab == "multiplayer_portal" then
        portal = e
        break
    end
end
local point = portal:GetPosition()
local counts, next_scene = { 100, 500, 1000 }, 1
local function run()
    local n = counts[next_scene]
    if not n then
        world.Tick = original
        print("[WW_LOAD_COMPLETE]")
        return
    end
    samples, entities = {}, {}
    local begin = G.GetTime()
    for _ = 1, n do
        local e = G.SpawnPrefab("flint")
        -- 控制场景仅改变数量：已落地的原版实体，同点集中掉落；不计 worldgen 或生成开销。
        e.Transform:SetPosition(point.x + 35, 0, point.z - 35)
        e.Physics:Stop()
        e.components.inventoryitem:SetLanded(true)
        e:PushEvent("on_loot_dropped")
        entities[#entities + 1] = e
    end
    G.TheWorld:DoTaskInTime(20, function()
        table.sort(samples)
        local function percentile(q)
            return samples[math.max(1, math.ceil(#samples * q))] or 0
        end
        local total, stacks = 0, 0
        for _, e in ipairs(entities) do
            if e:IsValid() then
                total = total + e.components.stackable:StackSize()
                stacks = stacks + 1
                e:Remove()
            end
        end
        print(
            string.format(
                "[WW_LOAD] count=%d conserved=%s stacks=%d samples=%d p50_ms=%.4f p95_ms=%.4f p99_ms=%.4f elapsed=%.2f pending=%d",
                n,
                tostring(total == n),
                stacks,
                #samples,
                percentile(0.5),
                percentile(0.95),
                percentile(0.99),
                G.GetTime() - begin,
                world.items.tail - world.items.head + 1
            )
        )
        next_scene = next_scene + 1
        run()
    end)
end
run()
