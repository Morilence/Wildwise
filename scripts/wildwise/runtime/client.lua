local Context = require("wildwise/runtime/context")
local Config = require("wildwise/core/config")
local U = require("wildwise/core/util")
local LRU = require("wildwise/core/lru")
local Lifetime = require("wildwise/core/lifetime")
local Hooks = require("wildwise/core/hooks")
local Protocol = require("wildwise/core/protocol")
local MapTransfer = require("wildwise/core/map_transfer")
local Facts = require("wildwise/services/facts")
local Health = require("wildwise/services/health")
local Queue = require("wildwise/services/queue")
local Planner = require("wildwise/services/planner")
local Actions = require("wildwise/runtime/actions")
local Strings = require("wildwise/ui/strings")
local json = require("json")
local Client = {}
Client.__index = Client

-- 创建当前玩家的客户端会话、UI、输入与统一观察缓存。
function Client.new(controls, G, config)
    local self = setmetatable({
        controls = controls,
        G = G,
        player = controls.owner,
        config = Config.copy(config),
        settings = Config.settings(config),
        scope = Lifetime.new(),
        cache = LRU.new(256),
        subscribed = {},
        threats = {},
        visible_bars = {},
        seq = 0,
        received = 0,
        next_hello = 0,
        next_heartbeat = 0,
        threat_order = 0,
        focused = true,
        previews = {},
        map = { players = {}, pings = {}, pairs = {} },
    }, Client)
    self.found = {}
    self.nonce = tostring(G.GetTime()) .. ":" .. tostring(math.random(1000000))
    self.lang = Strings.language(self.settings.language, G)
    self.adapter = Actions.create(self, G)
    self.queue = Queue.new(self.adapter, config.queue.limit)
    self.hud = controls:AddChild(require("wildwise/ui/hud")(self))
    self.scope:add(function()
        self.hud:Kill()
    end)
    self.scope:listen(self.player, "onremove", function()
        self:close()
    end)
    self.scope:task(self.player:DoPeriodicTask(0.1, function()
        self:tick()
    end))
    Hooks.after(self.scope, G, "OnFocusLost", function()
        self.focused = false
        self.input_epoch = (self.input_epoch or 0) + 1
        self.queue:pause("input_focus")
        self:clear_preview()
    end)
    Hooks.after(self.scope, G, "OnFocusGained", function()
        self.focused = true
    end)
    require("wildwise/runtime/input").attach(self, G)
    -- 新结构使用独立存储键，不读取旧平铺配置。
    G.TheSim:GetPersistentString("wildwise_client_v2", function(ok, bytes)
        if not ok or self.closed then
            return
        end
        local decoded, settings = pcall(json.decode, bytes)
        if not decoded or type(settings) ~= "table" then
            return
        end
        -- 共享开关属于当前世界，由 welcome 同步；本地偏好回调先后顺序不能覆盖它们。
        if type(settings.map) == "table" then
            settings.map.share_position, settings.map.share_exploration = nil, nil
        end
        Config.restore(self.settings, settings)
        self.lang = Strings.language(self.settings.language, G)
        self:sync_preferences()
    end)
    return self
end

-- 按当前语言读取显示文本。
function Client:L(key)
    return Strings.get(key, self.lang)
end

-- 发送受限协议消息；本地主机同步登记后再执行原版动作。
function Client:send(kind, target, data)
    if self.closed or (not self.session and kind ~= "hello") then
        return
    end
    self.seq = self.seq + 1
    local bytes = Protocol.encode(json, kind, self.session or "hello", self.seq, data)
    if bytes then
        -- 本地主机同步登记动作观察，再进入原生 DoAction，避免本地执行早于 RPC 到达。
        local world = self.G.TheWorld
        if world.ismastersim and world.components.wildwise_world then
            world.components.wildwise_world:Request(self.player, target, bytes)
        else
            self.G.SendModRPCToServer(self.G.GetModRPC("wildwise", "request"), target, bytes)
        end
    end
