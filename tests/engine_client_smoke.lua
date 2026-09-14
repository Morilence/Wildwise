-- 无画面主机路径合约：真实 Client、RPC 编码、世界服务、原生 Widget；虚拟身份和 HUD 焦点夹具。
-- 不替代本地主机窗口或远程网络客户端测试。仅运行于隔离测试专服。
local G = _G
local Context = require("wildwise/runtime/context")
local Client = require("wildwise/runtime/client")
local Widget = require("widgets/widget")
local player = G.SpawnPrefab("wilson")
player.userid = "wildwise_contract_fixture"
player.HUD = { HasInputFocus = function() return false end, IsMapScreenOpen = function() return false end }
local controls = Widget("WildwiseClientContract"); controls.owner = player
local old_client, instance = Context.client, nil
local ok, message = pcall(function()
    instance = Client.new(controls, G, Context.config)
    Context.client = instance
    instance:tick(); assert(instance.session, "host handshake did not arrive")
    instance:tick(); assert(instance.diagnostics, "host heartbeat did not arrive")
    instance:set("items.pickup", false)
    assert(G.TheWorld.components.wildwise_world.players[player].pickup == false)
    instance:set("healthbars.hostile_scope", "followers")
    assert(G.TheWorld.components.wildwise_world.players[player].hostile_scope == "followers")
    local original = Context.config.beefalo.hunger_threshold
    instance:set("beefalo.hunger_threshold", 0)
    assert(instance.settings.beefalo.hunger_threshold == 0 and Context.config.beefalo.hunger_threshold == original)
    local encoded = require("wildwise/core/protocol").encode(require("json"), "cancel", "expired-session", 999999, { reason = "death" })
    instance:receive(nil, encoded); assert(instance.queue.reason ~= "death", "old session accepted")
    instance:close(); assert(instance.closed)
end)
if instance and not instance.closed then instance:close() end
Context.client = old_client
player.HUD = nil; player:Remove(); controls:Kill()
if ok then print("[WW_CLIENT_RESULT] passed=1 failed=0 host_fixture=true")
else print("[WW_CLIENT_RESULT] passed=0 failed=1 " .. tostring(message)) end
