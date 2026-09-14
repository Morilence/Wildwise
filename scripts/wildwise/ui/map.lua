local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local Templates = require("widgets/redux/templates")
local Hooks = require("wildwise/core/hooks")
local Lifetime = require("wildwise/core/lifetime")
local U = require("wildwise/core/util")
local M = {}
local palette = {
    { 0.93, 0.65, 0.28 },
    { 0.4, 0.8, 0.94 },
    { 0.75, 0.53, 0.94 },
    { 0.5, 0.87, 0.46 },
    { 0.94, 0.4, 0.38 },
    {
        0.96,
        0.86,
        0.44,
    },
}

-- 扩展原生地图投影和标记输入，关闭地图时释放辅助控件。
function M.attach(screen, client, G)
    local scope = Lifetime.new()
    local root = screen:AddChild(Widget("WildwiseMapMarkers"))
    root:SetHAnchor(G.ANCHOR_MIDDLE)
    root:SetVAnchor(G.ANCHOR_MIDDLE)
    local markers = {}
    -- 固定在地图中央的四向选择器，保存打开时的世界坐标，避免选按钮时坐标漂移。
    local wheel = root:AddChild(Widget("WildwisePingWheel"))
    wheel.buttons = {}
    local wheel_bg = wheel:AddChild(Image("images/global.xml", "square.tex"))
    wheel_bg:SetSize(425, 220)
    wheel_bg:SetTint(0.07, 0.06, 0.05, 0.94)
    wheel.title = wheel:AddChild(Text(G.UIFONT, 20, client:L("select_ping")))
    for i, entry in ipairs({
        { "location", 0, 72 },
        { "danger", 125, 0 },
        { "resource", 0, -72 },
        { "rally", -125, 0 },
    }) do
        local kind = entry[1]
        local button = wheel:AddChild(Templates.StandardButton(function()
            if wheel.point then
                client:send("ping", nil, { kind = kind, x = wheel.point.x, z = wheel.point.z })
                client:set("map.ping_kind", kind)
            end
            wheel:Hide()
            wheel.point = nil
        end, client:L(kind), { 155, 40 }))
        button:SetPosition(entry[2], entry[3])
        wheel.buttons[i] = button
    end
    for i, button in ipairs(wheel.buttons) do
        button:SetFocusChangeDir(G.MOVE_RIGHT, wheel.buttons[i % 4 + 1])
        button:SetFocusChangeDir(G.MOVE_DOWN, wheel.buttons[i % 4 + 1])
        button:SetFocusChangeDir(G.MOVE_LEFT, wheel.buttons[(i + 2) % 4 + 1])
        button:SetFocusChangeDir(G.MOVE_UP, wheel.buttons[(i + 2) % 4 + 1])
    end
    wheel:Hide()
    scope.wheel = wheel

    local function make(i)
        if markers[i] then
            return markers[i]
        end
        local widget = root:AddChild(Widget("WildwiseMapMarker"))
        widget.icon = widget:AddChild(Image("images/hud.xml", "cursor02.tex"))
        widget.icon:SetSize(24, 24)
        widget.text = widget:AddChild(Text(G.UIFONT, 20, ""))
        widget.text:SetPosition(0, 23)
        markers[i] = widget
        return widget
    end
    Hooks.after(scope, screen, "OnUpdate", function()
        local count = 0
        if client.config.map.enabled then
            local function draw(x, z, label, colour, tooltip)
                if not U.finite(x) or not U.finite(z) then
                    return
                end
                count = count + 1
                local widget = make(count)
                -- 地图投影、缩放和旋转全部委托原版；这里仅将归一化坐标转换成控件坐标。
                local mx, my = screen.minimap:WorldPosToMapPos(x, z, 0)
                widget:SetPosition(screen:MapPosToWidgetPos(G.Vector3(mx, my, 0)))
                widget.text:SetString(label)
                widget.icon:SetTint(colour[1], colour[2], colour[3], 1)
                widget:SetTooltip(tooltip or label)
                widget:Show()
            end
            for _, player in ipairs(client.map.players or {}) do
                if
                    client.settings.map.show_players ~= false
                    and player.shard == client.shard
                    and player.x
                    and not U.muted(G, player.userid)
                then
                    draw(player.x, player.z, player.name, palette[2])
                end
            end
            for _, ping in ipairs(client.map.pings or {}) do
                if
                    client.config.map.pings ~= false
                    and client.settings.map.show_pings ~= false
                    and not U.muted(G, ping.owner)
                then
                    draw(ping.x, ping.z, client:L(ping.kind), ping.kind == "danger" and palette[5] or palette[1])
                end
            end
            for _, pair in ipairs(client.map.pairs or {}) do
                for _, endpoint in ipairs({ pair.a, pair.b }) do
                    -- 配对已知不代表目的地已探索；每个端点仍独立遵守迷雾。
                    if
                        client.settings.map.show_wormholes ~= false
                        and client.config.map.wormholes ~= false
                        and U.finite(endpoint.x)
                        and U.finite(endpoint.z)
                        and client.player:CanSeePointOnMiniMap(endpoint.x, 0, endpoint.z)
                    then
                        draw(
                            endpoint.x,
                            endpoint.z,
                            "#" .. pair.id,
                            palette[(pair.id - 1) % #palette + 1],
                            "#" .. pair.id .. " · " .. endpoint.prefab
                        )
                    end
                end
            end
            for _, fire in ipairs(client.map.fires or {}) do
                if client.config.map.signal_fires ~= false and client.settings.map.show_fires ~= false then
                    draw(fire.x, fire.z, client:L("signal_fire"), palette[1])
                end
            end
        end
        for i = count + 1, #markers do
            markers[i]:Hide()
        end
    end)
    Hooks.wrap(scope, screen, "OnControl", function(original, self, control, down, ...)
        if wheel.shown then
            if control == G.CONTROL_CANCEL or control == G.CONTROL_SECONDARY then
                if not down then
                    wheel:Hide()
                    wheel.point = nil
                end
                return true
            end
            wheel:OnControl(control, down)
            return true
        end
        if
            client.config.map.enabled
            and client.config.map.pings ~= false
            and G.TheInput:IsKeyDown(G.KEY_LALT)
            and (control == G.CONTROL_PRIMARY or control == G.CONTROL_SECONDARY)
        then
            if down then
                local x, _, z = self:GetWorldPositionAtCursor()
                if control == G.CONTROL_PRIMARY then
                    wheel.point = { x = x, z = z }
                    wheel:Show()
                    wheel.buttons[1]:SetFocus()
                else
                    -- 删除距鼠标最近的自己标记，不能越权删除其他玩家标记。
                    local nearest, distance = nil, 12 * 12
                    for _, ping in ipairs(client.map.pings or {}) do
                        local d = (ping.x - x) ^ 2 + (ping.z - z) ^ 2
                        if ping.owner == client.player.userid and d < distance then
                            nearest, distance = ping, d
                        end
                    end
                    if nearest then
                        client:send("delete_ping", nil, { id = nearest.id })
                    end
                end
            end
            return true
        end
        return original(self, control, down, ...)
    end)
    Hooks.after(scope, screen, "OnDestroy", function()
        scope:close()
    end)
    scope:add(function()
        root:Kill()
    end)
    return scope
end
return M