end

-- 接收当前会话的新消息，更新缓存或完整地图，忽略迟到数据。
function Client:receive(target, bytes)
    local msg = Protocol.decode(json, bytes)
    if not msg or self.closed then
        return
    end
    if msg.kind == "welcome" then
        if msg.data.nonce ~= self.nonce then
            return
        end
        if self.session == msg.session and msg.seq <= self.received then
            return
        end
        self.session, self.received = msg.session, msg.seq
        self.server_seen = self.G.GetTime()
        self.config, self.conflicts, self.shard = msg.data.config, msg.data.conflicts, msg.data.shard
        self.settings.map.share_position = msg.data.preferences.position
        self.settings.map.share_exploration = msg.data.preferences.exploration
        self:sync_preferences()
        if not self.settings.first_tip_seen then
            self.notice, self.notice_until = self:L("first_tip"), self.G.GetTime() + 9
            self.settings.first_tip_seen = true
            self:save_settings()
        end
        for feature, id in pairs(self.conflicts or {}) do
            self.notice, self.notice_until =
                self:L("conflict") .. ": " .. self:L(feature) .. " (" .. id .. ")", self.G.GetTime() + 12
        end
        return
    end
    if msg.session ~= self.session or msg.seq <= self.received then
        return
    end
    self.received = msg.seq
    if msg.kind == "snapshot" or msg.kind == "delta" then
        if not U.valid(target) or not self.subscribed[target] then
            return
        end
        local record = msg.kind == "snapshot" and {} or self.cache:peek(target)
        if not record then
            return
        end
        local fields = Facts.sanitize(msg.data.fields)
        for key in pairs(type(msg.data.fields) == "table" and msg.data.fields or {}) do
            if Facts.schema[key] then
                record[key] = fields[key]
            end
        end
        for _, key in ipairs(type(msg.data.removed) == "table" and msg.data.removed or {}) do
            if type(key) == "string" then
                record[key] = nil
            end
        end
        self.cache:set(target, record)
    elseif msg.kind == "invalidate" then
        self.cache:remove(target)
        self.threats[target] = nil
    elseif msg.kind == "threat" and U.valid(target) then
        local state = self.threats[target]
        if not state then
            if U.count(self.threats) >= 128 then
                return
            end
            self.threat_order = self.threat_order + 1
            state = { order = self.threat_order, last_hostile = -math.huge }
            self.threats[target] = state
        end
        state.hostile, state.direct, state.at = msg.data.hostile, msg.data.direct, self.G.GetTime()
        if state.hostile then
            state.last_hostile = state.at
        end
    elseif msg.kind == "map" then
        self:apply_map(msg.data)
    elseif msg.kind == "map_begin" or msg.kind == "map_chunk" or msg.kind == "map_end" then
        local snapshot
        local channel = msg.data.channel or "legacy"
        if not ({ legacy = true, players = true, pairs = true, pings = true, fires = true })[channel] then
            return
        end
        self.map_pending = self.map_pending or {}
        self.map_pending[channel], snapshot = MapTransfer.receive(self.map_pending[channel], msg.kind, msg.data)
        if snapshot then
            self:apply_map(snapshot)
        end
    elseif msg.kind == "recipes" then
        if msg.data.request == self.recipe_request then
            self.recipe_results = msg.data
            if self.menu then
                self.menu:refresh()
            end
        end
    elseif msg.kind == "found" and U.valid(target) then
        self.found[target] = self.G.GetTime() + 8
    elseif msg.kind == "action_result" then
        self.adapter.result(msg.data)
    elseif msg.kind == "cancel" then
        self.input_epoch = (self.input_epoch or 0) + 1
        self.queue:cancel(msg.data.reason)
        self:clear_preview()
    elseif msg.kind == "notice" then
        self.notice, self.notice_until = self:L(msg.data.reason), self.G.GetTime() + 5
    elseif msg.kind == "heartbeat" then
        self.diagnostics = msg.data
        self.server_seen = self.G.GetTime()
    end
