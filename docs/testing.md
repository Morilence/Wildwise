# 测试与性能报告

日期：2026-09-14。当前版本：Wildwise 0.2.0。结论：源码、工程检查、隔离独立专服和无画面原版 API 链路可运行；**尚未达到完整工坊发版门槛**。0.2.0 配置回归见下节；初版性能与移除测试保留为历史证据。

## 0.2.0 配置回归

配置入口、内部模块结构、个人偏好和中英文 README 已同步更新。Lua 静态检查 39 个文件无警告、无错误；48 项纯 Lua 测试通过，包括全部 30 项原生配置的默认值与枚举映射、关闭项、零阈值、非法值回退、模块对象隔离、嵌套偏好恢复、RPC 和 README 示例。

在同一隔离专服上通过原生 `modoverrides.lua` 设置 `beefalo_hunger_threshold = 25`、`info_font_size = 26`、`healthbars_numbers = false`、`map_share_position = "off"`、`items_radius = 6`，确认各值进入相应模块字段。重新执行实体测试 26 项、无画面原生 UI 测试 6 项、主机通信合约 1 项和异步掉落测试 2 项，全部通过。UI 测试包含原生模组配置页的 30 个选项、F7 对嵌套偏好的读写，以及个人修改不污染服务器规则；仍不代表画面与真实鼠标操作验收。原始结果见 [configuration.txt](evidence/configuration.txt)。

## 环境与证据

以下记录为 0.1.0 的初版基线；0.2.0 的新增验证和复测结果见上节。

测试机器原先未安装游戏。测试通过 SteamCMD 匿名下载官方 DST Dedicated Server App 343050，取得游戏版本 **747465**，在单独的临时存储目录创建小型生存世界，绑定回环地址、离线 LAN，仅运行开发测试。测试使用独立存档，未登录游戏账号或安装图形客户端。

环境是 2 vCPU 的 Intel Xeon E5-2680 v4 KVM 虚拟机，内存约 7.26 GiB，Linux 6.8.0-49，Node 24.18.0，独立测试使用 Lua 5.1。完整参数见 [environment.json](evidence/environment.json)。

| 检查层 | 结果 | 能证明什么 |
|---|---|---|
| Lua 静态检查 | 0 warning / 0 error | 语法、未定义变量和常见静态问题 |
| 纯 Lua 自动测试 | 40 项通过 | 缓存、生命周期、权限、来源、守恒、队列、规划、协议与迁移不变量 |
| 原版专服实体测试 | 26 项通过 | 真实 prefab/组件、食用效果、healthdelta、库存余量、MapExplorer、牛骑乘与计时 |
| 原版异步掉落 | 2 项通过 | lootdropper 完成落地后合堆，主动 DropItem 来源受保护 |
| 无画面原生 UI 合约 | 4 项通过 | 真实 HUD 与中英文全部菜单页构造／刷新、原版键位回调、预览 prefab |
| 无画面主机路径合约 | 1 项通过 | 真实 Client 与世界服务的握手、心跳、偏好、旧会话丢弃和关闭；身份／HUD 焦点为夹具 |
| 保存与重启 | 已执行多次 | 隔离专服保存并从同一世界恢复加载 |
| 停用后加载 | 通过基础检查 | 同一存档在 No mods registered 下加载；世界与出生门存在，继续保存 |
| 安装包 | UTF-8、Lua 编译、白名单检查 | 安装目录结构和可复现归档，不包含参考源码与游戏资产 |

专服逐项输出见 [dedicated-results.txt](evidence/dedicated-results.txt)。`server does not load UI` 检查的是正常服务启动未创建客户端；后续 UI 测试是开发控制台显式加载的，不能把此测试流程当作生产专服的 UI 加载行为。

停用模组后的基础加载输出见 [removal.txt](evidence/removal.txt)，完整升级／重启用和玩家资产回归仍待完成。

这些测试未连接任何人类玩家。两个生成的 Wilson 实体不是两名远程联机玩家；真实对象测试也不能替代网络预测、实际输入和画面验收。

## 已通过实测修正的问题

1. `modinfo.lua` 使用了受限环境不存在的迭代函数；改用数值循环后真实专服成功加载。
2. 自然生成的物品还没有完成落地，不能直接视为合堆候选；分别补充受控落地测试和真实异步 lootdropper 测试。
3. 原版 GiveItem 会把部分容量的余量拿到鼠标上；改为按 CanAcceptCount 使用原版 Get 拆分，实测库存 38→40，地面 5→3。
4. 夜间重新加载存档使可见性测试前提变化；使用原版夜视能力固定测试前提，保留生产代码的光照权限检查。
5. 牛顺从修改接口是 DeltaObedience；真实骑乘后验证 `_bucktask` 存在并随顺从提升更新。
6. 集中掉落暴露重复邻居查询成本；改用获准候选的空间索引和数量／CPU 双预算，下面记录同一开发探针的结果。

