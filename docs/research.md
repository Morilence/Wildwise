# 源码调研与采用的设计

调研日期：2026-09-14。使用 Exa 检索原作者资料与源码入口，随后直接读取 GitHub 源码和 SteamCMD 下载的原工坊发布文件。原版接口最终以 Steam 官方独立专服 App **343050**、游戏版本 **747465** 自带的 `databundles/scripts.zip` 为准。公开脚本镜像只用于导航。

用户补充的智能小木牌与 Beefalo Status Bar 已加入独立功能模块。本文区分读过源码、确认过接口、实际执行过测试与尚未进行的兼容验收。

本轮[三年工坊评论审查](workshop-issues.md)已补采至 **35 个模组、58 个公开接口分页、4,584 条去重评论，其中窗口内 3,588 条**。另通过 Exa 搜索与讨论串补充上下文，整理 74 个具体场景。精确日期使用评论 Unix 时间转北京时间，不把缓存页面的日期标签数当评论数；完整步骤、边界和缺口见 [workshop-coverage.json](evidence/workshop-coverage.json)。

## 最新正式版核验

2026-09-14 重新调用官方 SteamCMD 的 `app_info_update 1` 和 `app_info_print 343050`：public build **24700372** 与安装的 appmanifest 一致，`version.txt` 为 **747465**；Linux depot **343052** 的 public manifest 为 **3802424534343984195**。引擎接口和专服测试均使用该安装的 `scripts.zip`，SHA-256 与核对接口列表见 [current-engine.json](evidence/current-engine.json)。

