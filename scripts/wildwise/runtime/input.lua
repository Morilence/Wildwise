local U = require("wildwise/core/util")
local Hooks = require("wildwise/core/hooks")
local Actions = require("wildwise/runtime/actions")
local Planner = require("wildwise/services/planner")
local M = {}
function M.attach(client, G)
    local player, scope = client.player, client.scope
    local pc, start, last_click = player.components.playercontroller, nil, nil
    if not pc then return end
    local function add(target, right, point)
        local action = Actions.pick(player, target, point, right)
        if action then
            local active = player.replica.inventory:GetActiveItem()
            return client.queue:add({ target = target, key = target, right = right, point = point,
                action = action.action.id, material = active and active.prefab })
        end
    end
    local function selection(right, down)
        if not client.config.queue or not client:input_ready() then return false end
        if not start and G.TheInput:GetHUDEntityUnderMouse() then return false end
        local modifier = G.TheInput:IsKeyDown(client.settings.queue_key)
        if not modifier and not start then return false end
        if down then
            start = { point = G.TheInput:GetWorldPosition(), screen = G.TheInput:GetScreenPosition(),
                target = G.TheInput:GetWorldEntityUnderMouse(), right = right, at = G.GetTime() }
            return true
        end
        if not start then return true end
        local selected = start; start = nil
        local finish, screen = G.TheInput:GetWorldPosition(), G.TheInput:GetScreenPosition()
        local dragged = (screen.x - selected.screen.x)^2 + (screen.y - selected.screen.y)^2 > 100
        local tool = player.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.HANDS)
        if dragged and right and (player.replica.inventory:GetActiveItem() or (tool and tool:HasTag("TILL_tool"))) then
            client:plan(selected.point, finish); return true
        end
        if dragged then
            local ax, az, bx, bz = selected.point.x, selected.point.z, finish.x, finish.z
            local mx, mz = (ax + bx) / 2, (az + bz) / 2
            local radius = math.min(50, math.sqrt((ax - bx)^2 + (az - bz)^2) / 2 + 1)
            local candidates, targets = G.TheSim:FindEntities(mx, 0, mz, radius, nil, { "INLIMBO", "FX", "NOCLICK" }), {}
            for _, target in ipairs(candidates) do
                local x, _, z = target.Transform:GetWorldPosition()
                if x >= math.min(ax, bx) and x <= math.max(ax, bx) and z >= math.min(az, bz) and z <= math.max(az, bz) then
                    targets[#targets + 1] = target
                    if #targets >= client.config.queue_limit then break end
                end
            end
            for _, target in ipairs(Planner.nearest(targets, player:GetPosition())) do add(target, right, target:GetPosition()) end
        elseif U.valid(selected.target) then
            local now = G.GetTime()
            if last_click and now - last_click.at <= .35 and last_click.prefab == selected.target.prefab then
                local x, y, z = selected.target.Transform:GetWorldPosition()
                local targets = G.TheSim:FindEntities(x, y, z, 15, nil, { "INLIMBO", "FX", "NOCLICK" })
                for _, target in ipairs(Planner.nearest(targets, player:GetPosition())) do
                    if target.prefab == selected.target.prefab then add(target, right, target:GetPosition()) end
                end
            else add(selected.target, right, selected.point) end
            last_click = { at = now, prefab = selected.target.prefab }
        end
        client:clear_preview()
        return true
    end
    Hooks.wrap(scope, pc, "OnLeftClick", function(original, self, down, ...)
        if selection(false, down) then return end
        if down and client:input_ready() then client.queue:cancel("manual_control") end
        return original(self, down, ...)
    end)
    Hooks.wrap(scope, pc, "OnRightClick", function(original, self, down, ...)
        if selection(true, down) then return end
        if down and client:input_ready() then client.queue:cancel("manual_control") end
        return original(self, down, ...)
    end)
    Hooks.wrap(scope, pc, "OnControl", function(original, self, control, down, ...)
        if down and ((control >= G.CONTROL_MOVE_UP and control <= G.CONTROL_MOVE_RIGHT)
            or control == G.CONTROL_ATTACK or control == G.CONTROL_CONTROLLER_ATTACK) then
            start = nil; client:clear_preview(); client.queue:cancel("manual_control")
        end
        return original(self, control, down, ...)
    end)
    local key_handler = G.TheInput:AddKeyHandler(function(key, down)
        -- 通用回调有 key/down 参数；专用 KeyUp 回调需要固定键值且不会传 key。
        if down or (client.menu and client.menu.binding) then return end
        if key == client.settings.menu_key then
            if client.menu then client.menu:close() elseif client:input_ready() then client:toggle_menu() end
        elseif key == client.settings.beefalo_key and client:input_ready() then
            client.settings.beefalo_visible = not client.settings.beefalo_visible
        end
    end)
    scope:add(function() key_handler:Remove() end)
    local builder = player.replica.builder
    if builder then
        client.adapter.set_recipe_original(builder.MakeRecipeFromMenu)
        Hooks.wrap(scope, builder, "MakeRecipeFromMenu", function(original, self, recipe, skin, ...)
            if client.config.queue and G.TheInput:IsKeyDown(client.settings.queue_key) and not recipe.placer then
                client.queue:add({ recipe = recipe.name, key = "recipe:" .. recipe.name, skin = skin, remaining = client.config.queue_limit })
                return
            end
            return original(self, recipe, skin, ...)
        end)
    end
end
return M
