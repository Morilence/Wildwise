-- 真实引擎的无画面 UI/API 合约检查：用真实 Widget/Menu，业务输入为受控夹具。
-- 不能据此声称布局、鼠标命中区域、图像质量或远程客户端联机通过验收。
local G = _G
local U = require("wildwise/core/util")
local Context = require("wildwise/runtime/context")
local Strings = require("wildwise/ui/strings")
local client = { player = G.SpawnPrefab("wilson"), config = U.copy(Context.config),
    settings = U.copy(Context.config), cache = require("wildwise/core/lru").new(256), lang = "zh",
    map = { players = {}, pairs = {}, pings = {} }, queue = { tasks = {}, state = "idle", reason = "" },
    found = {}, visible_bars = {}, previews = {}, conflicts = {}, selected = {} }
client.settings.categories, client.settings.beefalo_visible = {}, true
client.settings.beefalo_x, client.settings.beefalo_y = 0, 0
client.L = function(self, key) return Strings.get(key, self.lang) end
client.set = function(self, key, value) self.settings[key] = value end
client.save_settings, client.send = function() end, function() end
local passed, failed, cleanup = 0, 0, {}
local function test(name_, fn)
    local ok, message = pcall(fn)
    if ok then passed = passed + 1; print("[WW_UI_PASS] " .. name_)
    else failed = failed + 1; print("[WW_UI_FAIL] " .. name_ .. " " .. tostring(message)) end
end
test("native HUD constructor and update", function()
    local hud = require("wildwise/ui/hud")(client); cleanup[#cleanup + 1] = hud
    hud:OnUpdate(); assert(hud.button and hud.mount)
    client.queue.tasks = { { action = "CHOP" } }; hud:OnUpdate(); client.queue.tasks = {}
    client.plan_points = { { valid = true }, { valid = false } }; hud:OnUpdate(); client.plan_points = nil
end)
test("all native menu pages in Chinese and English", function()
    local menu = require("wildwise/ui/menu")(client); cleanup[#cleanup + 1] = menu
    for _, lang in ipairs({ "zh", "en" }) do
        client.lang = lang
        for _, tab in ipairs({ "info", "maps", "items", "queue", "diagnostics" }) do
            menu.tab = tab
            for page = 1, (tab == "info" and 5 or 1) do menu.page = page; menu:refresh() end
        end
    end
end)
test("native general key callback receives key and down", function()
    local seen
    local handler = G.TheInput:AddKeyHandler(function(key, down) seen = { key, down } end)
    G.TheInput:OnRawKey(G.KEY_F7, false)
    handler:Remove(); assert(seen and seen[1] == G.KEY_F7 and seen[2] == false)
end)
test("native batch outline has no pointer-following component", function()
    local preview = G.SpawnPrefab("axisalignedplacement_outline")
    assert(preview and not preview.components.placer)
    preview.AnimState:PlayAnimation("unit_x"); preview:Remove()
end)
for _, widget in ipairs(cleanup) do widget:Kill() end
client.player:Remove()
print(string.format("[WW_UI_RESULT] passed=%d failed=%d build=%s", passed, failed, tostring(G.APP_VERSION)))
