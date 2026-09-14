local LRU = {}; LRU.__index = LRU
function LRU.new(capacity)
    return setmetatable({ capacity = capacity or 256, size = 0, entries = {} }, LRU)
end
function LRU:unlink(node)
    if node.prev then node.prev.next = node.next else self.first = node.next end
    if node.next then node.next.prev = node.prev else self.last = node.prev end
end
function LRU:touch(node)
    if self.first == node then return end
    if node.prev or node.next or self.last == node then self:unlink(node) end
    node.prev, node.next = nil, self.first
    if self.first then self.first.prev = node else self.last = node end
    self.first = node
end
function LRU:get(key)
    local node = self.entries[key]
    if node then self:touch(node); return node.value end
end
function LRU:peek(key) local node = self.entries[key]; return node and node.value end
function LRU:set(key, value)
    local node = self.entries[key]
    if node then node.value = value else
        node = { key = key, value = value }; self.entries[key] = node; self.size = self.size + 1
    end
    self:touch(node)
    if self.size > self.capacity then self:remove(self.last.key) end
end
function LRU:remove(key)
    local node = self.entries[key]
    if node then self:unlink(node); self.entries[key] = nil; self.size = self.size - 1 end
end
function LRU:clear() self.entries, self.first, self.last, self.size = {}, nil, nil, 0 end
return LRU
