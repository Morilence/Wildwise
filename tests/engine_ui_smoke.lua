local Config = require("wildwise/core/config")
-- 真实引擎的无画面 UI/API 合约检查：用真实 Widget/Menu，业务输入为受控夹具。
-- 不能据此声称布局、鼠标命中区域、图像质量或远程客户端联机通过验收。
local G = _G
local Context = require("wildwise/runtime/context")
local Strings = require("wildwise/ui/strings")
local client = {
    player = G.SpawnPrefab("wilson"),
    config = Config.copy(Context.config),
    settings = Config.settings(Context.config),
    cache = require("wildwise/core/lru").new(256),
    lang = "zh",
    map = { players = {}, pairs = {}, pings = {} },
    queue = { tasks = {}, state = "idle", reason = "" },
    found = {},
    visible_bars = {},
    previews = {},
    conflicts = {},
    selected = {},
}
client.settings.beefalo.offset_x, client.settings.beefalo.offset_y = 0, 0
client.L = function(self, key)
    return Strings.get(key, self.lang)
end
client.set = function(self, key, value)
    Config.set(self.settings, key, value)
end
client.save_settings, client.send = function() end, function() end
local passed, failed, cleanup = 0, 0, {}
local function test(name_, fn)
    local ok, message = pcall(fn)
    if ok then
        passed = passed + 1
        print("[WW_UI_PASS] " .. name_)
    else
        failed = failed + 1
        print("[WW_UI_FAIL] " .. name_ .. " " .. tostring(message))
    end
end
test("native HUD constructor and update", function()
    local hud = require("wildwise/ui/hud")(client)
    cleanup[#cleanup + 1] = hud
    hud:OnUpdate()
    assert(hud.button and hud.mount)
    client.queue.tasks = { { action = "CHOP" } }
    hud:OnUpdate()
    client.queue.tasks = {}
    client.plan_points = { { valid = true }, { valid = false } }
    hud:OnUpdate()
    client.plan_points = nil
end)
test("all native menu pages in Chinese and English", function()
    local menu = require("wildwise/ui/menu")(client)
    cleanup[#cleanup + 1] = menu
    for _, lang in ipairs({ "zh", "en" }) do
        client.lang = lang
        for _, tab in ipairs({ "info", "maps", "items", "queue", "diagnostics" }) do
            menu.tab = tab
            for page = 1, (tab == "info" and 5 or 1) do
                menu.page = page
                menu:refresh()
            end
        end
    end
end)
test("native general key callback receives key and down", function()
    local seen
    local handler = G.TheInput:AddKeyHandler(function(key, down)
        seen = { key, down }
    end)
    G.TheInput:OnRawKey(G.KEY_F7, false)
    handler:Remove()
    assert(seen and seen[1] == G.KEY_F7 and seen[2] == false)
end)
test("native menu edits module settings without changing server defaults", function()
    local menu = require("wildwise/ui/menu")(client)
    cleanup[#cleanup + 1] = menu
    local original = client.config.beefalo.hunger_threshold
    client.settings.beefalo.hunger_threshold = 0
    menu.tab, menu.page = "info", 5
    menu:refresh()
    local button = menu.focus_buttons[3]
    assert(button and button.onclick, "missing hunger threshold choice")
    button.onclick()
    assert(client.settings.beefalo.hunger_threshold == 5, "menu did not use native threshold choices")
    assert(client.config.beefalo.hunger_threshold == original, "personal edit mutated server rules")
end)
test("native mod configuration screen exposes all scalar options including container signs", function()
    local modname = G.KnownModIndex:GetModActualName("Wildwise")
    local screen = require("screens/redux/modconfigurationscreen")(modname, false)
    cleanup[#cleanup + 1] = screen
    assert(#screen.options == #Config.fields, "native configuration option count changed")
    assert(screen.options[1].name == "language", "general settings are not first")
    assert(screen.options[#screen.options].name == "beefalo_hunger_threshold", "beefalo field is not exposed")
    local names = {}
    for _, option in ipairs(screen.options) do
        names[option.name] = true
    end
    for prefab in pairs(require("wildwise/services/signs").supported) do
        assert(names["signs_" .. prefab], "missing container switch: " .. prefab)
    end
end)
test("native batch outline has no pointer-following component", function()
    local preview = G.SpawnPrefab("axisalignedplacement_outline")
    assert(preview and not preview.components.placer)
    preview.AnimState:PlayAnimation("unit_x")
    preview:Remove()
end)
test("WW-U01 hover text follows replacement owner and is removed with HUD", function()
    local Widget = require("widgets/widget")
    local a, b = Widget("hover_a"), Widget("hover_b")
    cleanup[#cleanup + 1] = a
    cleanup[#cleanup + 1] = b
    local hud = require("wildwise/ui/hud")(client)
    hud:update_hover(a)
    local old = hud.hover_text
    hud:update_hover(b)
    assert(hud.hover_owner == b and not old.inst:IsValid())
    local last = hud.hover_text
    hud:Kill()
    assert(not last.inst:IsValid())
end)
for _, widget in ipairs(cleanup) do
    widget:Kill()
end
client.player:Remove()
print(string.format("[WW_UI_RESULT] passed=%d failed=%d build=%s", passed, failed, tostring(G.APP_VERSION)))
