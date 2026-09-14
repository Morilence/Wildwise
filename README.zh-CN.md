# Wildwise

[English](README.md)

**Wildwise 是《饥荒联机版》的综合便利模组**：查看信息、协作探索、整理掉落、连续操作和管理基地，都在同一套服务器权限与个人设置下完成。支持简体中文／英文、键盘与鼠标，使用游戏原生 UI 和资源。

当前为 **0.3.0 开发版**。2026-09-14 已核验官方最新 **public 正式分支：游戏 747465，Steam build 24700372**，并在其真实独立专服运行测试；较新的 updatebeta 未适配验证。[版本证据](docs/evidence/current-engine.json) · [验证与限制](docs/testing.md)

## 玩家：能做什么

| 功能 | 使用方式与边界 |
|---|---|
| 信息提示 | 悬停查看血量、基础伤害、食用效果、鲜度、耐久、燃料、加工、农作物和随从信息；食用效果考虑查看者角色。检查修饰键展开详情，菜单可选简洁／标准／详细预设。缺少可信接口的数值省略。 |
| 战斗血条 | 按当前战斗目标显示，默认关注敌视自己的生物，最多 12 条、脱战保留 2 秒；可包含随从／附近队友。已显示的血量不在 hover 重复。 |
| 协作地图 | 队友位置与名称、允许共享的探索、实际穿越虫洞的配对编号；端点仍受迷雾限制。四种临时标记每人最多 5 个、60 秒失效；木炭信号火、跨世界队友提示。 |
| 合堆与拾取 | 新掉落物落地后向较早的合法堆合并，默认保护主动丢弃物和读档摆设。自动拾取默认关闭，需服主允许且个人开启；默认只拾取已有同类物品，装不下的余量留地。 |
| 行为队列 | Shift 点击／框选采集、砍挖、农业等允许的操作，最多 200 项；支持非建筑重复制作和批量布点。工具／材料／库存不足时暂停，手动操作可接管。 |
| 智能小木牌 | 默认在木箱、龙鳞宝箱、远古船货舱显示首个非空物品图标；可分别开启切斯特、哈奇、冰箱、盐盒、鱼类储物箱。包裹可显示内部首件物品，空箱清除旧图。 |
| 牛状态栏 | 骑牛时查看血量、驯化、顺从、倾向、鞍具、饥饿及原版踢落计时；B 切换。不会给 Woby 套用牛的驯化数据。 |

料理查询支持四格食材，点击锅类型可切换普通锅／便携锅（沃利默认便携锅）。更换材料会清除旧结果；配方异常会说明原因。容器内容／同类定位、世界事件详情、攻击范围数值默认关闭，由服主允许。位面伤害／防御单独显示。基础伤害不等于考虑敌人抗性后的最终伤害；未知自定义食物回调不会为预测而执行。基础腐败余量与“环境不变的保鲜估时”分开显示；保鲜估时支持原版已知倍率，遇到未知保鲜回调、酸雨额外腐败或暂停时明确降级。料理候选显示权重概率及基础耗时，不假设角色与锅的额外倍率。

### 显示、皮肤与独立控制

- F7 信息页支持食用、保鲜、装备、加工、农田、随从、冷却、计时器等独立显示；可选时间／温度单位和最大行数，内容截断会提示展开。服务端关闭对应信息时，个人开关不能取得该数据。
- F7 信息第 5 页设置牛栏：原生徽章／紧凑文字、独立缩放、位置微调、背景不透明度、饥饿独立隐藏。生命／饥饿显示当前值与上限，徽章按上限归一化；B 的开关会保存。
- 小木牌保留原生物品图标、物品换肤、调味叠层和包裹尺寸图标。箱中放入原生 `minisign_item` 时，沿用其关联皮肤作为牌体；取出后恢复默认。服主可以关闭牌体换肤、关闭包裹透视或调整牌体缩放。
- 指向附近受支持容器后按 F7，进入物品第 2 页，可切换此箱木牌显示。作用于当前世界的本次运行，重启恢复；不取出、挖除或消耗物品。距离限 6 个世界单位、同平台且可见。
- 物品三套半径分别用于世界掉落合堆、玩家丢弃合堆和自动拾取；值为 0 时继承旧 `items_radius`。灰烬／粪便／种子的九个独立许可默认关闭。树枝树附近自然树枝、着火／阴燃物及分功能排除标签受保护。
- 地图玩家、标记、信号火和虫洞可分别隐藏；服主独立控制标记／信号火／虫洞许可。个人隐藏图标不会撤回已经共享的探索。

