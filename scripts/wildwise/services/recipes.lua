local U = require("wildwise/core/util")
local M = {}
-- cooking.lua 的三个原生 prefab 别名没有导出；显式适配并由真实引擎配方测试校验。
local aliases =
    { cookedmeat = "meat_cooked", cookedsmallmeat = "smallmeat_cooked", cookedmonstermeat = "monstermeat_cooked" }

-- 查询原版食材定义及规范名；库存名称仍保留真实 prefab，不能把别名当成物品生成。
function M.ingredient(cooking, prefab)
    if type(prefab) ~= "string" or not cooking or type(cooking.ingredients) ~= "table" then
        return nil
    end
    local name = aliases[prefab] or prefab
    local data = cooking.ingredients[name]
    if type(data) == "table" then
        return data, name
    end
end

-- 对恰好四格输入执行当前原版配方，返回最高优先级的所有候选，不进行随机选菜。
-- 判定异常会明确返回错误；不能忽略失效配方后把低优先级结果当成准确预览。
function M.query(cooking, cooker, ingredients)
    if type(ingredients) ~= "table" or #ingredients ~= 4 or U.count(ingredients) ~= 4 then
        return nil, "four_ingredients"
    end
    if not cooking or type(cooking.recipes) ~= "table" or type(cooking.recipes[cooker]) ~= "table" then
        return nil, "invalid_recipe"
    end
    local names, tags = {}, {}
    for i = 1, 4 do
        local ingredient, name = M.ingredient(cooking, ingredients[i])
        if not ingredient or (ingredient.tags ~= nil and type(ingredient.tags) ~= "table") then
            return nil, "invalid_ingredient"
        end
        names[name] = (names[name] or 0) + 1
        for tag, amount in pairs(ingredient.tags or {}) do
            if type(tag) ~= "string" or not U.finite(amount) or not U.finite((tags[tag] or 0) + amount) then
                return nil, "invalid_ingredient"
            end
            tags[tag] = (tags[tag] or 0) + amount
        end
    end
    local out, priority = {}, -math.huge
    for name, recipe in pairs(cooking.recipes[cooker]) do
        if type(name) ~= "string" or type(recipe) ~= "table" or type(recipe.test) ~= "function" then
            return nil, "invalid_recipe"
        end
        local rank, weight, cooktime = recipe.priority or 0, recipe.weight or 1, recipe.cooktime or 1
        if not U.finite(rank) or not U.finite(weight) or weight <= 0 or not U.finite(cooktime) or cooktime <= 0 then
            return nil, "invalid_recipe"
        end
        -- 每个查询回调只获得四格输入的浅副本，避免污染后续配方和原版食材注册表。
        local ok, matches = pcall(recipe.test, cooker, U.copy(names), U.copy(tags))
        if not ok then
            return nil, "invalid_recipe"
        end
        if matches then
            if rank > priority then
                priority, out = rank, {}
            end
            if rank == priority then
                out[#out + 1] = { name = name, weight = weight, cooktime = cooktime }
            end
        end
    end
    table.sort(out, function(a, b)
        return a.name < b.name
    end)
    return out
end

-- 收集主库存、背包和鼠标手持的食材种类；切换背包时忽略已移除的物品引用。
function M.inventory_choices(player, cooking)
    local names, inventory = {}, player.replica and player.replica.inventory
    if not inventory then
        return {}
    end
    local function add(item)
        if U.valid(item) and M.ingredient(cooking, item.prefab) then
            names[item.prefab] = true
        end
    end
    for _, item in pairs(inventory:GetItems()) do
        add(item)
    end
    add(U.call(inventory, "GetActiveItem"))
    local bag = inventory:GetOverflowContainer()
    if bag then
        for _, item in pairs(bag:GetItems()) do
            add(item)
        end
    end
    return U.sortedkeys(names)
end
return M
