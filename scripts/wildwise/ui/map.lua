local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local Hooks = require("wildwise/core/hooks")
local Lifetime = require("wildwise/core/lifetime")
local U = require("wildwise/core/util")
local M = {}
local palette = { { .93, .65, .28 }, { .4, .8, .94 }, { .75, .53, .94 }, { .5, .87, .46 }, { .94, .4, .38 }, { .96, .86, .44 } }
function M.attach(screen, client, G)
    local scope = Lifetime.new()
    local root = screen:AddChild(Widget("WildwiseMapMarkers")); root:SetHAnchor(G.ANCHOR_MIDDLE); root:SetVAnchor(G.ANCHOR_MIDDLE)
    local markers = {}
    local function make(i)
        if markers[i] then return markers[i] end
        local widget = root:AddChild(Widget("WildwiseMapMarker"))
        widget.icon = widget:AddChild(Image("images/hud.xml", "cursor02.tex")); widget.icon:SetSize(24, 24)
        widget.text = widget:AddChild(Text(G.UIFONT, 20, "")); widget.text:SetPosition(0, 23)
        markers[i] = widget; return widget
    end
    Hooks.after(scope, screen, "OnUpdate", function()
        local count = 0
        if client.config.map.enabled then
            local function draw(x, z, label, colour, tooltip)
                if not U.finite(x) or not U.finite(z) then return end
                count = count + 1; local widget = make(count)
                -- 地图投影、缩放和旋转全部委托原版；这里仅将归一化坐标转换成控件坐标。
                local mx, my = screen.minimap:WorldPosToMapPos(x, z, 0)
                widget:SetPosition(screen:MapPosToWidgetPos(G.Vector3(mx, my, 0))); widget.text:SetString(label)
                widget.icon:SetTint(colour[1], colour[2], colour[3], 1); widget:SetTooltip(tooltip or label); widget:Show()
            end
            for _, player in ipairs(client.map.players or {}) do
                if player.shard == client.shard and player.x and not U.muted(G, player.userid) then
                    draw(player.x, player.z, player.name, palette[2])
                end
            end
            for _, ping in ipairs(client.map.pings or {}) do
                if not U.muted(G, ping.owner) then
                    draw(ping.x, ping.z, client:L(ping.kind), ping.kind == "danger" and palette[5] or palette[1])
                end
            end
            for _, pair in ipairs(client.map.pairs or {}) do
                for _, endpoint in ipairs({ pair.a, pair.b }) do
                    -- 配对已知不代表目的地已探索；每个端点仍独立遵守迷雾。
                    if U.finite(endpoint.x) and U.finite(endpoint.z) and client.player:CanSeePointOnMiniMap(endpoint.x, 0, endpoint.z) then
                        draw(endpoint.x, endpoint.z, "#" .. pair.id, palette[(pair.id - 1) % #palette + 1], "#" .. pair.id .. " · " .. endpoint.prefab)
                    end
                end
            end
            for _, fire in ipairs(client.map.fires or {}) do draw(fire.x, fire.z, client:L("signal_fire"), palette[1]) end
        end
        for i = count + 1, #markers do markers[i]:Hide() end
    end)
    Hooks.wrap(scope, screen, "OnControl", function(original, self, control, down, ...)
        if client.config.map.enabled and control == G.CONTROL_PRIMARY and G.TheInput:IsKeyDown(G.KEY_LALT) then
            if down then
                local x, _, z = self:GetWorldPositionAtCursor()
                client:send("ping", nil, { kind = client.settings.map.ping_kind, x = x, z = z })
            end
            return true
        end
        return original(self, control, down, ...)
    end)
    Hooks.after(scope, screen, "OnDestroy", function() scope:close() end)
    scope:add(function() root:Kill() end)
end
return M
