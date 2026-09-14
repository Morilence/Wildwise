local LRU = {}
LRU.__index = LRU

-- 创建固定容量缓存；最近访问项置于链表头。
function LRU.new(capacity)
    return setmetatable({ capacity = capacity or 256, size = 0, entries = {} }, LRU)
end

-- 从双向链表摘除节点，不改变键索引。
function LRU:unlink(node)
    if node.prev then
        node.prev.next = node.next
    else
        self.first = node.next
    end
    if node.next then
        node.next.prev = node.prev
    else
        self.last = node.prev
    end
end

-- 把已有节点移到最近访问位置，时间复杂度为 O(1)。
function LRU:touch(node)
    if self.first == node then
        return
    end
    if node.prev or node.next or self.last == node then
        self:unlink(node)
    end
    node.prev, node.next = nil, self.first
    if self.first then
        self.first.prev = node
    else
        self.last = node
    end
    self.first = node
end

-- 读取缓存并刷新最近访问顺序；未命中返回 nil。
function LRU:get(key)
    local node = self.entries[key]
    if node then
        self:touch(node)
        return node.value
    end
end

-- 只读缓存，不改变淘汰顺序。
function LRU:peek(key)
    local node = self.entries[key]
    return node and node.value
end

-- 写入缓存，超过容量时淘汰最久未访问项。
function LRU:set(key, value)
    local node = self.entries[key]
    if node then
        node.value = value
    else
        node = { key = key, value = value }
        self.entries[key] = node
        self.size = self.size + 1
    end
    self:touch(node)
    if self.size > self.capacity then
        self:remove(self.last.key)
    end
end

-- 同时删除索引和链表节点；不存在的键可重复删除。
function LRU:remove(key)
    local node = self.entries[key]
    if node then
        self:unlink(node)
        self.entries[key] = nil
        self.size = self.size - 1
    end
end

-- 清空缓存并释放全部实体引用。
function LRU:clear()
    self.entries, self.first, self.last, self.size = {}, nil, nil, 0
end
return LRU
