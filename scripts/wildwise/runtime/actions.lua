local U = require("wildwise/core/util")
local Planner = require("wildwise/services/planner")
local M = {}
-- 显式白名单：采集、农业和设施操作可排队，ATTACK/CASTSPELL 等战斗决策不会自动执行。
M.allowed = {}
for _, id in ipairs({
    "PICKUP",
    "PICK",
    "HARVEST",
    "CHOP",
    "MINE",
    "DIG",
    "HAMMER",
    "NET",
    "TILL",
    "PLANT",
    "PLANTSOIL",
    "POUR_WATER",
    "POUR_WATER_GROUNDTILE",
    "FERTILIZE",
    "INTERACT_WITH",
    "ADDWETFUEL",
    "ADDFUEL",
    "GIVE",
    "FEED",
    "HEAL",
    "STORE",
    "TAKEITEM",
    "DEPLOY",
    "DEPLOY_TILEARRIVE",
    "TERRAFORM",
    "DRY",
    "REPAIR",
    "RESETMINE",
    "CHECKTRAP",
    "ACTIVATE",
    "LOWER_SAIL",
    "RAISE_SAIL",
    "LOWER_ANCHOR",
    "RAISE_ANCHOR",
    "COOK",
    "FILL",
    "FILL_OCEAN",
    "SEW",
    "SCYTHE",
    "CAST_NET",
    "REPAIR_LEAK",
    "PLANTREGISTRY_RESEARCH",
    "RUMMAGE",
    "ADDCOMPOSTABLE",
    "EMPTY_CONTAINER",
    "PICKUP_CHESTER",
    "DRAW",
}) do
    M.allowed[id] = true
end
M.repeated = { CHOP = true, MINE = true, HAMMER = true, DIG = true }
local tools = {
    CHOP = "CHOP_tool",
    MINE = "MINE_tool",
    HAMMER = "HAMMER_tool",
    DIG = "DIG_tool",
    NET = "NET_tool",
    TILL = "TILL_tool",
    TERRAFORM = "terraformer",
    POUR_WATER_GROUNDTILE = "wateringcan",
    SCYTHE = "SCYTHE_tool",
}

M.racks = { meatrack = true, meatrack_hermit = true, meatrack_hermit_multi = true }

function M.tool(item, id)
    if not U.valid(item) then
        return false
    end
    if id == "TERRAFORM" then
        return item.prefab == "pitchfork" or item.prefab == "goldenpitchfork"
    end
    if id == "TILL" and item.HasActionComponent then
        return item:HasActionComponent("farmtiller")
    end
    return tools[id] ~= nil and item:HasTag(tools[id])
end

function M.plan_mode(active, tool)
    if active then
        return active:HasTag("tile_deploy") and "DEPLOY_TILEARRIVE" or "DEPLOY"
    end
    for _, id in ipairs({ "TILL", "TERRAFORM", "POUR_WATER_GROUNDTILE" }) do
        if M.tool(tool, id) then
            return id
        end
    end
end

function M.plan_valid(id, point, player, active, G)
    if not point then
        return false
    end
    local map = G.TheWorld.Map
    if id == "TILL" then
        return map:CanTillSoilAtPoint(point.x, 0, point.z)
    end
    if id == "TERRAFORM" then
        return map:CanTerraformAtPoint(point.x, 0, point.z)
    end
    if id == "POUR_WATER_GROUNDTILE" then
        return map:IsFarmableSoilAtPoint(point.x, 0, point.z)
    end
    local inv = U.valid(active) and active.replica.inventoryitem
    return inv and inv:CanDeploy(G.Vector3(point.x, 0, point.z), nil, player) or false
end

