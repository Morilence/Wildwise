local Lifetime = {}; Lifetime.__index = Lifetime
function Lifetime.new() return setmetatable({ cleanups = {}, closed = false }, Lifetime) end
function Lifetime:add(fn)
    if self.closed then fn() else self.cleanups[#self.cleanups + 1] = fn end
    return fn
end
function Lifetime:listen(owner, event, fn, source)
    owner:ListenForEvent(event, fn, source)
    self:add(function() owner:RemoveEventCallback(event, fn, source) end)
end
function Lifetime:task(task)
    self:add(function() task:Cancel() end); return task
end
function Lifetime:close()
    if self.closed then return end
    self.closed = true
    for i = #self.cleanups, 1, -1 do pcall(self.cleanups[i]) end
    self.cleanups = {}
end
return Lifetime
