local Context = require("wildwise/runtime/context")
local Config = require("wildwise/core/config")
local G = Context.G
local Screen = require("widgets/screen")
local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Templates = require("widgets/redux/templates")
local Format = require("wildwise/ui/format")
local Menu = G.Class(Screen, function(self, client)
    Screen._ctor(self, "WildwiseMenu")
    self.client, self.tab, self.page = client, "info", 1
    self.root = self:AddChild(Widget("WildwiseMenuRoot"))
    self.root:SetHAnchor(G.ANCHOR_MIDDLE); self.root:SetVAnchor(G.ANCHOR_MIDDLE)
    self.root:SetScaleMode(G.SCALEMODE_PROPORTIONAL)
    self.frame = self.root:AddChild(Templates.CurlyWindow(820, 560, "Wildwise"))
    self.frame:SetScale(1.05, 1.15)
    self.content = self.root:AddChild(Widget("WildwiseMenuContent"))
    self.tabs = {}
    for i, tab in ipairs({ "info", "maps", "items", "queue", "diagnostics" }) do
        local key = tab
        local button = self.root:AddChild(Templates.StandardButton(function() self.tab, self.page = key, 1; self:refresh() end,
            client:L(key), { 135, 40 }))
        button:SetPosition(-300 + (i - 1) * 150, 208); self.tabs[i] = button
    end
    self.close_button = self.root:AddChild(Templates.StandardButton(function() self:close() end, client:L("close"), { 140, 40 }))
    self.close_button:SetPosition(0, -232)
    self.default_focus = self.tabs[1]
    self:refresh()
end)
function Menu:line(text, y)
    local label = self.content:AddChild(Text(G.UIFONT, 22, text)); label:SetPosition(0, y); return label
