local Context = require("wildwise/runtime/context")
local G = Context.G
local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local Templates = require("widgets/redux/templates")
local U = require("wildwise/core/util")
local Format = require("wildwise/ui/format")
local Facts = require("wildwise/services/facts")
local HUD = G.Class(Widget, function(self, client)
    Widget._ctor(self, "WildwiseHUD")
    self.client, self.bars, self.indicators, self.found = client, {}, {}, {}
    self:SetHAnchor(G.ANCHOR_LEFT); self:SetVAnchor(G.ANCHOR_BOTTOM); self:SetScaleMode(G.SCALEMODE_NONE)
    self.button = self:AddChild(Templates.StandardButton(function() client:toggle_menu() end, "Wildwise", { 118, 38 }))
    self.button:SetPosition(82, 55)
    self.notice = self:AddChild(Text(G.UIFONT, 24, "")); self.notice:SetClickable(false)
    self.queue = self:AddChild(Widget("WildwiseQueue")); self.queue:SetPosition(205, 170)
    self.queue_text = self.queue:AddChild(Text(G.UIFONT, 21, "")); self.queue_text:SetPosition(0, 46)
    self.pause = self.queue:AddChild(Templates.StandardButton(function()
        if client.queue.state == "paused" then client.queue:resume() else client.queue:pause() end
    end, client:L("pause"), { 110, 36 })); self.pause:SetPosition(-58, -18)
    self.clear = self.queue:AddChild(Templates.StandardButton(function() client.queue:cancel(); client:clear_preview() end,
        client:L("clear"), { 110, 36 })); self.clear:SetPosition(62, -18)
    self.plan = self:AddChild(Widget("WildwisePlan")); self.plan:SetPosition(210, 270)
    self.plan_text = self.plan:AddChild(Text(G.UIFONT, 21, "")); self.plan_text:SetPosition(0, 32)
    self.plan_go = self.plan:AddChild(Templates.StandardButton(function() client:execute_plan() end,
        client:L("execute_plan"), { 135, 36 })); self.plan_go:SetPosition(-70, -12)
    self.plan_cancel = self.plan:AddChild(Templates.StandardButton(function() client:clear_preview() end,
        client:L("cancel_plan"), { 135, 36 })); self.plan_cancel:SetPosition(75, -12)
    self.mount = self:AddChild(Widget("WildwiseBeefalo"))
    self.mount_bg = self.mount:AddChild(Image("images/global.xml", "square.tex"))
    self.mount_bg:SetSize(280, 215); self.mount_bg:SetTint(.07, .06, .05, .82)
    self.mount_text = self.mount:AddChild(Text(G.UIFONT, 21, "")); self.mount_text:SetClickable(false)
    self.mount:SetTooltip(client:L("beefalo"))
    self:StartUpdating()
end)
function HUD:bar(index)
    if self.bars[index] then return self.bars[index] end
    local bar = self:AddChild(Widget("WildwiseHealth")); bar:SetClickable(false)
    bar.bg = bar:AddChild(Image("images/global.xml", "square.tex")); bar.bg:SetSize(106, 12); bar.bg:SetTint(.08, .06, .04, .9)
    bar.fill = bar:AddChild(Image("images/global.xml", "square.tex")); bar.fill:SetTint(.78, .21, .16, 1)
    bar.text = bar:AddChild(Text(G.UIFONT, 18, "")); bar.text:SetPosition(0, 19)
    bar:SetClickable(false); self.bars[index] = bar; return bar
end
function HUD:update_hover(hoverer)
    local client = self.client
    if not self.hover_text then
        self.hover_text = hoverer:AddChild(Text(G.UIFONT, client.settings.info.font_size, ""))
        self.hover_text:SetColour(.96, .9, .73, 1); self.hover_text:SetClickable(false)
    end
    local fields = client.hover and client.cache:get(client.hover)
    if not fields or not client.config.info.enabled or not hoverer.shown then self.hover_text:Hide(); return end
    local detailed = G.TheInput:IsControlPressed(G.CONTROL_FORCE_INSPECT)
    local content = Format.lines(fields, client.settings, client.lang, detailed, client.visible_bars[client.hover])
    self.hover_text:SetString(content); self.hover_text:SetSize(client.settings.info.font_size)
    local _, height = self.hover_text:GetRegionSize()
    self.hover_text:SetPosition(0, -85 - height / 2); self.hover_text:Show()