-- 目标级约束复用于选取和执行，不把玩家、传送器、火焰或任意容器当作批量任务。
function M.accepts(player, id, target)
    if not M.allowed[id] then
        return false
    end
    if target and (not U.valid(target) or target:HasTag("INLIMBO") or target:HasTag("playerghost")) then
        return false
    end
    if target and target:HasTag("player") and not (id == "HEAL" and target == player) then
        return false
    end
    if id == "ACTIVATE" then
        return target ~= nil and target.prefab == "dirtpile"
    end
    if id == "RUMMAGE" then
        return target ~= nil and M.racks[target.prefab] == true
    end
    if id == "STORE" then
        return target ~= nil and (M.racks[target.prefab] or target:HasTag("_container")) == true
    end
    if id == "PICKUP" and target then
        local c = target.components or {}
        return not (
            target:HasTag("fire")
            or target:HasTag("no_autopickup")
            or target:HasTag("penguin_egg")
            or target:HasTag("heavy")
            or (c.bait and c.bait.trap)
            or U.call(c.burnable, "IsBurning")
        )
    end
    return true
end

-- 从原版动作选择器中选取白名单动作；不推断或生成战斗动作。
function M.pick(player, target, point, right, wanted)
    local picker = player.components.playeractionpicker
    if not picker then
        return
    end
    local choices = right and picker:GetRightClickActions(point, target) or picker:GetLeftClickActions(point, target)
    for _, action in ipairs(choices or {}) do
        if (not wanted or action.action.id == wanted) and M.accepts(player, action.action.id, target) then
            return action
        end
    end
end