原版 minisign 在 nullrenderer 中直接调用 OnDrawn 也会记录 `Could not find anim build FROMNUM`。当前测试验证 drawable 数据和实体生命周期，不把该日志当作已验证的贴图渲染结果；小木牌图片仍需图形客户端查看。

## 集中掉落探针

`tests/engine_load.lua` 在真实专服创建 100、500、1000 个已落地的原版 flint，每组运行 20 秒。每组约 200 个 Wildwise 世界 Tick 样本；使用 `os.clock()` 统计此组件的 CPU 耗时。角色未连接，场景不含客户端渲染、生成 prefab 的初始耗时、全游戏帧耗时或网络流量。每组末尾验证数量并移除测试物。100 件组的前六秒同时运行了两件物品的异步掉落测试，位置与负载物品分离；其余两组没有此并行场景。

| 掉落数 | 数量守恒 | 最终待处理 | p50 ms | p95 ms | p99 ms |
|---|---|---|---|---|---|
| 100 | 是 | 0 | 0.017 | 0.156 | 2.116 |
| 500 | 是 | 0 | 0.022 | 2.105 | 2.163 |
| 1000 | 是 | 0 | 0.034 | 2.144 | 2.224 |

原始记录：[item-load.txt](evidence/item-load.txt)。修正前的同类开发探针记录在 [item-load-before.txt](evidence/item-load-before.txt)，用于解释实现热点，**不是与参考模组或原版游戏的性能对照**。空世界、前置验证和世界状态仍可能影响结果，不能直接转成宣传百分比。

CPU 预算只在原版调用之间让出，不能打断单个调用，所以高分位可略超过 2 ms。PRD 的“6 人常规场景新增 Lua p95 ≤ 2 ms”没有在这里得到验证；本报告也不宣称已满足。当前 1000 件场景的 p95 约 2.14 ms 是公开保留的测量结果。

## 复现

开发依赖与 `npm run check` / `npm run package` 见中英文 README。引擎测试必须从源码 checkout 执行，安装包不含 tests。

1. 使用合法取得的 DST 独立专服，安装源码文件夹到 `mods/Wildwise`。
2. 创建隔离测试 cluster，设置离线 LAN、空服不暂停、小型生存世界；启用 Wildwise，不使用私人游戏存档。
3. 从 `bin64` 目录启动专服，世界加载完成后在其控制台逐条运行：

```lua
dofile('../mods/Wildwise/tests/engine_smoke.lua')
dofile('../mods/Wildwise/tests/engine_ui_smoke.lua')
dofile('../mods/Wildwise/tests/engine_events.lua')
-- 等待 WW_EVENT_RESULT，再开始负载探针，避免混入事件场景。
dofile('../mods/Wildwise/tests/engine_load.lua')
-- 等待 WW_LOAD_COMPLETE；约 60 秒。
dofile('../mods/Wildwise/tests/engine_client_smoke.lua')
```

4. 保留带 `WW_` 标签的结果，执行 `c_save(); c_shutdown(true)`；重新启动确认保存可恢复。
5. 无画面 UI 测试显式创建并清理真实 Widget；主机合约使用测试身份，不应在公开服务器上运行。

## 发版前仍需完成

- 本地主机窗口 + 一名远程客户端：实体引用、角色差异、输入接管、动作预测与结果、独立地图共享隔离。
- Master/Caves 实际连接、往返、断线重连、回档与编号恢复；不同共享模式和关闭共享的历史边界。
- 图形客户端截图及交互：不同分辨率／缩放、中文字体、血条遮挡、包裹／皮肤／调味小木牌、牛状态栏、地图投影、船上预览。
- Geometric Placement、Minimap HUD、Combined Status；实际同功能模组停用提示；角色特殊形态。
- 两名玩家竞争拾取、船岸、落石、工具损坏、所有动作类别、全部原版食用修正和库存特例。
- 同环境、同存档的原版／参考组合／Wildwise 对照，6 人与 12 人场景，客户端与服务端 p50/p95/p99、消息量、内存和至少两小时持续运行。
- 升级、移除与重新启用的完整存档回归，以及正式截图与工坊发布检查。

测试缺口来自当前没有图形游戏客户端与真实多人测试环境；因此提供开发版本与明确的后续验收清单，不把静态测试或 nullrenderer 当作联机验收完成。
