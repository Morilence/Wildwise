local Queue = {}; Queue.__index = Queue
function Queue.new(adapter, limit)
    return setmetatable({ adapter = adapter, limit = limit or 200, tasks = {}, seen = {}, state = "idle",
        reason = "", generation = 0, sequence = 0, done = 0, skipped = 0 }, Queue)
end
function Queue:add(task)
    if #self.tasks >= self.limit then self.reason = "queue_limit"; return false end
    if task.key and self.seen[task.key] then return false end
    task.retries = 0; self.tasks[#self.tasks + 1] = task
    if task.key then self.seen[task.key] = true end
    if self.state == "idle" then self.state = "running" end
    return true
end
function Queue:finish(skipped)
    local task = table.remove(self.tasks, 1)
    if task and task.key then self.seen[task.key] = nil end
    self.inflight = nil
    self.adapter.release()
    if skipped then self.skipped = self.skipped + 1 else self.done = self.done + 1 end
    if #self.tasks == 0 then self.state = "idle" end
end
function Queue:pause(reason)
    if self.state == "idle" or self.state == "paused" then return end
    self.state, self.reason, self.wait_since = "paused", reason or "paused", nil
    self.generation = self.generation + 1; self.inflight = nil
    self.adapter.cancel(); self.adapter.release()
end
function Queue:resume()
    if #self.tasks > 0 then self.state, self.reason = "running", "" end
end
function Queue:cancel(reason)
    -- 空闲时普通点击无需额外提交 WALKTO；只取消本队列实际拥有的执行。
    if self.state ~= "idle" or self.inflight then self.adapter.cancel(); self.adapter.release() end
    self.generation = self.generation + 1
    self.wait_since = nil
    self.tasks, self.seen, self.inflight = {}, {}, nil
    self.state, self.reason = "idle", reason or "cancelled"
end
function Queue:result(token, result, reason)
    if not self.inflight or token ~= self.inflight.token or self.state ~= "running" then return end
    self.inflight = nil; self.adapter.release()
    if result == "done" then self:finish(false)
    elseif result == "skip" then self:finish(true)
    elseif result == "pause" then self:pause(reason)
    elseif result == "progress" then self.tasks[1].retries = 0
    else
        local task = self.tasks[1]
        if task.retries < 1 then task.retries = task.retries + 1 else self:finish(true) end
    end
end
function Queue:tick(now)
    if self.state ~= "running" or #self.tasks == 0 then return end
    local ready, reason = self.adapter.ready()
    if not ready then self:pause(reason); return end
    if self.inflight then
        local progress = self.adapter.progress(self.tasks[1])
        if progress ~= self.inflight.progress then self.inflight.progress, self.inflight.at = progress, now end
        if now - self.inflight.at >= 5 then
            self.adapter.cancel(); self:result(self.inflight.token, "retry", "timeout")
        end
        return
    end
    local task = self.tasks[1]
    local status, detail = self.adapter.validate(task)
    if status == "skip" then self:finish(true); return end
    if status == "pause" then self:pause(detail); return end
    if status == "wait" then
        self.wait_since = self.wait_since or now
        if now - self.wait_since >= 5 then self:pause("unsupported_state") end
        return
    end
    self.wait_since = nil
    self.sequence = self.sequence + 1
    local token = self.generation .. ":" .. self.sequence
    self.inflight = { token = token, at = now, progress = self.adapter.progress(task) }
    self.adapter.submit(task, token, function(result, why) self:result(token, result, why) end)
end
function Queue:redirect(old, outcome, surviving)
    for i = #self.tasks, 1, -1 do
        local task = self.tasks[i]
        if task.target == old then
            if outcome == "merged" and surviving then
                if task.key then self.seen[task.key] = nil end
                task.target, task.key = surviving, surviving
                self.seen[surviving] = true
            elseif outcome ~= "partial" then
                if i == 1 then self:finish(false) else
                    if task.key then self.seen[task.key] = nil end
                    table.remove(self.tasks, i)
                end
            end
        end
    end
end
return Queue
