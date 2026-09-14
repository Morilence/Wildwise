local U = require("wildwise/core/util")
local M = {}
M.supported = {
    treasurechest = true,
    dragonflychest = true,
    icebox = true,
    saltbox = true,
    chester = true,
    hutch = true,
    fish_box = true,
    boat_ancient_container = true,
}

-- 同时检查模块总开关、容器白名单与类型开关。
function M.enabled(prefab, settings)
    -- 总开关与类型开关同时生效；白名单外的容器不能仅靠添加配置就挂载辅助牌。
    return settings.enabled == true and M.supported[prefab] == true and settings[prefab] == true
end

-- 优先取最前面的有效格子；不解包、不生成临时物品，避免触发食物/皮肤的游戏回调。
-- 返回第一格有效物品，不移动或解包容器内容。
function M.first(container)
    for slot = 1, container.numslots do
        local item = container:GetItemInSlot(slot)
        if U.valid(item) then
            return item
        end
    end
end

-- 解析原生图标、皮肤和调味层，不生成临时物品或注册外部资产。
function M.image(item, G, settings)
    if not U.valid(item) then
        return nil
    end
    local c = item.components
    if
        (not settings or settings.bundle_contents ~= false)
        and c.unwrappable
        and c.unwrappable.itemdata
        and c.unwrappable.itemdata[1]
    then
        local record = c.unwrappable.itemdata[1]
        if type(record) ~= "table" or type(record.prefab) ~= "string" then
            return nil
        end
        local name = record.prefab
        local invdata = record.data and record.data.inventoryitem
        if invdata and type(invdata.imagename) == "string" and invdata.imagename ~= "" then
            name = invdata.imagename
        end
        if record.skinname and G.GetSkinInvIconName then
            name = G.GetSkinInvIconName(record.skinname) or name
        end
        if type(name) ~= "string" then
            return nil
        end
        name = name:gsub("%.tex$", "")
        local dish, spice = name:match("^(.-)_(spice_%w+)$")
        if dish and spice then
            return spice .. "_over",
                G.GetInventoryItemAtlas(spice .. "_over.tex"),
                dish,
                G.GetInventoryItemAtlas(dish .. ".tex")
        end
        return name, G.GetInventoryItemAtlas(name .. ".tex")
    end
    local inv = c.inventoryitem
    if not inv then
        return nil
    end
    -- replica 的图标可能是 net_hash 数字。服务端使用原版绘图覆盖和组件字符串，
    -- 保留皮肤/调味图层，且不依赖客户端哈希反查或临时生成物品。
    local name = G.FunctionOrValue and G.FunctionOrValue(item.drawimageoverride, item)
    name = name or (inv.imagename ~= "" and inv.imagename) or item.prefab
    if type(name) ~= "string" then
        return nil
    end
    name = name:gsub("%.tex$", "")
    local atlas = G.FunctionOrValue and G.FunctionOrValue(item.drawatlasoverride, item)
    atlas = atlas or (inv.atlasname ~= "" and inv.atlasname)
    if type(atlas) ~= "string" then
        atlas = G.GetInventoryItemAtlas(name .. ".tex")
    end
    if item.inv_image_bg then
        return name, atlas, item.inv_image_bg.image:gsub("%.tex$", ""), item.inv_image_bg.atlas
    end
    return name, atlas
end

-- 只沿用容器里实际小木牌物品的原生关联皮肤，不构造皮肤名称或解锁资格。
function M.skin(container, settings)
    if settings and settings.body_skins == false then
        return nil
    end
    for slot = 1, math.min(container.numslots or 0, 80) do
        local item = container:GetItemInSlot(slot)
        if U.valid(item) and item.prefab == "minisign_item" and type(item.linked_skinname) == "string" then
            return item.linked_skinname, item.skin_id
        end
    end
end
return M