end
function HUD:OnUpdate()
    local c, now = self.client, G.GetTime()
    if c.closed then return end
    local w, h = G.TheSim:GetScreenSize()
    self:SetScale(c.settings.ui_scale)
    local scale = c.settings.ui_scale
    c.visible_bars = {}
    for i, target in ipairs(c.selected or {}) do
        local bar, hp = self:bar(i), c.cache:peek(target)
        if U.valid(target) and hp and hp.health and hp.health_max and hp.health > 0 and hp.health_max > 0 then
            local x, y, z = target.Transform:GetWorldPosition()
            local sx, sy = G.TheSim:GetScreenPos(x, y + 2.2, z)
            if target.entity:IsVisible() and sx > 50 and sx < w - 50 and sy > 30 and sy < h - 30 then
                bar:SetPosition(sx / scale, sy / scale); bar:SetScale(c.settings.healthbars.scale)
                local fill = 100 * U.clamp(hp.health / hp.health_max, 0, 1)
                bar.fill:SetSize(math.max(.01, fill), 6); bar.fill:SetPosition((fill - 100) / 2, 0)
                bar.text:SetString(c.settings.healthbars.numbers and string.format("%.0f / %.0f", hp.health, hp.health_max) or "")
                bar:Show(); c.visible_bars[target] = true
            else bar:Hide() end
        else bar:Hide() end
    end
    for i = #(c.selected or {}) + 1, #self.bars do self.bars[i]:Hide() end
    if c.notice and now < (c.notice_until or 0) then
        self.notice:SetPosition(w / (2 * scale), h / scale - 130); self.notice:SetString(c.notice); self.notice:Show()
    else self.notice:Hide() end
    if #c.queue.tasks > 0 then
        local task = c.queue.tasks[1]
        self.queue_text:SetString(c:L(c.queue.state) .. " · " .. #c.queue.tasks .. "\n" ..
            (task.action or task.recipe or "") .. "\n" .. c:L(c.queue.reason))
        self.pause:SetText(c:L(c.queue.state == "paused" and "resume" or "pause")); self.queue:Show()
    else self.queue:Hide() end
    if c.plan_points then
        local valid = 0; for _, record in ipairs(c.plan_points) do if record.valid then valid = valid + 1 end end
        self.plan_text:SetString(c:L("enabled_points") .. ": " .. valid .. " / " .. #c.plan_points); self.plan:Show()
    else self.plan:Hide() end
    local mount = c.mount and c.cache:peek(c.mount)
    if mount and c.config.beefalo.enabled and c.settings.beefalo.visible then
        if self.last_mount ~= c.mount then self.hunger_active = (mount.hunger or 0) >= c.settings.beefalo.hunger_threshold; self.last_mount = c.mount end
        if mount.hunger and mount.hunger >= c.settings.beefalo.hunger_threshold then self.hunger_active = true end
        if mount.hunger and mount.hunger <= 0 then self.hunger_active = false end
        local lines = { c:L("beefalo") }
        for _, key in ipairs({ "health", "domestication", "obedience", "tendency", "ride_time", "saddle_uses", "hunger" }) do
            if mount[key] ~= nil and (key ~= "hunger" or self.hunger_active) then
                lines[#lines + 1] = c:L(key) .. ": " .. Format.value(mount[key], Facts.schema[key], c.lang)
            end
        end
        self.mount:SetPosition(w / scale - 420 + (c.settings.beefalo.offset_x or 0), h / scale - 230 + (c.settings.beefalo.offset_y or 0))
        self.mount_text:SetString(table.concat(lines, "\n")); self.mount:Show()
    else self.mount:Hide(); self.last_mount = nil end
    -- 定位结果只保留 8 秒，消失/失去可见性后立即隐藏，不改变实体材质或战斗高亮。
    for target, expires in pairs(c.found) do
        if not U.valid(target) or now >= expires then
            c.found[target] = nil
            if self.found[target] then self.found[target]:Kill(); self.found[target] = nil end
        else
            local text = self.found[target]
            if not text then text = self:AddChild(Text(G.UIFONT, 22, "")); text:SetClickable(false); self.found[target] = text end
            local x, y, z = target.Transform:GetWorldPosition()
            local sx, sy = G.TheSim:GetScreenPos(x, y + 1, z)
            text:SetString("◆ " .. c:L("found")); text:SetPosition(sx / scale, sy / scale)
            if target.entity:IsVisible() then text:Show() else text:Hide() end
        end
    end
    self:update_indicators(w, h, scale)
end
function HUD:update_indicators(w, h, scale)
    local c = self.client
    local active = c.config.map.enabled and (c.settings.map.indicators == "always" or
        (c.settings.map.indicators == "scoreboard" and G.TheInput:IsControlPressed(G.CONTROL_SHOW_PLAYER_STATUS)))
    local index = 0
    if active then
        for _, record in ipairs(c.map.players or {}) do
            if record.userid ~= c.player.userid and record.shard == c.shard and record.x
                and not U.muted(G, record.userid) then
                local sx, sy = G.TheSim:GetScreenPos(record.x, 0, record.z)
                if sx < 80 or sx > w - 80 or sy < 80 or sy > h - 80 then
                    index = index + 1
                    local text = self.indicators[index]
                    if not text then text = self:AddChild(Text(G.UIFONT, 20, "")); text:SetClickable(false); self.indicators[index] = text end
                    text:SetString(record.name); text:SetPosition(U.clamp(sx, 80, w - 80) / scale, U.clamp(sy, 80, h - 80) / scale); text:Show()
                end
            end
        end
    end
    for i = index + 1, #self.indicators do self.indicators[i]:Hide() end
end
return HUD