end

-- 只原子替换本次完整收到的频道；位置更新不会擦掉正在接收或已经显示的配对。
function Client:apply_map(snapshot)
    local map = U.copy(self.map)
    for _, key in ipairs({ "players", "pings", "fires", "pairs" }) do
        if type(snapshot[key]) == "table" then
            map[key] = snapshot[key]
            if self.map_pending then
                self.map_pending[key] = nil
            end
        end
    end
    self.map = map
end

-- 更换食材或锅类型时作废旧结果及仍在网络途中的旧查询。
function Client:clear_recipe_results()
    self.recipe_request = (self.recipe_request or 0) + 1
    self.recipe_results = nil
end

-- 提交当前四格食材与锅类型；响应必须对应当前请求才允许显示。
function Client:query_recipes()
    self:clear_recipe_results()
    self:send("recipes", nil, {
        cooker = self.recipe_cooker or "cookpot",
        ingredients = self.recipe_slots or {},
        request = self.recipe_request,
    })
end

-- 检查游戏窗口及 HUD 输入焦点，避免聊天和菜单触发队列。
function Client:input_ready()
    return not self.closed
        and self.focused
        and self.player.HUD
        and not self.player.HUD:HasInputFocus()
        and not self.G.TheFrontEnd.textProcessorWidget
end

-- 按周期合并观察需求、续租订阅并推进单一队列执行器。
function Client:tick()
    local G, now = self.G, self.G.GetTime()
    if not U.valid(self.player) then
        self:close()
        return
    end
    if not self.session then
        if now >= self.next_hello then
            self.next_hello = now + 2
            self:send("hello", nil, { nonce = self.nonce })
        end
        return
    end
    if now >= self.next_heartbeat then
        self.next_heartbeat = now + 3
        self:send("heartbeat", nil, {})
    end
    if self.server_seen and now - self.server_seen > 10 then
        self.queue:pause("disconnected")
    end
    self.hover = self:input_ready() and G.TheInput:GetWorldEntityUnderMouse() or nil
    local hud_entity = self:input_ready() and G.TheInput:GetHUDEntityUnderMouse()
    local widget = hud_entity and hud_entity.widget
    -- 库存图标本身是 UI 实体；沿控件父链找到真实物品，不能把 UI 引用发给服务器。
    for _ = 1, 8 do
        if not widget then
            break
        end
        if widget.item then
            self.hover = widget.item
            break
        end
        widget = widget.parent
    end
    if self.hover and not self.hover.Transform then
        self.hover = nil
    end
    if self.hover then
        self.last_hover = self.hover
    end
    local wanted = {}
    if U.valid(self.hover) and self.config.info.enabled then
        wanted[self.hover] = "hover"
    end
    local mount = U.call(self.player.replica.rider, "GetMount")
    self.mount = U.valid(mount) and mount.prefab == "beefalo" and mount or nil
    if self.mount and self.config.beefalo.enabled and self.settings.beefalo.visible then
        wanted[self.mount] = "beefalo"
    end
    if self.menu and self.config.info.enabled then
        wanted[self.player] = "menu"
    end
    local sw, sh = G.TheSim:GetScreenSize()
    for target, state in pairs(self.threats) do
        if not U.valid(target) or now - state.at > self.settings.healthbars.linger_seconds + 3 then
            self.threats[target] = nil
        else
            local x, y, z = target.Transform:GetWorldPosition()
            local sx, sy = G.TheSim:GetScreenPos(x, y + 2.2, z)
            state.visible = target.entity:IsVisible()
                and G.CanEntitySeeTarget(self.player, target)
                and sx > 50
                and sx < sw - 50
                and sy > 30
                and sy < sh - 30
            state.distance = U.distance(self.player, target)
            local record = self.cache:peek(target)
            state.dead = record and record.health and record.health <= 0
        end
    end
    self.selected = self.config.healthbars.enabled
            and self.settings.healthbars.enabled
            and Health.select(
                self.threats,
                self.hover,
                math.min(self.settings.healthbars.limit, 20),
                now,
                self.settings.healthbars.linger_seconds
            )
        or {}
    for _, target in ipairs(self.selected) do
        if not wanted[target] then
            wanted[target] = "health"
        end
    end
    -- Hover、主动血条、骑乘 HUD 合并成一个实体订阅，显示入口不各自发请求。
    for target in pairs(self.subscribed) do
        if not wanted[target] or not U.valid(target) then
            if U.valid(target) then
                self:send("unsubscribe", target, {})
            end
            self.subscribed[target] = nil
        end
    end
    for target, mask in pairs(wanted) do
        local sub = self.subscribed[target]
        if not sub or sub.mask ~= mask or now - sub.at > 2 then
            self.subscribed[target] = { mask = mask, at = now }
            self:send("subscribe", target, { mask = mask })
        end
    end
    if not self:input_ready() and self.queue.state == "running" then
        self.queue:pause("input_focus")
    end
    self:update_preview()
    self.queue:tick(now)