-- 创建队列的原版动作适配器；每次仅观察当前提交动作。
function M.create(client, G)
    local player = client.player
    local pending, native_recipe = {}, nil
    local adapter = {}

    -- 检查角色、连接与输入焦点，返回能否继续及暂停原因。
    function adapter.ready()
        if not U.valid(player) or player:HasTag("playerghost") then
            return false, "death"
        end
        if not client.session then
            return false, "disconnected"
        end
        if not client:input_ready() then
            return false, "input_focus"
        end
        return true
    end

    -- 取消本适配器拥有的动作和预测回调，归还玩家控制。
    function adapter.cancel()
        pending = {}
        local pc = player.components.playercontroller
        if pc then
            if pc.locomotor then
                pc.locomotor:Stop()
            end
            if pc.ismastersim then
                player:ClearBufferedAction()
            else
                -- 原版移动 RPC 接管角色，取消服务器上已进入寻路/预览的动作。
                local x, _, z = player.Transform:GetWorldPosition()
                local platform, px, pz = pc:GetPlatformRelativePosition(x, z)
                G.SendRPCToServer(
                    G.RPC.LeftClick,
                    G.ACTIONS.WALKTO.code,
                    px,
                    pz,
                    nil,
                    true,
                    0,
                    nil,
                    nil,
                    platform,
                    platform ~= nil
                )
            end
        end
    end

    -- 释放服务器预留并清空迟到回调，防止影响下一项任务。
    function adapter.release()
        pending = {}
        client:send("release", nil, {})
    end

    -- 续租当前动作观察，并以实际位移判断寻路进展。
    function adapter.progress()
        -- 长距离寻路可能超过初始观察租约；续租只观察当前动作，不另起执行器。
        for token, record in pairs(pending) do
            if G.GetTime() >= record.watch_at then
                record.watch_at = G.GetTime() + 2
                client:send(
                    "watch_action",
                    record.task.target,
                    { token = token, action = record.task.recipe and "BUILD" or record.task.action }
                )
            end
        end
        -- 按移动进展续期；站着播放同一无效动画不会无限刷新超时。
        local x, _, z = player.Transform:GetWorldPosition()
        return math.floor(x * 2) .. ":" .. math.floor(z * 2)
    end

    local function inventory_items()
        local inv, out = player.replica.inventory, {}
        for slot, item in pairs(inv:GetItems()) do
            out[#out + 1] = { item = item, slot = slot, container = inv }
        end
        local overflow = inv:GetOverflowContainer()
        if overflow then
            for slot, item in pairs(overflow:GetItems()) do
                out[#out + 1] = { item = item, slot = slot, container = overflow }
            end
        end
        return out
    end

    -- 只收集本队列实际工作点附近的合法掉落，有限半径/数量且仍走原版拾取。
    function adapter.finished(task)
        if not task.did_work or not client.settings.queue.collect_after_work or not task.point or not G.TheSim then
            return
        end
        local candidates = G.TheSim:FindEntities(
            task.point.x,
            0,
            task.point.z,
            4,
            { "_inventoryitem" },
            { "INLIMBO", "FX", "NOCLICK", "fire" }
        )
        local targets = {}
        for _, target in ipairs(candidates) do
            if
                M.accepts(player, "PICKUP", target)
                and U.sameplatform(player, target)
                and target.entity:IsVisible()
                and (not G.CanEntitySeeTarget or G.CanEntitySeeTarget(player, target))
            then
                targets[#targets + 1] = target
                if #targets >= 40 then
                    break
                end
            end
        end
        for _, target in ipairs(Planner.nearest(targets, player:GetPosition())) do
            client.queue:add({ target = target, key = target, action = "PICKUP", right = false })
        end
    end

    -- 肉架取槽复用原版容器转移；一次只发一笔，等待槽位同步后再继续。
    local function prepare_rack(task, inv, point)
        local container = task.target.replica and task.target.replica.container
        if not container or U.call(container, "CanBeOpened") == false then
            return "pause", "container_unavailable"
        end
        if not container:IsOpenedBy(player) then
            task.right = false
            task.action, task.buffered, task.point =
                "RUMMAGE", G.BufferedAction(player, task.target, G.ACTIONS.RUMMAGE), point
            return "ready"
        end
        if task.transfer then
            local old, current = task.transfer, container:GetItemInSlot(task.transfer.slot)
            if current == old.item and (U.call(current.replica.stackable, "StackSize") or 1) == old.count then
                return "wait"
            end
            task.transfer = nil
        end
        for slot = 1, math.min(container:GetNumSlots(), 12) do
            local item = container:GetItemInSlot(slot)
            if U.valid(item) and not item:HasTag("dryable") then
                if inv:IsFull() and (not inv:GetOverflowContainer() or inv:GetOverflowContainer():IsFull()) then
                    return "pause", "inventory_full"
                end
                task.transfers = (task.transfers or 0) + 1
                if task.transfers > 24 then
                    return "pause", "queue_limit"
                end
                task.transfer = { slot = slot, item = item, count = U.call(item.replica.stackable, "StackSize") or 1 }
                container:MoveItemFromAllOfSlot(slot, player)
                return "wait"
            end
        end
        if not task.material or container:IsFull() then
            return "done"
        end
        task.action = "STORE"
    end

    -- 执行前复查目标、平台、材料、工具和容量，返回 ready/wait/pause/skip。
    function adapter.validate(task)
        local pc, inv = player.components.playercontroller, player.replica.inventory
        if not pc or not inv then
            return "pause", "unsupported_state"
        end
        if player:HasTag("busy") then
            return "wait"
        end
        if task.recipe then
            local recipe = G.AllRecipes[task.recipe]
            local builder = player.replica.builder
            if not recipe or recipe.placer then
                return "skip"
            end
            if not builder or not builder:KnowsRecipe(recipe.name) then
                return "pause", "recipe_locked"
            end
            if not builder:CanBuild(recipe.name) then
                return "pause", "materials_empty"
            end
            return "ready"
        end
        if task.target and not U.valid(task.target) then
            return "skip"
        end
        local point
        if task.plan then
            point = Planner.project(task.plan)
        else
            point = (task.target and task.target:GetPosition()) or task.point
        end
        if not point then
            return "skip"
        end
        point = G.Vector3(point.x, point.y or 0, point.z)
        if task.rack then
            local status, reason = prepare_rack(task, inv, point)
            if status then
                return status, reason
            end
        elseif not M.accepts(player, task.action, task.target) then
            return "skip"
        end
        -- 空格已满仍可向同类未满堆叠补入；否则暂停，避免不断提交注定失败的拾取。
        if task.action == "PICKUP" and task.target and inv:IsFull() then
            local overflow, capacity = inv:GetOverflowContainer(), false
            if overflow and not overflow:IsFull() then
                capacity = true
            end
            for _, entry in ipairs(inventory_items()) do
                local existing = entry.item
                if
                    existing.prefab == task.target.prefab
                    and existing.skinname == task.target.skinname
                    and existing.replica.stackable
                    and not existing.replica.stackable:IsFull()
                then
                    capacity = true
                end
            end
            if not capacity then
                return "pause", "inventory_full"
            end
        end
        local active = inv:GetActiveItem()
        if task.material and (not active or active.prefab ~= task.material) then
            for _, entry in ipairs(inventory_items()) do
                local item = entry.item
                if item.prefab == task.material then
                    entry.container:TakeActiveItemFromAllOfSlot(entry.slot)
                    return "wait"
                end
            end
            return "pause", "materials_empty"
        end
        local action
        if task.plan then
            local tool = inv:GetEquippedItem(G.EQUIPSLOTS.HANDS)
            if M.plan_mode(active, tool) == task.action then
                if not M.plan_valid(task.action, point, player, active, G) then
                    return "skip"
                end
                action = G.BufferedAction(player, nil, G.ACTIONS[task.action], active or tool, point)
                task.right = true
            end
        else
            action = M.pick(player, task.target, point, task.right, task.action)
            if not action and task.rack then
                action = M.pick(player, task.target, point, not task.right, task.action)
                if action then
                    task.right = not task.right
                end
            end
        end
        if (not action or action.action.id ~= task.action) and task.action and tools[task.action] then
            if U.call(player.replica.rider, "IsRiding") then
                return "pause", "unsupported_state"
            end
            for _, entry in ipairs(inventory_items()) do
                local item = entry.item
                if M.tool(item, task.action) then
                    G.SendRPCToServer(G.RPC.ControllerUseItemOnSelfFromInvTile, G.ACTIONS.EQUIP.code, item)
                    return "wait"
                end
            end
            return "pause", "tool_missing"
        end
        if not action then
            return "skip"
        end
        if task.action and action.action.id ~= task.action then
            return "skip"
        end
        task.action, task.buffered, task.point = action.action.id, action, point
        return "ready"
    end

    -- 先登记结果观察，再通过原版控制器或制作入口提交动作。
    function adapter.submit(task, token, callback)
        pending[token] = { callback = callback, task = task, watch_at = G.GetTime() + 2 }
        local id = task.recipe and "BUILD" or task.action
        client:send("watch_action", task.target, { token = token, action = id })
        if task.recipe then
            local builder = player.replica.builder
            local make = native_recipe or builder.MakeRecipeFromMenu
            make(builder, G.AllRecipes[task.recipe], task.skin)
            return
        end
        local action, pc = task.buffered, player.components.playercontroller
        if pc.ismastersim then
            pc:DoAction(action)
            return
        end
        local point = action:GetActionPoint() or task.point
        local platform, x, z = pc:GetPlatformRelativePosition(point.x, point.z)

        local function send()
            if not pending[token] then
                return
            end
            if task.right then
                G.SendRPCToServer(
                    G.RPC.RightClick,
                    action.action.code,
                    x,
                    z,
                    task.target,
                    action.rotation,
                    true,
                    0,
                    action.action.canforce,
                    action.action.mod_name,
                    platform,
                    platform ~= nil
                )
            else
                G.SendRPCToServer(
                    G.RPC.LeftClick,
                    action.action.code,
                    x,
                    z,
                    task.target,
                    true,
                    0,
                    action.action.canforce,
                    action.action.mod_name,
                    platform,
                    platform ~= nil
                )
            end
        end
        -- 客户端预测仍走 PlayerController；服务器只观察结果，所有原版校验保持生效。
        if pc.locomotor and pc:CanLocomote() then
            action.preview_cb = send
            pc:DoAction(action)
        else
            send()
        end
    end

    -- 把原版成功或失败结果映射为队列状态，不以动画开始当作完成。
    function adapter.result(data)
        local record = pending[data.token]
        if not record then
            return
        end
        pending[data.token] = nil
        local task = record.task
        if data.result == "success" then
            task.steps = (task.steps or 0) + 1
            if M.repeated[task.action] then
                task.did_work = true
            end
            if task.recipe then
                task.remaining = task.remaining - 1
                record.callback(task.remaining > 0 and "progress" or "done")
            else
                record.callback(
                    (M.repeated[task.action] or task.rack) and task.steps < client.config.queue.limit and "progress"
                        or "done"
                )
            end
        else
            record.callback("retry", "action_failed")
        end
    end

    -- 保存未包装的制作方法，避免队列递归进入自己的快捷键处理。
    function adapter.set_recipe_original(fn)
        native_recipe = fn
    end
    return adapter
end
return M
