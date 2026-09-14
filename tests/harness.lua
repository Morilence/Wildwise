local H = { passed = 0, failed = 0 }
function H.test(name, fn)
    local ok, err = xpcall(fn, debug.traceback)
    if ok then H.passed = H.passed + 1; io.write("PASS ", name, "\n")
    else H.failed = H.failed + 1; io.write("FAIL ", name, "\n", err, "\n") end
end
function H.eq(actual, expected)
    assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
function H.entity(id, x, z)
    local e = { GUID = id, prefab = "test", components = {}, replica = {}, tags = {}, events = {}, valid = true }
    e.Transform = { GetWorldPosition = function() return x or 0, 0, z or 0 end }
    e.entity = { IsVisible = function() return true end }
    function e:IsValid() return self.valid end
    function e:HasTag(tag) return self.tags[tag] == true end
    function e:GetPosition() local xx, _, zz = self.Transform:GetWorldPosition(); return { x = xx, y = 0, z = zz } end
    function e:GetCurrentPlatform() return self.platform end
    function e:GetDisplayName() return self.prefab end
    function e:ListenForEvent(event, fn) self.events[event] = self.events[event] or {}; self.events[event][fn] = true end
    function e:RemoveEventCallback(event, fn) if self.events[event] then self.events[event][fn] = nil end end
    function e:PushEvent(event, data) for fn in pairs(self.events[event] or {}) do fn(self, data) end end
    function e:Remove() self.valid = false; self:PushEvent("onremove") end
    return e
end
function H.item(id, x, count)
    local e = H.entity(id, x, 0); e.prefab = "twigs"
    e.components.inventoryitem = { is_landed = true, canbepickedup = true }
    local stack = { size = count or 1, max = 40 }
    function stack:StackSize() return self.size end
    function stack:Put(other)
        if e.prefab ~= other.prefab or e.skinname ~= other.skinname then return end
        local amount = math.min(self.max - self.size, other.components.stackable.size)
        self.size = self.size + amount; other.components.stackable.size = other.components.stackable.size - amount
        if other.components.stackable.size == 0 then other:Remove() end
    end
    e.components.stackable = stack
    return e
end
return H