end

-- 保存个人偏好到本地，不改写服主配置。
function Client:save_settings()
    self.G.TheSim:SetPersistentString("wildwise_client_v2", json.encode(self.settings), false)
end

-- 握手后同步个人拾取和血条偏好，由服务器再次检查权限。
function Client:sync_preferences()
    if not self.session then
        return
    end
    for _, key in ipairs({ "items.pickup", "healthbars.hostile_scope", "healthbars.enabled" }) do
        self:send("preference", nil, { key = key, value = Config.get(self.settings, key) })
    end
end

-- 应用菜单提供的合法偏好值，必要时同步到服务器并保存。
function Client:set(key, value)
    Config.set(self.settings, key, value)
    if key == "language" then
        self.lang = Strings.language(value, self.G)
    end
    if
        key == "items.pickup"
        or key == "map.share_position"
        or key == "map.share_exploration"
        or key == "healthbars.hostile_scope"
        or key == "healthbars.enabled"
    then
        self:send("preference", nil, { key = key, value = value })
    end
    self:save_settings()
end

-- 打开或关闭原生设置窗口；打开时暂停队列。
function Client:toggle_menu()
    if self.menu then
        self.menu:close()
        return
    end
    self.queue:pause("input_focus")
    self.menu = require("wildwise/ui/menu")(self)
    self.G.TheFrontEnd:PushScreen(self.menu)
end

-- 销毁本客户端创建的临时轮廓，清除计划状态。
function Client:clear_preview()
    for _, preview in ipairs(self.previews) do
        if U.valid(preview) then
            preview:Remove()
        end
    end
    self.previews, self.plan_points, self.plan_validate = {}, nil, nil
end

