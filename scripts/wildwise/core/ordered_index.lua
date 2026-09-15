-- 按来源顺序索引空间桶；AVL 保证插入、删除、后继查找均为 O(log N)。
-- 查询只保留标量游标，跨 Tick 删除或重新索引实体不会使遍历游标悬空。
local Index = {}
Index.__index = Index

local function height(node)
    return node and node.height or 0
end

local function update(node)
    node.height = 1 + math.max(height(node.left), height(node.right))
    return node
end

local function rotate_left(node)
    local top = node.right
    node.right, top.left = top.left, node
    update(node)
    return update(top)
end

local function rotate_right(node)
    local top = node.left
    node.left, top.right = top.right, node
    update(node)
    return update(top)
end

local function balance(node)
    if not node then
        return nil
    end
    update(node)
    if height(node.left) - height(node.right) > 1 then
        if height(node.left.right) > height(node.left.left) then
            node.left = rotate_left(node.left)
        end
        return rotate_right(node)
    end
    if height(node.right) - height(node.left) > 1 then
        if height(node.right.left) > height(node.right.right) then
            node.right = rotate_right(node.right)
        end
        return rotate_left(node)
    end
    return node
end

local function insert(node, key, value)
    if not node then
        return { key = key, value = value, height = 1 }
    end
    if key < node.key then
        node.left = insert(node.left, key, value)
    elseif key > node.key then
        node.right = insert(node.right, key, value)
    else
        node.value = value
    end
    return balance(node)
end

local function remove(node, key)
    if not node then
        return nil
    end
    if key < node.key then
        node.left = remove(node.left, key)
    elseif key > node.key then
        node.right = remove(node.right, key)
    elseif not node.left or not node.right then
        return node.left or node.right
    else
        local successor = node.right
        while successor.left do
            successor = successor.left
        end
        node.key, node.value = successor.key, successor.value
        node.right = remove(node.right, successor.key)
    end
    return balance(node)
end

function Index.new()
    return setmetatable({}, Index)
end

function Index:set(key, value)
    self.root = insert(self.root, key, value)
end

function Index:remove(key)
    self.root = remove(self.root, key)
end

-- 返回严格大于 key 的最早来源；实体有效性由调用方在操作前检查。
function Index:after(key)
    local node, best = self.root, nil
    while node do
        if node.key > key then
            best, node = node, node.left
        else
            node = node.right
        end
    end
    if best then
        return best.value, best.key
    end
end

return Index
