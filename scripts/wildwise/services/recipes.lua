local U = require("wildwise/core/util")
local M = {}
-- 对四种明确输入运行原版配方 test；同优先级结果全部返回，不调用随机选菜逻辑。
function M.query(cooking, cooker, ingredients)
    if type(ingredients) ~= "table" or #ingredients ~= 4 then return nil, "four_ingredients" end
    local names, tags = {}, {}
    for _, name in ipairs(ingredients) do
        if type(name) ~= "string" or not cooking.ingredients[name] then return nil, "invalid_ingredient" end
        names[name] = (names[name] or 0) + 1
        for tag, amount in pairs(cooking.ingredients[name].tags or {}) do tags[tag] = (tags[tag] or 0) + amount end
    end
    local out, priority = {}, -math.huge
    for name, recipe in pairs(cooking.recipes[cooker] or {}) do
        local ok, matches = pcall(recipe.test, cooker, names, tags)
        if ok and matches then
            local rank = recipe.priority or 0
            if rank > priority then priority, out = rank, {} end
            if rank == priority then out[#out + 1] = { name = name, weight = recipe.weight or 1, cooktime = recipe.cooktime or 1 } end
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end
function M.inventory_choices(player, cooking)
    local names = {}
    for _, item in pairs(player.replica.inventory:GetItems()) do
        if U.valid(item) and cooking.ingredients[item.prefab] then names[item.prefab] = true end
    end
    local bag = player.replica.inventory:GetOverflowContainer()
    if bag then for _, item in pairs(bag:GetItems()) do if cooking.ingredients[item.prefab] then names[item.prefab] = true end end end
    return U.sortedkeys(names)
end
return M
