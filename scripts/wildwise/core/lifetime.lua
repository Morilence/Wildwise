local Lifetime = {}
Lifetime.__index = Lifetime

-- 创建监听、任务和包装器的清理域。
function Lifetime.new()
    return setmetatable({ cleanups = {}, closed = false }, Lifetime)
end

-- 注册清理函数；清理域已关闭时立即执行。
function Lifetime:add(fn)
    if self.closed then
        fn()
    else
        self.cleanups[#self.cleanups + 1] = fn
    end
    return fn
end

-- 监听实体事件，并在关闭时移除同一回调。
function Lifetime:listen(owner, event, fn, source)
    owner:ListenForEvent(event, fn, source)
    self:add(function()
        owner:RemoveEventCallback(event, fn, source)
    end)
end

-- 登记需要在关闭时取消的引擎任务。
function Lifetime:task(task)
    self:add(function()
        task:Cancel()
    end)
    return task
end

-- 按逆序清理所有资源；可重复调用，单项失败不阻断剩余清理。
function Lifetime:close()
    if self.closed then
        return
    end
    self.closed = true
    for i = #self.cleanups, 1, -1 do
        pcall(self.cleanups[i])
    end
    self.cleanups = {}
end
return Lifetime
