local U = require("wildwise/core/util")
local Planner = require("wildwise/services/planner")
local M = {}
-- 显式白名单：采集、农业和设施操作可排队，ATTACK/CASTSPELL 等战斗决策不会自动执行。
M.allowed = {}
for _, id in ipairs({ "PICKUP", "PICK", "HARVEST", "CHOP", "MINE", "DIG", "HAMMER", "NET", "TILL", "PLANT",
    "PLANTSOIL", "POUR_WATER", "POUR_WATER_GROUNDTILE", "FERTILIZE", "INTERACT_WITH", "ADDWETFUEL", "ADDFUEL",
    "GIVE", "FEED", "HEAL", "STORE", "TAKEITEM", "DEPLOY", "DEPLOY_TILEARRIVE", "TERRAFORM", "DRY", "REPAIR",
    "RESETMINE", "CHECKTRAP", "ACTIVATE", "LOWER_SAIL", "RAISE_SAIL", "LOWER_ANCHOR", "RAISE_ANCHOR",
    "ROW_FAIL", "GIVEALLTOPLAYER", "ADDCOMPOSTABLE", "EMPTY_CONTAINER", "PICKUP_CHESTER", "DRAW" }) do M.allowed[id] = true end
M.repeated = { CHOP = true, MINE = true, HAMMER = true, DIG = true }
local tools = { CHOP = "CHOP_tool", MINE = "MINE_tool", HAMMER = "HAMMER_tool", DIG = "DIG_tool", NET = "NET_tool", TILL = "TILL_tool" }
function M.pick(player, target, point, right)
    local picker = player.components.playeractionpicker
    if not picker then return end
    local choices = right and picker:GetRightClickActions(point, target) or picker:GetLeftClickActions(point, target)
    for _, action in ipairs(choices or {}) do if M.allowed[action.action.id] then return action end end