-- 按原版网格与部署规则生成有界计划，不立即执行。
function Client:plan(a, b)
    self:clear_preview()
    local G, inv = self.G, self.player.replica.inventory
    local active, tool = inv:GetActiveItem(), inv:GetEquippedItem(G.EQUIPSLOTS.HANDS)
    local action = Actions.plan_mode(active, tool)
    local till = action == "TILL"
    if not action then
        return
    end
    local item = active and active.replica.inventoryitem
    local spacing = till and (4 / self.settings.queue.farm_grid)
        or (item and math.max(0.5, item:DeploySpacingRadius()) or 4)
    local tile = action == "TERRAFORM" or action == "POUR_WATER_GROUNDTILE" or action == "DEPLOY_TILEARRIVE"
    if tile then
        spacing = 4
    end
    if active and active:HasTag("groundtile") then
        spacing = 4
    end
    if active and active:HasTag("wallbuilder") then
        spacing = 1
    end
    -- 农田格子锚定原版地块，地皮锚定地块中心，墙体使用原版半米中心。
    local cx, _, cz = G.TheWorld.Map:GetTileCenterPoint(a.x, 0, a.z)
    local ox, oz
    if till then
        ox, oz = cx - 2 + spacing / 2, cz - 2 + spacing / 2
    elseif tile or (active and active:HasTag("groundtile")) then
        ox, oz = cx, cz
    elseif active and active:HasTag("wallbuilder") then
        ox, oz = 0.5, 0.5
    end
    if ox then
        a, b = Planner.bounds(a, b, spacing, ox, oz)
        if not a then
            self.notice, self.notice_until = self:L("no_points"), G.GetTime() + 5
            return
        end
    end

    local function validate(point)
        if not point or (active and not U.valid(active)) then
            return false
        end
        return Actions.plan_valid(action, point, self.player, active, G)
    end
    local points, reason = Planner.grid(a, b, spacing, self.config.queue.limit, validate, U.platform(self.player))
    if not points then
        self.notice, self.notice_until = self:L(reason), G.GetTime() + 5
        return
    end
    self.plan_points, self.plan_action, self.plan_material = points, action, active and active.prefab
    self.plan_validate = validate
    for _, record in ipairs(points) do
        -- 原生轮廓使用叉号区分无效点，避免只靠红绿表达；没有鼠标跟随的 placer 组件。
        local preview = G.SpawnPrefab("axisalignedplacement_outline")
        if preview then
            preview.AnimState:SetScale(math.min(spacing, 2), math.min(spacing, 2))
            preview.persists = false
            record.preview = preview
            self.previews[#self.previews + 1] = preview
        end
    end
    self:update_preview()
end

-- 重新投影移动平台上的计划并检查点位有效性。
function Client:update_preview()
    if not self.plan_points or not self.plan_validate then
        return
    end
    for _, record in ipairs(self.plan_points) do
        local point = Planner.project(record)
        record.valid = self.plan_validate(point) == true
        if U.valid(record.preview) then
            if point then
                record.preview.Transform:SetPosition(point.x, point.y or 0, point.z)
                record.preview.AnimState:PlayAnimation(record.valid and "unit" or "unit_x")
                record.preview.AnimState:SetMultColour(
                    record.valid and 0.4 or 1,
                    record.valid and 1 or 0.35,
                    0.35,
                    0.65
                )
            else
                record.preview:Hide()
            end
        end
    end
end

-- 将有效预览点加入队列，随后清理全部预览实体。
function Client:execute_plan()
    for _, record in ipairs(self.plan_points or {}) do
        if record.valid then
            self.queue:add({ plan = record, action = self.plan_action, right = true, material = self.plan_material })
        end
    end
    self:clear_preview()
end

-- 关闭客户端会话并释放输入、监听、观察与辅助 UI；可重复调用。
function Client:close()
    if self.closed then
        return
    end
    self.queue:cancel("disconnected")
    for target in pairs(self.subscribed) do
        if U.valid(target) then
            self:send("unsubscribe", target, {})
        end
    end
    self.closed = true
    if self.menu then
        self.menu:close()
    end
    self:clear_preview()
    self.scope:close()
    self.cache:clear()
    if Context.client == self then
        Context.client = nil
    end
end

-- 注册原生控件扩展入口，在 HUD 重建时替换旧客户端。
function Client.register(api, G, config)
    api.AddClassPostConstruct("widgets/controls", function(controls)
        controls.inst:DoTaskInTime(0, function()
            if not controls.owner or controls.owner ~= G.ThePlayer then
                return
            end
            if Context.client then
                Context.client:close()
            end
            Context.client = Client.new(controls, G, config)
        end)
    end)
    api.AddClassPostConstruct("widgets/hoverer", function(hoverer)
        local original = hoverer.OnUpdate
        hoverer.OnUpdate = function(self, ...)
            original(self, ...)
            local client = Context.client
            if client and client.hud then
                client.hud:update_hover(self)
            end
        end
    end)
    api.AddClassPostConstruct("screens/mapscreen", function(screen)
        if Context.client then
            require("wildwise/ui/map").attach(screen, Context.client, G)
        end
    end)
end
return Client
