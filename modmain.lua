local G = GLOBAL
local config = require("wildwise/core/config").load(GetModConfigData)
PrefabFiles = {}
-- 入口仅注册：专服永远不会 require widgets/screens 或客户端输入模块。
require("wildwise/runtime/bootstrap").register({
    AddPrefabPostInit = AddPrefabPostInit,
    AddComponentPostInit = AddComponentPostInit,
    AddPlayerPostInit = AddPlayerPostInit,
    AddClassPostConstruct = AddClassPostConstruct,
    AddModRPCHandler = AddModRPCHandler,
    AddClientModRPCHandler = AddClientModRPCHandler,
    AddShardModRPCHandler = AddShardModRPCHandler,
}, G, config)