同次查询发现 updatebeta build **25265075** 比正式分支更新；本轮未下载或测试该测试分支，不能把“最新正式版验证”表述为“全部最新测试版已兼容”。公开 [Klei 更新列表](https://forums.kleientertainment.com/game-updates/dst/) 的检索缓存不能独立证明当前 Steam 分支，本次以官方实时分支元数据和本机安装共同核对。

新增核对包括：`gamelogic.lua` 的 `POPULATING` 阶段、真实 `EntityScript:SetPersistData` 恢复时机（`unwrappable` 解包也调用它，必须区分）、`dryingrack:GetDryingInfoSnapshot()`、`prefabs/meatrack2.lua` 的多格容器、原生 RUMMAGE／placer 输入以及首件物品 imagechange。新增多格晾肉架信息读取已接入；自动队列暂不批量收取它，保留玩家手动开关和取物。

第二轮另核对 `pickable` 的本地／外部定时器、`worldsettingsutil` 的原生回调参数、`wobyrack` 对 `dryingrack` 的继承、`container_proxy:GetMaster()`、`planardamage/GetDamage`、`planardefense/GetDefense`、`cooking.lua` 的三个熟肉别名与最高优先级判定、`edible` 的角色食物偏好，以及 `wormholetravel` 和发给世界的迁移事件。`kramped` 的计数在世界私有闭包中，未提供结构化读取接口，因此不再假定玩家存在该组件；腐败余量也不冒充已计算环境倍率的准确倒计时。

## 参考快照

| 参考 | 实际取得的源码 | 关注实现 | Wildwise 的处理 |
|---|---|---|---|
| [Insight](https://github.com/penguin0616/Insight) | Git `e0912f30de127f16c5bf35d27a0ea78e607366aa`；[工坊 2189004162](https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162) | 信息描述器、观察请求、角色差异、缓存 | 自行实现字段 schema、实体公共缓存、查看者缓存与增量同步；不复制描述器 |
| [Global Positions](https://github.com/rezecib/Global-Positions) | Git `defb25620be92cc307e1b7ceef6f512a7c5d5ea0`；[工坊 378160973](https://steamcommunity.com/sharedfiles/filedetails/?id=378160973) | 独立 MapExplorer、地图保存、位置与标记、主机路径差异 | 只记录获准的探索来源点，用原版 RevealArea 分批回放；不复制任一玩家完整个人地图 |
| [Wormhole Marks](https://steamcommunity.com/sharedfiles/filedetails/?id=362175979) | 原工坊 legacy ZIP，modinfo 1.4.5 | `starttravelsound` 后标记两端、颜色图集和世界计数 | 包装实际成功的 teleporter Activate，验证双向连接；稳定编号与逐端迷雾检查 |
| [Auto Stack and Pick Up](https://steamcommunity.com/sharedfiles/filedetails/?id=1803285852) | 原工坊文件，modinfo 0.3.1 | 掉落、来源排除、读档选项、堆叠与拾取 | 默认只处理已确认新掉落；保护来源与目标，等待落地；原版 Get/Put/GiveItem 保持属性与数量 |
| [ActionQueue RB3](https://steamcommunity.com/sharedfiles/filedetails/?id=2873533916) | 原工坊说明；读过[公开非官方衍生源码](https://github.com/alicia-vanca/ActionQueue-RB3-with-endless-action-Unofficial-modification)，Git `6776f5b6fd3efa29df61d54316d180349a45ab32` | 行为队列、批量布点、取消与替换工具 | 独立状态机与显式动作白名单，沿用原版动作选择和 RPC；衍生源码不视为当前原版 RB3 的发布文件 |
| [智能小木牌](https://steamcommunity.com/sharedfiles/filedetails/?id=1595631294) | 原工坊文件，modinfo 1.1.8 | 第一格内容、包裹、图集、辅助牌生命周期 | 原版 minisign/drawable 网络同步；直接读包裹保存记录，不生成临时物品；不包装全局 RegisterPrefabs |
| [Beefalo Status Bar](https://steamcommunity.com/sharedfiles/filedetails/?id=2477889104) | 原工坊文件，modinfo 1.4.0 | 骑乘信息、鞍具、饥饿阈值、踢落剩余时间 | 与 hover 共用观察；直接读取原版 `_bucktask`，覆盖顺从提升重置计时的情况 |

原工坊源码的 SHA-256 记录在 [source-snapshots.json](evidence/source-snapshots.json)，不把这些文件本身加入仓库或安装包。

## 关键接口核对

- **模组环境**：`modinfo.lua` 的受限环境没有常规 `ipairs` 等全局；用数值循环生成配置，真实专服确认可加载。服务端启动不 require 客户端 UI。
- **键位**：`Input:AddKeyUpHandler(key, fn)` 的回调没有 key 参数；`AddKeyHandler(fn)` 才提供 `(key, down)`。使用后者支持运行中重绑定，退出时 Remove。
- **信息权限**：引擎 `CanEntitySeeTarget` 包含光照、夜视、沙暴等检查。订阅与后续更新均检查，库存物品还检查持有者或已打开的容器。
- **血量与角色**：`healthdelta` 合并更新；`edible`、`eater`、`foodmemory` 按查看者计算。未知有副作用的自定义食用回调不作为查询执行。
- **原版拾取**：`Inventory:GiveItem` 会把溢出物放到活动鼠标格。自动拾取先使用 `CanAcceptCount` 和原版 `Stackable:Get` 拆分可接收数量，余量留地；真实专服已复现并修正。
- **原版合堆**：`Stackable:Put` 处理皮肤兼容、保鲜、湿度、温度等语义。没有自行 Remove 后 SpawnPrefab 重建堆叠。
- **落地**：`on_loot_dropped`、`stopfalling`、`on_landed` 与 `inventoryitem.is_landed` 分工不同。物理速度、纵坐标、持有者和来源在执行时复查，后到的落地通知不得抹掉主动丢弃来源。
- **动作**：`performaction` 先于原版 BufferedAction 执行，可挂成功／失败回调。客户端队列经 PlayerController 和原版 LeftClick/RightClick/MakeRecipeFromMenu 提交；房主本地路径先同步登记观察，避免执行早于登记。
- **小木牌**：网络图像可能是哈希，服务端读取原版绘图覆盖与 inventoryitem 字符串。只使用游戏已提供的图集。原版 minisign 单独 OnDrawn 在 nullrenderer 也输出 `FROMNUM`，因此该环境的 drawable 字段测试不证明贴图外观正确。
- **牛状态**：原版 `domesticatable:DeltaObedience` 可以重置 `_bucktask`；不在 Wildwise 维护平行的骑乘时长公式。

## 产品设计决策

Product Design 用于梳理原版游戏中的信息层级与操作流程。沿用原版字体、按钮、纸质窗口、hover 和地图投影；提供五个设置页签，不弹首次强制向导。预设只改变显示密度，自动拾取保留独立 opt-in。主动血条实际不可见时保留 hover 血量，避免信息空缺。

队列以明确选择启动；手动操作接管，输入焦点变化暂停，恢复需玩家确认。批量部署只创建临时原生轮廓，使用叉号与计数补充颜色语义，不接管普通单次建筑放置。

本轮未生成替代游戏的网页演示或伪造实机截图。原生菜单的无画面构造／刷新已执行，具体布局、字体和视觉兼容仍需图形客户端验收。

## 来源与许可边界

独立编写全部业务代码。Insight 使用 [RECEX Shared Source License](https://github.com/penguin0616/Insight/blob/e0912f30de127f16c5bf35d27a0ea78e607366aa/LICENSE)，未将其视为可复制到本 MIT 项目的代码。其他参考源码亦未拷入发布物。游戏字体、库存图标和动画由安装的 DST 提供，不再分发。参见 [Klei 的模组说明](https://support.klei.com/hc/en-us/articles/360029555992-Modding-Don-t-Starve-and-Don-t-Starve-Together)。

工坊说明及源码提示的问题只作为设计和测试线索。除报告记录的专服测试外，未声称复现参考模组缺陷，也没有参考组合的性能比较数据。