图形客户端中的实际皮肤、分辨率和 Combined Status 组合仍待验收。当前已验证原生 Widget、图像数据和实体生命周期，不将无画面结果称为外观验收通过。

### 第一次使用

1. 与房主安装相同版本，在“服务器模组”启用后进世界。
2. 点击 HUD 的 **Wildwise** 按钮或按 **F7**。菜单有信息、地图、物品、队列、诊断五页。
3. 先选择信息预设，再调整位置／探索共享。需要自动拾取时，在房主允许后进入 **F7 → 物品 → 自动拾取** 开启。

位置与探索共享在生存／无尽模式默认允许，荒野／PvP 默认关闭。个人关闭后停止后续共享，**队友已经学到的地图不能撤回**。F7 保存个人偏好，不改写服务器配置。

### 常用操作

| 输入 | 操作 |
|---|---|
| HUD 按钮／F7 | 打开设置；菜单键可重绑定 |
| 游戏检查修饰键 | 展开提示详情 |
| Shift＋单击／双击 | 添加目标／选择附近同类可操作目标 |
| Shift＋左键拖动 | 框选目标 |
| 手持可部署材料／肥料，或装备锄头／草叉／浇水壶，Shift＋右键拖动 | 创建布点／耕地／铲地／地块浇水预览，再点击“执行布点” |
| Shift＋点击非建筑配方 | 重复制作 |
| 移动、普通点击、攻击 | 接管角色并取消后续任务 |
| 队列面板 | 暂停、继续、清空 |
| Alt＋地图左键 | 打开四向标记选择器，选择类型后发出；右键／Esc 取消 |
| Alt＋地图右键 | 删除光标附近自己的标记 |
| C | 再制作一次本次会话最近使用的非建筑配方；可重绑定 |
| B | 切换牛状态栏并保存偏好；可重绑定 |

农田支持 2×2／3×3／4×4，墙体和地皮遵循原版对齐。普通单次建筑放置保留原生 Shift 网格操作。聊天、地图、菜单或窗口失焦会暂停队列，返回后需主动继续。主操作键跟随游戏绑定，队列修饰键可更改。

**肉架支持开取挂闭环**：Shift 选择肉架后只打开未打开的容器，按格取回完成品，保留仍在晾晒的材料；鼠标上持有可挂材料时继续挂入。每次只转移一个格子，等待原生库存同步；每架最多 24 次取物，满包、材料不足或五秒无进展时暂停。可在 F7 开启工作后收集，仅加入实际工作点半径 4 个世界单位内的合法掉落，仍受队列上限约束。队列不提供自动战斗、选敌或躲避攻击；完整手柄操作仍待实机验收。

## 服主：安装、配置与维护

Wildwise 是服务器启用、**所有客户端都需要加载**的模组，无需安装参考模组。当前通过 GitHub 构建产物手动分发，未发布到 Steam 工坊。

