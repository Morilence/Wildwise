-- 地图同步按频道持有不可变版本：位置变化不重新发送配对。
-- 编码与发送分 Tick 推进，频道间独立组装，旧快照直到新版本完整才被替换。
local Protocol = require("wildwise/core/protocol")
local Sync = {}
Sync.__index = Sync
local keys = { "players", "pings", "fires", "pairs" }

function Sync.new(json, send, clock)
    return setmetatable({
        json = json,
        send = send,
        clock = clock or os.clock,
        jobs = {},
        players = {},
        order = {},
        revision = 0,
        player_cursor = 1,
        job_cursor = 1,
        bytes = 0,
        messages = 0,
    }, Sync)
end

-- id 表示可见性相同的一组数据；相同版本返回同一任务，供多个玩家共享编码。
function Sync:publish(id, key, version, entries)
    local job = self.jobs[id]
    if job and job.version == version then
        return job
    end
    self.revision = self.revision + 1
    job = {
        id = id,
        key = key,
        version = version,
        entries = entries,
        revision = self.revision,
        next_entry = 1,
        chunks = {},
        packets = nil,
    }
    self.jobs[id] = job
    job.failed = #entries > 2048
    return job
end

-- 高频频道只比较固定标量记录，不靠重复 JSON 编码判断是否变化。
function Sync:publish_rows(id, key, entries)
    local job = self.jobs[id]
    local equal = job and #job.entries == #entries
    if equal then
        for i, row in ipairs(entries) do
            local old = job.entries[i]
            for field, value in pairs(row) do
                if old[field] ~= value then
                    equal = false
                    break
                end
            end
            for field in pairs(old) do
                if row[field] == nil then
                    equal = false
                    break
                end
            end
            if not equal then
                break
            end
        end
    end
    return equal and job or self:publish(id, key, job and job.version + 1 or 1, entries)
end

function Sync:watch(player, key, job)
    local state = self.players[player]
    if not state then
        state = { desired = {}, active = {}, applied = {}, cursor = 1 }
        self.players[player] = state
        self.order[#self.order + 1] = player
    end
    if state.desired[key] ~= job then
        -- 权限或版本变化立刻作废尚未发完的旧频道；不能在撤销共享后继续旧流。
        state.active[key] = nil
    end
    state.desired[key] = job
end

function Sync:remove(player)
    self.players[player] = nil
    for i = #self.order, 1, -1 do
        if self.order[i] == player then
            table.remove(self.order, i)
        end
    end
end

-- 一步最多编码 12 条记录；超限时只缩小本片，单条仍超限则保留旧频道。
function Sync:prepare(job)
    local count = #job.entries
    if count <= 12 and job.next_entry == 1 then
        local packet = Protocol.prepare(self.json, "map", { [job.key] = job.entries })
        if packet then
            job.packets = { packet }
            return
        end
    end
    if job.next_entry > count then
        local packets = {
            assert(Protocol.prepare(self.json, "map_begin", {
                revision = job.revision,
                channel = job.key,
                chunks = #job.chunks,
                keys = { job.key },
            })),
        }
        for _, chunk in ipairs(job.chunks) do
            packets[#packets + 1] = chunk
        end
        packets[#packets + 1] = assert(Protocol.prepare(self.json, "map_end", {
            revision = job.revision,
            channel = job.key,
        }))
        job.packets, job.chunks = packets, nil
        return
    end
    local size = math.min(12, count - job.next_entry + 1)
    while size >= 1 do
        local entries = {}
        for i = job.next_entry, job.next_entry + size - 1 do
            entries[#entries + 1] = job.entries[i]
        end
        local packet = Protocol.prepare(self.json, "map_chunk", {
            revision = job.revision,
            channel = job.key,
            index = #job.chunks + 1,
            key = job.key,
            entries = entries,
        })
        if packet then
            job.chunks[#job.chunks + 1] = packet
            job.next_entry = job.next_entry + size
            return
        end
        size = math.floor(size / 2)
    end
    job.failed = true
end

function Sync:tick()
    local started = self.clock()
    local deadline, prepare_deadline = started + 0.002, started + 0.001
    local needed, referenced, jobs = {}, {}, {}
    for _, player in ipairs(self.order) do
        local state = self.players[player]
        for _, key in ipairs(keys) do
            local job = state.desired[key]
            if job then
                referenced[job] = true
                if not job.packets and not job.failed and not needed[job] then
                    needed[job] = true
                    jobs[#jobs + 1] = job
                end
            end
        end
    end
    -- 删除无人订阅的旧可见性组，避免退服和权限切换积累编码任务。
    for id, job in pairs(self.jobs) do
        if not referenced[job] then
            self.jobs[id] = nil
        end
    end
    local steps = 0
    while #jobs > 0 and steps < 32 and self.clock() < prepare_deadline do
        self.job_cursor = (self.job_cursor - 1) % #jobs + 1
        local job = jobs[self.job_cursor]
        if not job.packets and not job.failed then
            self:prepare(job)
        end
        self.job_cursor, steps = self.job_cursor + 1, steps + 1
    end
    local bytes, messages = 0, 0
    -- 最多 8 包／24 KB；轮转玩家及频道，慢速配对流不会阻挡新的玩家位置。
    local attempts = #self.order * #keys * 2
    for _ = 1, attempts do
        if #self.order == 0 or messages >= 8 or self.clock() >= deadline then
            break
        end
        self.player_cursor = (self.player_cursor - 1) % #self.order + 1
        local player = self.order[self.player_cursor]
        local state = self.players[player]
        self.player_cursor = self.player_cursor + 1
        local key = keys[state.cursor]
        state.cursor = state.cursor % #keys + 1
        local active, desired = state.active[key], state.desired[key]
        if not active and desired and desired.packets and state.applied[key] ~= desired then
            active = { job = desired, next_packet = 1 }
            state.active[key] = active
        end
        if active then
            local packet = active.job.packets[active.next_packet]
            if bytes + packet.max_bytes <= 24000 and self.send(player, packet) then
                bytes, messages = bytes + packet.max_bytes, messages + 1
                active.next_packet = active.next_packet + 1
                if active.next_packet > #active.job.packets then
                    state.applied[key], state.active[key] = active.job, nil
                end
            end
        end
    end
    self.bytes, self.messages = self.bytes + bytes, self.messages + messages
    return messages, bytes
end

function Sync:close()
    self.jobs, self.players, self.order = {}, {}, {}
end

return Sync