end
function Menu:choice(key, values, y, permission)
    local c, button = self.client, nil
    local reason = permission and not Config.get(c.config, permission) and c:L("restricted")
    if key == "map.share_position" or key == "map.share_exploration" then
        local positions, exploration = require("wildwise/core/config").share(c.config, G.TheNet:GetServerGameMode(), G.TheNet:GetPVPEnabled())
        if (key == "map.share_position" and not positions) or (key == "map.share_exploration" and not exploration) then reason = c:L("restricted") end
    end
    local module = (permission or key):match("^[^.]+")
    if c.conflicts and c.conflicts[module] then reason = c:L("conflict") .. ": " .. c.conflicts[module] end
    local function text()
        local v = Config.get(c.settings, key)
        return c:L(key) .. ": " .. (type(v) == "boolean" and c:L(v and "on" or "off") or c:L(v))
    end
    button = self.content:AddChild(Templates.StandardButton(function()
        if reason then return end
        local index = 1; for i, v in ipairs(values) do if v == Config.get(c.settings, key) then index = i % #values + 1 end end
        c:set(key, values[index]); button:SetText(text())
    end, text(), { 450, 36 }))
    button:SetPosition(0, y)
    if reason then button:Disable(); button:SetTooltip(reason) end
    self.focus_buttons[#self.focus_buttons + 1] = button
end
function Menu:readonly(key, y)
    local c = self.client
    local value = Config.get(c.config, key)
    self:line(c:L(key) .. ": " .. (type(value) == "boolean" and c:L(value and "on" or "off") or tostring(value)) .. " · " .. c:L("server_rule"), y)
end
function Menu:refresh()
    self.content:KillAllChildren(); self.focus_buttons = {}
    local c = self.client
    if self.tab == "info" then
        if self.page == 1 then
            self:choice("info.preset", { "minimal", "standard", "detailed" }, 145)
            self:choice("healthbars.enabled", { true, false }, 103, "healthbars.enabled")
            self:choice("healthbars.hostile_scope", { "self", "followers", "nearby", "nearby_followers" }, 61, "healthbars.enabled")
            self:choice("healthbars.numbers", { true, false }, 19, "healthbars.enabled")
            self:choice("beefalo.visible", { true, false }, -23, "beefalo.enabled")
            self:choice("info.font_size", { 18, 22, 26, 30 }, -65)
            self:choice("ui_scale", { .75, 1, 1.25, 1.5 }, -107)
            self:choice("language", { "auto", "zh", "en" }, -149)
        elseif self.page == 2 then
            self:choice("healthbars.limit", { 4, 8, 12, 16, 20 }, 145)
            self:choice("healthbars.scale", { .75, 1, 1.25, 1.5 }, 103)
            self:readonly("info.container_contents", 61); self:readonly("info.attack_range", 19)
            self:readonly("info.world_events", -23)
            local fields = c.cache:peek(c.player)
            self:line(Format.lines(fields, { info = { preset = "detailed" } }, c.lang, true, false), -115):SetSize(18)
        elseif self.page == 3 then
            self:line(c:L("recipe_query"), 150)
            local choices = require("wildwise/services/recipes").inventory_choices(c.player, require("cooking"))
            c.recipe_slots = c.recipe_slots or {}
            for i = 1, 4 do
                local slot = i
                if not c.recipe_slots[slot] then c.recipe_slots[slot] = choices[1] end
                local button = self.content:AddChild(Templates.StandardButton(function()
                    local current = 0; for j, name in ipairs(choices) do if name == c.recipe_slots[slot] then current = j end end
                    c.recipe_slots[slot] = choices[current % math.max(1, #choices) + 1]; self:refresh()
                end, slot .. ": " .. (c.recipe_slots[slot] or c:L("unknown")), { 450, 36 }))
                button:SetPosition(0, 108 - (slot - 1) * 43)
            end
            local query = self.content:AddChild(Templates.StandardButton(function()
                c:send("recipes", nil, { cooker = "cookpot", ingredients = c.recipe_slots })
            end, c:L("query"), { 200, 36 })); query:SetPosition(0, -68)
            local results = {}
            for _, result in ipairs(c.recipe_results and c.recipe_results.results or {}) do
                results[#results + 1] = G.STRINGS.NAMES[result.name:upper()] or result.name
            end
            self:line(table.concat(results, " / "), -120)
        elseif self.page == 4 then
            local keys = { "combat", "food", "equipment", "progress", "farm", "follower", "container", "world" }
            for i, category in ipairs(keys) do
                local key = category
                local button = self.content:AddChild(Templates.StandardButton(function()
                    c.settings.info.categories[key] = c.settings.info.categories[key] == false
                    c:save_settings(); self:refresh()
                end, c:L(key) .. ": " .. c:L(c.settings.info.categories[key] == false and "off" or "on"), { 450, 36 }))
                button:SetPosition(0, 145 - (i - 1) * 42)
            end
        else
            self:choice("beefalo.offset_x", { -300, -200, -100, 0, 100, 200, 300 }, 145, "beefalo.enabled")
            self:choice("beefalo.offset_y", { -200, -100, 0, 100, 200 }, 97, "beefalo.enabled")
            self:choice("beefalo.hunger_threshold", { 0, 5, 15, 25 }, 49, "beefalo.enabled")
        end
    elseif self.tab == "maps" then
        self:choice("map.share_position", { true, false }, 145, "map.enabled")
        self:choice("map.share_exploration", { true, false }, 103, "map.enabled")
        self:choice("map.indicators", { "scoreboard", "always", "off" }, 61, "map.enabled")
        self:choice("map.ping_kind", { "location", "danger", "resource", "rally" }, 19, "map.enabled")
        local roster = {}
        for _, record in ipairs(c.map.players or {}) do if record.shard ~= c.shard then roster[#roster + 1] = record.name .. " · " .. record.shard end end
        self:line(table.concat(roster, "\n"), -65)
        local clear = self.content:AddChild(Templates.StandardButton(function()
            for _, ping in ipairs(c.map.pings or {}) do
                if ping.owner == c.player.userid then c:send("delete_ping", nil, { id = ping.id }) end
            end
        end, c:L("clear"), { 180, 36 })); clear:SetPosition(-135, -150)
        local user = G.TheNet:GetClientTableForUser(c.player.userid or "")
        if user and user.admin then
            local all = self.content:AddChild(Templates.StandardButton(function()
                c:send("delete_ping", nil, { id = 0 })
            end, c:L("clear_all"), { 340, 36 })); all:SetPosition(165, -150)
        end
    elseif self.tab == "items" then
        self:choice("items.pickup", { false, true }, 145, "items.pickup_allowed")
        self:readonly("items.stack_world", 95); self:readonly("items.stack_manual", 45); self:readonly("items.stack_loaded", -5)
        self:readonly("signs.enabled", -55)
        local find = self.content:AddChild(Templates.StandardButton(function()
            if c.last_hover then c:send("find", nil, { prefab = c.last_hover.prefab }); self:close() end
        end, c:L("find"), { 250, 36 })); find:SetPosition(0, -115)
        if not c.config.info.container_contents then find:Disable(); find:SetTooltip(c:L("restricted")) end
    elseif self.tab == "queue" then
        self:line(c:L(c.queue.state) .. " · " .. #c.queue.tasks .. " / " .. c.config.queue.limit, 145)
        self:line(c:L(c.queue.reason), 103)
        self:choice("queue.farm_grid", { 2, 3, 4 }, 61, "queue.enabled")
        for i, key in ipairs({ "menu_key", "queue.modifier_key", "beefalo.toggle_key" }) do
            local id = key
            local button = self.content:AddChild(Templates.StandardButton(function() self.binding = id; self:line(c:L("rebind"), -165) end,
                c:L(id) .. ": " .. Config.get(c.settings, id), { 450, 36 }))
            button:SetPosition(0, 20 - (i - 1) * 44)
        end
    else
        local diag = c.diagnostics or {}
        self:line("Wildwise 0.2.0 · " .. (c.shard or "…"), 145)
        self:line("Cache " .. c.cache.size .. "/256 · " .. "RPC bytes " .. (diag.bytes or 0), 95)
        self:line("Observers " .. (diag.observations or 0), 45)
        local conflicts = {}; for key, value in pairs(c.conflicts or {}) do conflicts[#conflicts + 1] = c:L(key) .. ": " .. value end
        self:line(table.concat(conflicts, "\n"), -20)
        self:line(c.lang == "zh" and "诊断只写本地，不上传日志。" or "Diagnostics stay local; no uploads.", -155)
    end
    if self.tab == "info" then
        local more = self.content:AddChild(Templates.StandardButton(function() self.page = self.page % 5 + 1; self:refresh() end,
            c:L("more") .. " " .. self.page .. "/5", { 110, 36 }))
        more:SetPosition(305, -160)
    end
    -- 使用原版焦点导航，Esc 返回；进入菜单即暂停，关闭菜单不擅自恢复自动执行。
    for i, button in ipairs(self.focus_buttons) do
        button:SetFocusChangeDir(G.MOVE_DOWN, self.focus_buttons[i + 1] or self.close_button)
        button:SetFocusChangeDir(G.MOVE_UP, self.focus_buttons[i - 1] or self.tabs[1])
    end
end
function Menu:OnRawKey(key, down)
    if self.binding and not down then
        self.client:set(self.binding, key); self.binding = nil; self:refresh(); return true
    end
    return Menu._base.OnRawKey(self, key, down)
end
function Menu:OnControl(control, down)
    if Menu._base.OnControl(self, control, down) then return true end
    if not down and control == G.CONTROL_CANCEL then self:close(); return true end
    return false
end
function Menu:close()
    if self.client.menu ~= self then return end
    self.client.menu = nil; G.TheFrontEnd:PopScreen(self)
end
return Menu
