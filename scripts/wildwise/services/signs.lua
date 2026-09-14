local U = require("wildwise/core/util")
local M = {}
M.supported = { treasurechest = true, dragonflychest = true, icebox = true, saltbox = true,
    chester = true, hutch = true, fish_box = true, boat_ancient_container = true }
-- 优先取最前面的有效格子；不解包、不生成临时物品，避免触发食物/皮肤的游戏回调。
function M.first(container)
    for slot = 1, container.numslots do
        local item = container:GetItemInSlot(slot)
        if U.valid(item) then return item end
    end
end
function M.image(item, G)
    if not U.valid(item) then return nil end
    local c = item.components
    if c.unwrappable and c.unwrappable.itemdata and c.unwrappable.itemdata[1] then
        local record = c.unwrappable.itemdata[1]
        local name = record.prefab
        local invdata = record.data and record.data.inventoryitem
        if invdata and invdata.imagename then name = invdata.imagename end
        if record.skinname and G.GetSkinInvIconName then name = G.GetSkinInvIconName(record.skinname) or name end
        local dish, spice = name:match("^(.-)_(spice_%w+)$")
        if dish and spice then return spice .. "_over", G.GetInventoryItemAtlas(spice .. "_over.tex"), dish, G.GetInventoryItemAtlas(dish .. ".tex") end
        return name, G.GetInventoryItemAtlas(name .. ".tex")
    end
    local inv = c.inventoryitem
    if not inv then return nil end
    -- replica 的图标可能是 net_hash 数字。服务端使用原版绘图覆盖和组件字符串，
    -- 保留皮肤/调味图层，且不依赖客户端哈希反查或临时生成物品。
    local name = G.FunctionOrValue and G.FunctionOrValue(item.drawimageoverride, item)
    name = name or (inv.imagename ~= "" and inv.imagename) or item.prefab
    if type(name) ~= "string" then return nil end
    name = name:gsub("%.tex$", "")
    local atlas = G.FunctionOrValue and G.FunctionOrValue(item.drawatlasoverride, item)
    atlas = atlas or (inv.atlasname ~= "" and inv.atlasname)
    if type(atlas) ~= "string" then atlas = G.GetInventoryItemAtlas(name .. ".tex") end
    if item.inv_image_bg then return name, atlas, item.inv_image_bg.image:gsub("%.tex$", ""), item.inv_image_bg.atlas end
    return name, atlas
end
return M
