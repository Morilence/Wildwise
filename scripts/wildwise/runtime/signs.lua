local Signs = require("wildwise/services/signs")
local Lifetime = require("wildwise/core/lifetime")
local U = require("wildwise/core/util")
local M = {}

-- 为受支持容器挂载一个辅助牌生命周期；重复挂载复用同一实例。
function M.attach(inst, G)
    if inst._wildwise_sign_scope and not inst._wildwise_sign_scope.closed then
        return inst._wildwise_sign_scope
    end
    local scope, sign, scheduled = Lifetime.new(), nil, false
    local watched, item_scope, last_image, dirty
    inst._wildwise_sign_scope = scope

    local function update()
        scheduled = false
        if scope.closed or not U.valid(inst) or inst:HasTag("burnt") then
            return
        end
        local container = inst.components.container
        if not container then
            return
        end
        local item = Signs.first(container)
        if watched ~= item then
            if item_scope then
                item_scope:close()
            end
            watched, item_scope = item, Lifetime.new()
            if item then
                item_scope:listen(inst, "imagechange", dirty, item)
                item_scope:listen(inst, "onremove", dirty, item)
            end
        end
        if not item then
            if U.valid(sign) then
                sign:Remove()
                sign = nil
            end
            return
        end
        local ok, name, atlas, bg, bgatlas = pcall(Signs.image, item, G)
        if not ok or not name or not atlas then
            if U.valid(sign) then
                sign:Remove()
                sign = nil
            end
            return
        end
        if not U.valid(sign) then
            last_image = nil
            sign = G.SpawnPrefab("minisign")
            if not sign then
                return
            end
            -- 复用原版资源与 drawable 的网络同步；辅助牌不可收获，也不进入存档。
            sign.persists = false
            sign:AddTag("NOCLICK")
            sign:AddTag("FX")
            for _, key in ipairs({ "workable", "lootdropper", "burnable", "propagator", "inspectable" }) do
                if sign.components[key] then
                    sign:RemoveComponent(key)
                end
            end
            sign.entity:SetParent(inst.entity)
            sign.Transform:SetPosition(0, 0, 0.7)
            sign.Transform:SetScale(0.65, 0.65, 0.65)
        end
        -- 图集缺失时只跳过本牌，绝不包装全局 RegisterPrefabs 或收集其它模组资源。
        local signature = table.concat({ name, atlas, bg or "", bgatlas or "" }, "\0")
        if signature == last_image then
            return
        end
        local drawn = pcall(sign.components.drawable.OnDrawn, sign.components.drawable, name, nil, atlas, bg, bgatlas)
        if not drawn then
            sign:Remove()
            sign = nil
        else
            last_image = signature
        end
    end
    dirty = function()
        if scheduled or scope.closed then
            return
        end
        scheduled = true
        inst:DoTaskInTime(0, update)
    end
    for _, event in ipairs({ "onclose", "itemget", "itemlose" }) do
        scope:listen(inst, event, dirty)
    end
    scope:listen(inst, "onremove", function()
        scope:close()
    end)
    scope:listen(inst, "onburnt", function()
        scope:close()
    end)
    scope:add(function()
        if item_scope then
            item_scope:close()
        end
        if U.valid(sign) then
            sign:Remove()
        end
        inst._wildwise_sign_scope = nil
    end)
    dirty()
    return scope
end
return M