end
function M.create(client, G)
    local player = client.player
    local pending, native_recipe = {}, nil
    local adapter = {}
    function adapter.ready()
        if not U.valid(player) or player:HasTag("playerghost") then return false, "death" end
        if not client.session then return false, "disconnected" end
        if not client:input_ready() then return false, "input_focus" end
        return true
    end
    function adapter.cancel()
        pending = {}
        local pc = player.components.playercontroller
        if pc then
            if pc.locomotor then pc.locomotor:Stop() end
            if pc.ismastersim then player:ClearBufferedAction()
            else
                -- 原版移动 RPC 接管角色，取消服务器上已进入寻路/预览的动作。
                local x, _, z = player.Transform:GetWorldPosition()
                local platform, px, pz = pc:GetPlatformRelativePosition(x, z)
                G.SendRPCToServer(G.RPC.LeftClick, G.ACTIONS.WALKTO.code, px, pz, nil, true, 0, nil, nil, platform, platform ~= nil)
            end
        end
    end
    function adapter.release() client:send("release", nil, {}) end
    function adapter.progress()
        -- 长距离寻路可能超过初始观察租约；续租只观察当前动作，不另起执行器。
        for token, record in pairs(pending) do
            if G.GetTime() >= record.watch_at then
                record.watch_at = G.GetTime() + 2
                client:send("watch_action", record.task.target, { token = token, action = record.task.recipe and "BUILD" or record.task.action })
            end
        end
        -- 按移动进展续期；站着播放同一无效动画不会无限刷新超时。
        local x, _, z = player.Transform:GetWorldPosition()
        return math.floor(x * 2) .. ":" .. math.floor(z * 2)
    end
    local function inventory_items()
        local inv, out = player.replica.inventory, {}
        for slot, item in pairs(inv:GetItems()) do out[#out + 1] = { item = item, slot = slot, container = inv } end
        local overflow = inv:GetOverflowContainer()
        if overflow then
            for slot, item in pairs(overflow:GetItems()) do out[#out + 1] = { item = item, slot = slot, container = overflow } end
        end
        return out
    end
    function adapter.validate(task)
        local pc, inv = player.components.playercontroller, player.replica.inventory
        if not pc or not inv then return "pause", "unsupported_state" end
        if player:HasTag("busy") then return "wait" end
        if task.recipe then
            local recipe = G.AllRecipes[task.recipe]
            local builder = player.replica.builder
            if not recipe or recipe.placer then return "skip" end
            if not builder or not builder:KnowsRecipe(recipe.name) then return "pause", "recipe_locked" end
            if not builder:CanBuild(recipe.name) then return "pause", "materials_empty" end
            return "ready"
        end
        if task.target and not U.valid(task.target) then return "skip" end
        local point = task.plan and Planner.project(task.plan) or (task.target and task.target:GetPosition()) or task.point
        if not point then return "skip" end
        point = G.Vector3(point.x, point.y or 0, point.z)
        -- 空格已满仍可向同类未满堆叠补入；否则暂停，避免不断提交注定失败的拾取。
        if task.action == "PICKUP" and task.target and inv:IsFull() then
            local overflow, capacity = inv:GetOverflowContainer(), false
            if overflow and not overflow:IsFull() then capacity = true end
            for _, entry in ipairs(inventory_items()) do
                local existing = entry.item
                if existing.prefab == task.target.prefab and existing.skinname == task.target.skinname
                    and existing.replica.stackable and not existing.replica.stackable:IsFull() then capacity = true end
            end
            if not capacity then return "pause", "inventory_full" end
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
        if task.plan and task.action == "TILL" then
            if not G.TheWorld.Map:CanTillSoilAtPoint(point.x, 0, point.z) then return "skip" end
        elseif task.plan and active and task.action == "DEPLOY" then
            if not active.replica.inventoryitem:CanDeploy(point, nil, player) then return "skip" end
        end
        local action = M.pick(player, task.target, point, task.right)
        if (not action or action.action.id ~= task.action) and task.action and tools[task.action] then
            for _, entry in ipairs(inventory_items()) do
                local item = entry.item
                if U.valid(item) and item:HasTag(tools[task.action]) then
                    G.SendRPCToServer(G.RPC.ControllerUseItemOnSelfFromInvTile, G.ACTIONS.EQUIP.code, item)
                    return "wait"
                end
            end
            return "pause", "tool_missing"
        end
        if not action then return "skip" end
        if task.action and action.action.id ~= task.action then return "skip" end
        task.action, task.buffered, task.point = action.action.id, action, point
        return "ready"
    end
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
        if pc.ismastersim then pc:DoAction(action); return end
        local point = action:GetActionPoint() or task.point
        local platform, x, z = pc:GetPlatformRelativePosition(point.x, point.z)
        local function send()
            if not pending[token] then return end
            if task.right then
                G.SendRPCToServer(G.RPC.RightClick, action.action.code, x, z, task.target, action.rotation,
                    true, 0, action.action.canforce, action.action.mod_name, platform, platform ~= nil)
            else
                G.SendRPCToServer(G.RPC.LeftClick, action.action.code, x, z, task.target,
                    true, 0, action.action.canforce, action.action.mod_name, platform, platform ~= nil)
            end
        end
        -- 客户端预测仍走 PlayerController；服务器只观察结果，所有原版校验保持生效。
        if pc.locomotor and pc:CanLocomote() then action.preview_cb = send; pc:DoAction(action) else send() end
    end
    function adapter.result(data)
        local record = pending[data.token]
        if not record then return end
        pending[data.token] = nil
        local task = record.task
        if data.result == "success" then
            if task.recipe then
                task.remaining = task.remaining - 1
                record.callback(task.remaining > 0 and "progress" or "done")
            else record.callback(M.repeated[task.action] and "progress" or "done") end
        else record.callback("retry", "action_failed") end
    end
    function adapter.set_recipe_original(fn) native_recipe = fn end
    return adapter
end
return M