1. 从 [GitHub Actions](https://github.com/Morilence/Wildwise/actions) 的成功构建下载 `Wildwise-mod`，或按下文自行打包。
2. 解压构建产物，再把其中的 `Wildwise-0.3.0.zip` 解压到游戏 `mods`。检查应为 `mods/Wildwise/modinfo.lua`，不要多套一层目录。
3. 房主在“服务器模组”启用；每位玩家安装同一份文件。专服的 Master 与 Caves 都需安装、启用并保持版本一致。
4. 修改服务器模组配置后重启相应 shard；在 F7 查看生效设置与停用原因。

手动安装的目录名区分大小写；`modoverrides.lua` 的条目必须与目录完全相同，例如目录 `Wildwise` 对应下方示例。已有配置时合并条目，保留其他模组。无需为这个手动包编造 Workshop ID。

### 权限与默认值

服务器控制功能总开关、共享规则、查询范围权限、自动拾取许可与木牌类型。玩家只在允许范围内调整显示／操作；个人设置不能开启服主禁用的模块。显示配置提供个人初始值，不会强制覆盖已保存偏好。

自动合堆默认仅处理新掉落；主动丢弃／读档合堆需服主另行开启。自动拾取需要 **`items_enabled`、`items_pickup_allowed` 和个人开关**同时允许。即便允许拾取，也不会擅自开启被关闭的合堆来源。

### modoverrides.lua 完整示例

以下 **74 项均为默认值**，与游戏原生配置及测试同步。通用项在前，模块使用平铺前缀，例如 `beefalo_hunger_threshold`。写入 `Master/modoverrides.lua`；有洞穴时也配置 `Caves/modoverrides.lua`。

<details>
<summary>展开可复制的完整配置</summary>

```lua
return {
    Wildwise = {
        enabled = true,
        configuration_options = {
            language = "auto",
            ui_scale = 1,
            menu_key = 288,
            diagnostics = false,
            info_enabled = true,
            info_container_contents = false,
            info_world_events = false,
            info_attack_range = false,
            info_font_size = 22,
            healthbars_enabled = true,
            healthbars_limit = 12,
            healthbars_linger_seconds = 2,
            healthbars_scale = 1,
            healthbars_numbers = true,
            healthbars_hostile_scope = "self",
            map_enabled = true,
            map_share_position = "auto",
            map_share_exploration = "auto",
            items_enabled = true,
            items_stack_world = true,
            items_stack_manual = false,
            items_stack_loaded = false,
            items_pickup_allowed = false,
            items_pickup_existing = true,
            items_radius = 4,
            queue_enabled = true,
            queue_farm_grid = 3,
            signs_enabled = true,
            signs_treasurechest = true,
            signs_dragonflychest = true,
            signs_boat_ancient_container = true,
            signs_chester = false,
            signs_hutch = false,
            signs_icebox = false,
            signs_saltbox = false,
            signs_fish_box = false,
            beefalo_enabled = true,
            beefalo_hunger_threshold = 15,
            info_combat = true,
            info_food_values = true,
            info_perishable = true,
            info_equipment = true,
            info_progress = true,
            info_farm = true,
            info_follower = true,
            info_cooldowns = true,
            info_timers = true,
            info_max_lines = 10,
            info_inspect_lines = 25,
            info_time_style = "clock",
            info_temperature_units = "game",
            map_wormholes = true,
            map_pings = true,
            map_signal_fires = true,
            items_world_radius = 0,
            items_manual_radius = 0,
            items_pickup_radius = 0,
            items_world_ash = false,
            items_world_poop = false,
            items_world_seeds = false,
            items_manual_ash = false,
            items_manual_poop = false,
            items_manual_seeds = false,
            items_pickup_ash = false,
            items_pickup_poop = false,
            items_pickup_seeds = false,
            queue_collect_after_work = false,
            queue_double_click_speed = 0.35,
            queue_double_click_range = 15,
            signs_bundle_contents = true,
            signs_body_skins = true,
            signs_scale = 0.65,
            beefalo_show_hunger = true,
            beefalo_scale = 1,
        },
    },
}
```

</details>

可只覆盖需要修改的项；未指定项使用游戏保存的配置或默认值。布尔值／数字不加引号。`signs_enabled` 为总开关，各容器开关独立。旧版平铺个人设置不迁移到当前 `wildwise_client_v2`；服务器仍使用上方原生字段。

### 升级、停用与排错

- 升级前备份完整 cluster（Master、Caves、玩家资料），停止服务器后更换所有端的模组文件，再启动核对版本与设置。
- 停用不会撤销已经完成的原版合堆、拾取或共享探索。临时标记、动作、血条和辅助牌不作为持久游戏内容保存。历史停用加载已验证，复杂存档升级仍建议先在副本试运行。
- 未知／损坏的 Wildwise 地图保存数据会原样保留并停止该模块修改，避免部分恢复覆盖旧数据；先保留存档和日志，再定位原因。
- 发现同功能模组时会按已知工坊 ID 停用对应重叠功能并显示原因，列表见[功能与兼容](docs/features.md)。这不等于全部组合兼容认证。
- 自动拾取无效先检查服务器许可和个人开关；菜单无响应先检查聊天／输入焦点和自定义热键；客户端无法加入先核对文件版本、目录层级和两 shard 配置。

报告问题请附：Wildwise 版本、DST 分支／版本、主机或专服、角色与所在 shard、启用模块／配置、最短复现步骤、预期／实际结果，以及出错时的 `client_log.txt` 和对应 `server_log.txt` 片段。优先在隔离副本只开 Wildwise 复测；公开日志前去掉账号标识与访问令牌。信息读取异常可临时开启 `diagnostics`，每类首次失败会记录摘要。

同类定位在服主允许后可检查普通容器、一层包裹及原版口袋存储，不解包、不生成物品。草／树枝／浆果和 Woby 晾肉架读取当前游戏计时；暂停或没有可信数据时省略数值。经过虫洞或切换 shard 后，旧队列与预览会清空。

## 开发指南：架构、扩展与测试

运行时仅依赖游戏 Lua 5.1 与原生资源，Node／Python 只用于开发。源码分为 `core`（配置、协议、生命周期）、`services`（规则与状态）、`runtime`（引擎事件／动作适配）和 `ui`（显示／输入）；世界组件负责服务端协调。新增信息类别已有隔离读取入口，无需把所有功能塞回启动文件。

扩展时先明确数据归属和服务器权限，再接服务与引擎事件；中文注释说明公共方法与非显然约束。监听／任务／包装器必须有释放路径，新增公共设置同步 `modinfo`、配置、翻译、两份 README 和测试。详见[架构与扩展约定](docs/architecture.md)。当前没有承诺稳定的第三方插件 API。

开发需要 Lua 5.1（含 `luac`）、LuaRocks、Python 3、Node.js 24：

```sh
luarocks --lua-version=5.1 install luacheck 1.2.0-1
luarocks --lua-version=5.1 install lua-cjson 2.1.0.10-1
npm ci
npm run format
npm run check
npm run package
```

格式由固定版本 StyLua 管理：Lua 5.1、四空格、保留函数间空行、不压缩函数体。`check` 执行格式、静态检查、121 项纯 Lua 测试、7 项采集器夹具测试及发布白名单／Lua 编译检查；输出 `dist/Wildwise-0.3.0.zip` 和 SHA-256。安装包不含测试、开发依赖、参考模组源码或游戏资源。

本版通过 **111 项原版引擎／无画面界面合约检查**：此前 85 项、本轮能力 17 项、外观生命周期 6 项及异步掉落 3 项。外观生命周期中的皮肤资产入口使用替身，尚未验证实际皮肤渲染；此前保存恢复／解包检查保留为历史证据。**这些不是图形客户端、真实多人、Master/Caves 往返或性能兼容认证**。具体结果、集中掉落性能与复现命令见[测试报告](docs/testing.md)。

## 文档与当前边界

- [功能覆盖与兼容](docs/features.md)：每项功能的实现和实机缺口。
- [三年工坊问题审查](docs/workshop-issues.md)：35 个模组、3,588 条近三年去重评论、74 个场景，以及排除理由、修复和测试映射。
- [0.3.0 落实记录](docs/implementation-2026-09-14.md)：能力补齐、皮肤适配、配置变化及剩余验收事项。
- [实机回归用例](docs/manual-regressions.md)：真实玩家、洞穴、图形和长时负载的操作步骤，当前待执行。
- [源码与机制调研](docs/research.md)：借鉴的设计、原版接口与许可边界。

当前尚未完成图形客户端、真实多人和两小时稳定性验收；新旧存档、特殊角色、皮肤／调味图像及外部模组组合需继续实机验证。正式分支测试不代表 updatebeta 可用，也不宣称整体性能最优。

代码采用 [MIT](LICENSE)；原生资源和参考作品的权利见[第三方说明](THIRD_PARTY_NOTICES.md)。
