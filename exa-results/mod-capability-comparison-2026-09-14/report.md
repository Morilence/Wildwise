# Wildwise 与 7 个参考模组：源码功能与配置边界评估

结论：**Wildwise 0.2.1 已经整合了七类常用能力，但目前不等于七个参考模组的完整替代品。** 信息模块的专用描述与调节粒度、队列的完整任务流程、地图/物品的独立控制项是主要差距。优先顺序建议为：现有行为正确性与实机验收 → 高频权限/配置 → 日常非战斗流程 → 常用信息 → 需求明确后再扩展。本文仅评估，没有修改实现、服务器配置、测试或发布状态。

## 阅读入口

- [完整配置表：参考194项 + Wildwise原生38项](/usr/local/src/Wildwise/exa-results/mod-capability-comparison-2026-09-14/configurations.md)；[可筛选配置CSV](/usr/local/src/Wildwise/exa-results/mod-capability-comparison-2026-09-14/configuration-matrix.csv)。
- [动作逐项表](/usr/local/src/Wildwise/exa-results/mod-capability-comparison-2026-09-14/actions.md)；[动作CSV](/usr/local/src/Wildwise/exa-results/mod-capability-comparison-2026-09-14/action-matrix.csv)。
- [Wildwise全部信息字段及实际赋值情况](/usr/local/src/Wildwise/exa-results/mod-capability-comparison-2026-09-14/wildwise-fields.md)。
- [8列模组支持矩阵CSV](/usr/local/src/Wildwise/exa-results/mod-capability-comparison-2026-09-14/capability-matrix.csv)。
- [Insight全部描述器入口索引](/usr/local/src/Wildwise/exa-results/mod-capability-comparison-2026-09-14/insight-descriptor-index.csv)；[源码快照清单](/usr/local/src/Wildwise/exa-results/mod-capability-comparison-2026-09-14/source-audit.json)。

## 判断口径与证据范围

✅ 表示**被审查版本存在该行所述的实际实现或用户配置入口**，包括默认关闭的能力；仍受该行的角色、组件、目标、权限等条件约束。❌ 表示该行所述的完整能力没有对应实现/入口，可能有相关基础值或局部流程；具体差别写在同一行。无关领域的❌只是职责之外，不代表该模组质量差。不能将这些行简单相加计算“完成率”。

功能与配置分开计：例如 Wildwise 支持包裹内容图标，但不能配置关闭；支持 `TERRAFORM` 候选动作，但没有铲地皮的区域计划入口。源码里的 schema 声明、返回给客户端但没渲染的字段、内部默认常量均不直接算玩家可用能力。未完成实机验收单独列出，不用❌冒充功能不存在。

范围来自仓库原有 research.md 的7个核心参考；35个工坊评论样本是问题背景，不扩成35个功能基线。没有额外捏造“血条参考模组”，血条作为 Wildwise 自有能力列出。

本轮用 Exa 执行2组检索，共取得10条检索结果，并读取6个核心工坊页面；去除重复URL/第三方API导航和评论模板后，仅用作者说明定位功能，最终结论以源码为主。页面缓存中的“已移除/不兼容”模板、相对日期和用户评论不作为实时状态或已复现缺陷的证明。没有使用搜索结果条数冒充独立证据数量。

Wildwise 固定在提交 `9a80d9f8f72a498ae7bf92eccb66b0db88a4e249`，工作区开始时干净。本次静态分析读取当前代码；没有重新运行游戏客户端、专服或多人测试。原有 public 747465 专服验证记录作为历史证据，不能推导所有当前分支/组合已兼容。

## 版本与来源

| 模组 | 版本 | 公开配置数 | 证据类型 | 来源 |
| --- | --- | --- | --- | --- |
| Insight | 6.0.6 | 114 | 现有 Git 源码快照 | [Insight](https://github.com/penguin0616/Insight/tree/e0912f30de127f16c5bf35d27a0ea78e607366aa)；[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162)；[modinfo.lua](/tmp/wildwise-research/insight/modinfo.lua) |
| Global Positions | 1.7.6 | 7 | 现有 Git 源码快照 | [Global Positions](https://github.com/rezecib/Global-Positions/tree/defb25620be92cc307e1b7ceef6f512a7c5d5ea0)；[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=378160973)；[modinfo.lua](/tmp/wildwise-research/global-positions/modinfo.lua) |
| Wormhole Marks | 1.4.5 | 1 | 原工坊 legacy ZIP 解出的源码 | [Wormhole Marks](https://steamcommunity.com/sharedfiles/filedetails/?id=362175979)；[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=362175979)；[modinfo.lua](/tmp/wildwise-research/wormhole/modinfo.lua) |
| Auto Stack and Pick Up | 0.3.1 | 21 | SteamCMD 原工坊发布文件；本轮读取 | [Auto Stack and Pick Up](https://steamcommunity.com/sharedfiles/filedetails/?id=1803285852)；[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=1803285852)；[modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua) |
| ActionQueue RB3 | 4.3 | 21 | 本轮 SteamCMD 新下载原版4.3；不再用非官方衍生版替代 | [ActionQueue RB3](https://steamcommunity.com/sharedfiles/filedetails/?id=2873533916)；[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=2873533916)；[modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua) |
| 智能小木牌 | 1.1.8 | 7 | SteamCMD 原工坊发布文件；本轮读取 | [智能小木牌](https://steamcommunity.com/sharedfiles/filedetails/?id=1595631294)；[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=1595631294)；[modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modinfo.lua) |
| Beefalo Status Bar | 1.4.0 | 23 | SteamCMD 原工坊发布文件；本轮读取 | [Beefalo Status Bar](https://steamcommunity.com/sharedfiles/filedetails/?id=2477889104)；[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=2477889104)；[modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua) |
| Wildwise | 0.2.1 | 38 | 当前工作区运行代码 | [modinfo.lua](/usr/local/src/Wildwise/modinfo.lua)；[features.md](/usr/local/src/Wildwise/docs/features.md) |

Insight Git：`e0912f30de127f16c5bf35d27a0ea78e607366aa`；Global Positions Git：`defb25620be92cc307e1b7ceef6f512a7c5d5ea0`。这定义了审查快照，不宣称Git主分支此后没有更新。原版RB3的全部Lua文件校验摘要已单独写入 source-audit.json；没有把参考源码加入仓库。

非官方 ActionQueue 衍生版版本 `3.2.14`、Git `6776f5b6fd3efa29df61d54316d180349a45ab32` 仅用于辨别来源差异：25个配置里新增了可调浇水/施肥阈值、递归/持续实体任务等；不在原版 RB3 的21项配置中。原版仍有固定90%浇水、普通无尽部署和批量建筑，不能因为排除衍生功能就把原版这些能力漏掉。[衍生源码](https://github.com/alicia-vanca/ActionQueue-RB3-with-endless-action-Unofficial-modification/tree/6776f5b6fd3efa29df61d54316d180349a45ab32)。

## 各自完整职责概览

| 模组 | 职责 | 公开配置数 | 与Wildwise的主要关系 |
| --- | --- | --- | --- |
| Insight | 通用/组件/特定实体信息、范围、高亮、指示器、UI/手柄、外部Wiki查询 | 114（110普通+4动态） | 常用数值已覆盖；专用信息、显示控制、范围/高亮差距最大。四食材计算器是 Wildwise 额外能力。 |
| Global Positions | 位置、探索、记分板分享开关、烟火、5类地图标记及轮盘/手柄 | 7 | 共享基础已覆盖；接收方显示开关、信号许可、地图内编辑、头像与手柄不足。 |
| Wormhole Marks | 使用后标记成对虫洞、22套色图、保存、可选穿迷雾 | 1 | 编号和逐端迷雾已覆盖；不同配色/穿迷雾不必机械追齐。 |
| Auto Stack and Pick Up | 新掉落/手丢/生成与读档、自动拾取、三套半径、方向/类别排除 | 21 | 核心操作具备；过滤、标签/火焰/树枝树边界和独立半径更值得补。 |
| ActionQueue RB3 4.3 | 选择队列、工作/收集、材料工具续接、农业/建筑部署、钓鱼、扩展API | 21 | 有界执行框架已具备；实际非战斗动作闭环与交互配置仍明显少于原版。 |
| 智能小木牌 | 首件图标、包裹、皮肤/调味、可挖、第三方API | 7 | Wildwise 内置容器更广；包裹显示开关、逐箱控制和外观适配不足。 |
| Beefalo Status Bar | 骑乘五徽章、计时/鞍具、阈值、主题/音效/颜色/定位、HUD集成 | 23 | 关键读数齐备；呈现方式和可配置性未追平，需先做真实客户端布局验收。 |
| Wildwise 0.2.1 | 七类整合模块、独立敌意血条、统一权限/缓存、4格食谱计算、保护性预算 | 38原生；另有个人偏好 | 不能定位成“七个参考模组的全部能力合集”；更接近常用能力整合及较严格的自动化/共享边界。 |

## 功能支持矩阵

列缩写：**I**＝Insight；**G**＝Global Positions；**H**＝Wormhole Marks；**A**＝Auto Stack and Pick Up；**Q**＝原版ActionQueue RB3 4.3；**S**＝智能小木牌；**B**＝Beefalo Status Bar；**W**＝Wildwise。每个分组保留同样8列，便于横向检查。建议列都是评估意见，未形成已批准开发范围。

### 信息：通用数值

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F001 | 悬停实体与库存物品信息 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 仅对当前可见或有持有/开箱权限的对象查询；不保证每个 prefab 有专用信息。 | 保持 |
| F002 | 检查修饰键展开更多详情 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 常规最多 10 行，minimal 4 行，按检查键最多 25 行；detailed 预设仍常规最多 10 行。 | 应补截断提示及可配置行数 |
| F003 | 信息密度预设 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Insight 4 套预设；Wildwise minimal/standard/detailed 3 档，主要改变级别和行数，不是完整的逐项配置方案。 | 先补独立开关，再完善预设 |
| F004 | 当前/最大生命值 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise health/currenthealth 与 GetMaxWithPenalty，支持数值缺失时省略。牛栏另见骑乘分组。 | 保持 |
| F005 | 基础普通攻击伤害 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 读取 combat.defaultdamage 或数值型 weapon.damage，不执行函数型动态伤害。 | 应补可信动态接口与限定说明 |
| F006 | 位面伤害/位面防御独立显示 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 调用 planardamage/GetDamage 与 planardefense/GetDefense，不能视为最终实战伤害。 | 保持 |
| F007 | 阵营伤害加成/抗性、套装及复杂武器特效 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight 有 damagetypebonus/resist、setbonus 和专用武器描述器；Wildwise 未接入。 | 常用装备优先补 |
| F008 | 护甲剩余耐久/吸收率 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise condition、absorb_percent / health.absorb；没有最终多层防御合成。 | 保持基础值，按需补合成说明 |
| F009 | 工具剩余次数、总次数、百分比 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise finiteuses 三个字段；没有库存格常驻覆盖数字。 | 保持；补库存格显示 |
| F010 | 防水、保温类别/数值、移速、装备理智变化 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 读取组件基础字段，未汇总角色技能、装备套装和环境全部倍率。 | 明确基础值，常用修正按需 |
| F011 | 装备/物品充能与冷却时间 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight rechargeable/cooldown/pocketwatch；Wildwise 只有燃料/加工/生长等固定类别。 | 应补 |
| F012 | 维修、缝补、升级材料的恢复量/升级进度 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 的 REPAIR 队列动作不代表能展示修补值。 | 应补常用装备信息 |
| F013 | 物品湿度与实体温度、暖石状态 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 有防水和世界温度，但没有物品湿度/体温/暖石温度读取。 | 应补温度与保鲜相关信息 |
| F014 | 实体被冰冻的状态提示 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 通过 freezable:IsFrozen() 输出 frozen；Insight 本快照未有同等通用 freezable 描述器。双方还存在燃烧相关提示：Wildwise 为 burning 布尔值，Insight 的燃烧余时见下一行。 | 保持；不要把暖石低温或冰封鱼塘当作通用实体冰冻状态 |
| F015 | 燃烧时间/传播、爆炸伤害和爆炸抗性 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight burnable/propagator/explosive/explosiveresist；Wildwise 只有 burning 状态及基础攻击。 | 可按危险物品优先补 |
| F016 | 通用实体计时器列表 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight timer/worldsettingstimer；Wildwise 未查询普通实体 timer，只有特定业务字段。 | 应补白名单、友好名称和暂停语义 |
| F017 | 库存格数字/百分比/混合常驻显示 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 仅 hover/HUD，没有 itemtile 数值覆盖层。 | 应补高频耐久/鲜度显示 |
| F018 | 图标模式、文字着色与字体选择 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 使用固定原版字体的文字，只有字号/全局缩放。 | 图标模式按需；可读性先验收 |
| F019 | 游戏天/现实时间切换及摄氏/华氏 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 时间固定分:秒；世界温度显示游戏值；基础腐败余量另标非倒计时。 | 应补时间语义和单位选项 |
| F020 | 物品/组件描述器公开扩展 API | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight AddComponentDescriptor/AddPrefabDescriptor；Wildwise 内部可扩展，但没有公开注册接口。 | 核心稳定后按需补 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F001 | [I:descriptors](/tmp/wildwise-research/insight/scripts/descriptors)；[W:services/observer.lua](/usr/local/src/Wildwise/scripts/wildwise/services/observer.lua)；[W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua) |
| F002 | [I:modinfo.lua](/tmp/wildwise-research/insight/modinfo.lua)；[W:ui/format.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/format.lua) |
| F003 | [I:scripts](/tmp/wildwise-research/insight/scripts)；[W:ui/format.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/format.lua)；[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua) |
| F004 | [I:descriptors/health.lua](/tmp/wildwise-research/insight/scripts/descriptors/health.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F005 | [I:descriptors/combat.lua](/tmp/wildwise-research/insight/scripts/descriptors/combat.lua)；[I:descriptors/weapon.lua](/tmp/wildwise-research/insight/scripts/descriptors/weapon.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F006 | [I:descriptors/planardamage.lua](/tmp/wildwise-research/insight/scripts/descriptors/planardamage.lua)；[I:descriptors/planardefense.lua](/tmp/wildwise-research/insight/scripts/descriptors/planardefense.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F007 | [I:descriptors/damagetypebonus.lua](/tmp/wildwise-research/insight/scripts/descriptors/damagetypebonus.lua)；[I:descriptors/damagetyperesist.lua](/tmp/wildwise-research/insight/scripts/descriptors/damagetyperesist.lua)；[I:descriptors/setbonus.lua](/tmp/wildwise-research/insight/scripts/descriptors/setbonus.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F008 | [I:descriptors/armor.lua](/tmp/wildwise-research/insight/scripts/descriptors/armor.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F009 | [I:descriptors/finiteuses.lua](/tmp/wildwise-research/insight/scripts/descriptors/finiteuses.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F010 | [I:descriptors/waterproofer.lua](/tmp/wildwise-research/insight/scripts/descriptors/waterproofer.lua)；[I:descriptors/insulator.lua](/tmp/wildwise-research/insight/scripts/descriptors/insulator.lua)；[I:descriptors/equippable.lua](/tmp/wildwise-research/insight/scripts/descriptors/equippable.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F011 | [I:descriptors/rechargeable.lua](/tmp/wildwise-research/insight/scripts/descriptors/rechargeable.lua)；[I:descriptors/cooldown.lua](/tmp/wildwise-research/insight/scripts/descriptors/cooldown.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F012 | [I:descriptors/repairer.lua](/tmp/wildwise-research/insight/scripts/descriptors/repairer.lua)；[I:descriptors/repairable.lua](/tmp/wildwise-research/insight/scripts/descriptors/repairable.lua)；[I:descriptors/sewing.lua](/tmp/wildwise-research/insight/scripts/descriptors/sewing.lua)；[I:descriptors/upgradeable.lua](/tmp/wildwise-research/insight/scripts/descriptors/upgradeable.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F013 | [I:descriptors/moisture.lua](/tmp/wildwise-research/insight/scripts/descriptors/moisture.lua)；[I:descriptors/temperature.lua](/tmp/wildwise-research/insight/scripts/descriptors/temperature.lua)；[I:prefab_descriptors/heatrock.lua](/tmp/wildwise-research/insight/scripts/prefab_descriptors/heatrock.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F014 | [I:descriptors](/tmp/wildwise-research/insight/scripts/descriptors)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F015 | [I:descriptors/burnable.lua](/tmp/wildwise-research/insight/scripts/descriptors/burnable.lua)；[I:descriptors/propagator.lua](/tmp/wildwise-research/insight/scripts/descriptors/propagator.lua)；[I:descriptors/explosive.lua](/tmp/wildwise-research/insight/scripts/descriptors/explosive.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F016 | [I:descriptors/timer.lua](/tmp/wildwise-research/insight/scripts/descriptors/timer.lua)；[I:descriptors/worldsettingstimer.lua](/tmp/wildwise-research/insight/scripts/descriptors/worldsettingstimer.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F017 | [I:modinfo.lua:itemtile_display](/tmp/wildwise-research/insight/modinfo.lua:1172)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F018 | [I:modinfo.lua](/tmp/wildwise-research/insight/modinfo.lua)；[W:ui/format.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/format.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F019 | [I:modinfo.lua](/tmp/wildwise-research/insight/modinfo.lua)；[W:ui/format.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/format.lua) |
| F020 | [I:doc/Adding Modded Information.md](</tmp/wildwise-research/insight/doc/Adding Modded Information.md>)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |

### 信息：食物与加工

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F021 | 查看者角色的食用资格和三维收益 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 按 eater/edible/foodmemory/吸收倍率计算；遇到未知 custom_stats_mod_fn 省略估算。 | 应补原版角色覆盖测试，保持不调用未知副作用回调 |
| F022 | 食物记忆影响最终估算 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 使用 GetFoodMultiplier；没有展示当前惩罚、记忆恢复时间或独立开关。 | 补记忆详情应优于重复做三维基础值 |
| F023 | 食物 buff/调味效果、特殊食用机制文本 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 不展示持续时间、属性 buff 明细和全部角色特例。 | 应补常见料理/调味/角色特例 |
| F024 | 鲜度百分比 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise GetPercent；与环境修正后的剩余时间是两项能力。 | 保持 |
| F025 | 结合保鲜容器/温度/湿度的腐败时间估计 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight 有 DST_Perish 倍率估算；Wildwise 仅 perishremainingtime 基础余量。两者均不能由静态代码保证所有新环境倍率正确。 | 应补经当前引擎校验的估时 |
| F026 | 食材类型与料理标签权重 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 读取 cooking.ingredients，显示肉度等标签；前端摘要可能按文本预算截断。 | 保持并改进中文名称 |
| F027 | 四食材料理结果预测 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 普通锅/便携锅，返回最高优先级所有候选；Insight 的配方入口是 Wiki 查询，stewer 显示已开始烹饪的产物，未见同等四格计算器。 | 保持并验收真实菜单流程 |
| F028 | 从制作/食谱页面打开物品 Wiki 或原模组页面 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight recipelookup 提供外部链接，不是内置完整百科；Wildwise 没有对应入口，四格计算器也不负责材料反查。 | 按需补高频查询，非基础整合必需 |
| F029 | 锅内已选定产物/份数、厨师及烹饪速度修正 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight stewer 显示产物/厨师/速度；Wildwise 只读剩余时间。其四格查询服务虽返回 weight/cooktime，菜单却只列名称，不能据字段宣称有概率/时长展示。 | 应补结果解释与可见细节 |
| F030 | 燃料百分比、基础余时、燃料物品热值 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 余时=currentfuel/rate；不保证火堆/角色/环境所有修正。 | 先补单位与倍率适配，再宣传准确倒计时 |
| F031 | 锅内烹饪剩余时间、传统晾晒剩余时间 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 原版 stewer/dryer 接口，仅处于加工状态才显示。 | 保持 |
| F032 | 新版多格肉架/Woby 肉架下一份可读完成时间 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise dryingrack/wobyrack 快照取最小数值，未展示全部格子明细；Insight 当前快照未见对应新组件专用读取。 | 补逐格与暂停原因按需；先验收 |
| F033 | 普通作物/树木生长阶段与可读取剩余时间 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise growable stage/targettime；不等于完整多阶段成长预测。 | 保持并补暂停/季节原因 |
| F034 | 草/树枝/浆果原生再生时间 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 支持本地 targettime 与外部再生计时回调，暂停/枯萎时省略。 | 保持 |
| F035 | 收获物类型、生产数量/上限和完整再生产逻辑 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise harvestable 只读 produce，缺少完整数量/上限/生产周期。 | 常用蜂箱/蘑菇农场等应补 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F021 | [I:descriptors/edible.lua](/tmp/wildwise-research/insight/scripts/descriptors/edible.lua)；[I:descriptors/eater.lua](/tmp/wildwise-research/insight/scripts/descriptors/eater.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F022 | [I:descriptors/edible.lua](/tmp/wildwise-research/insight/scripts/descriptors/edible.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F023 | [I:descriptors/edible.lua](/tmp/wildwise-research/insight/scripts/descriptors/edible.lua)；[I:descriptors/debuffable.lua](/tmp/wildwise-research/insight/scripts/descriptors/debuffable.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F024 | [I:descriptors/perishable.lua](/tmp/wildwise-research/insight/scripts/descriptors/perishable.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F025 | [I:descriptors/perishable.lua](/tmp/wildwise-research/insight/scripts/descriptors/perishable.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F026 | [I:descriptors/edible.lua](/tmp/wildwise-research/insight/scripts/descriptors/edible.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua)；[W:services/recipes.lua](/usr/local/src/Wildwise/scripts/wildwise/services/recipes.lua) |
| F027 | [I:scripts](/tmp/wildwise-research/insight/scripts)；[W:services/recipes.lua](/usr/local/src/Wildwise/scripts/wildwise/services/recipes.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F028 | [I:scripts](/tmp/wildwise-research/insight/scripts)；[W:services/recipes.lua](/usr/local/src/Wildwise/scripts/wildwise/services/recipes.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F029 | [I:descriptors/stewer.lua](/tmp/wildwise-research/insight/scripts/descriptors/stewer.lua)；[W:services/recipes.lua](/usr/local/src/Wildwise/scripts/wildwise/services/recipes.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F030 | [I:descriptors/fueled.lua](/tmp/wildwise-research/insight/scripts/descriptors/fueled.lua)；[I:descriptors/fuel.lua](/tmp/wildwise-research/insight/scripts/descriptors/fuel.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F031 | [I:descriptors/stewer.lua](/tmp/wildwise-research/insight/scripts/descriptors/stewer.lua)；[I:descriptors/dryer.lua](/tmp/wildwise-research/insight/scripts/descriptors/dryer.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F032 | [W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua)；[I:descriptors/dryer.lua](/tmp/wildwise-research/insight/scripts/descriptors/dryer.lua) |
| F033 | [I:descriptors/growable.lua](/tmp/wildwise-research/insight/scripts/descriptors/growable.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F034 | [I:descriptors/pickable.lua](/tmp/wildwise-research/insight/scripts/descriptors/pickable.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F035 | [I:descriptors/harvestable.lua](/tmp/wildwise-research/insight/scripts/descriptors/harvestable.lua)；[I:prefab_descriptors/mushroom_farm.lua](/tmp/wildwise-research/insight/scripts/prefab_descriptors/mushroom_farm.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |

### 信息：农业、角色与世界

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F036 | 土壤三类养分数值 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 仅在农作物对象上读取 GetTileNutrients，显示三个数；无帽子资格/分档/比例配置。 | 补名称、解释和权限细化 |
| F037 | 土壤湿润/不湿润状态 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 只有 IsSoilMoistAtPoint 布尔值。 | 保持真实语义 |
| F038 | 土壤精确水分、消耗速率/区间显示 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 无精确湿度；不能把布尔潮湿度写成百分比。 | 农业用户需要时补可信读取 |
| F039 | 作物当前压力描述 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 调用 GetStressDescription(viewer)，不自行列举所有压力源。 | 保持 |
| F040 | 压力累计点/等级、逐项压力原因/资格配置 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight 明确返回压力点、等级和测试出的 stressors；Wildwise 不具备同等细节。 | 应补，帮助玩家采取行动 |
| F041 | 肥料三类养分 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 显示 nutrients 三元组；没有独立堆肥干湿料贡献。 | 保持并补友好说明 |
| F042 | 堆肥贡献/干湿料比例、作物重量、巨型作物判定辅助 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight compostingbin/forcecompostable/weighable 等；Wildwise 未接入。 | 农业核心按需优先补 |
| F043 | 授粉、蜂群/巢穴/孵化、可刷毛与再生信息 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight pollinator/childspawner/breeder/hatchable/brushable；Wildwise 不提供这些专用描述。 | 按常用实体分批补 |
| F044 | 随从主人名称及可读忠诚剩余时间 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise follower.leader/targettime；不等于总领导额度/全随从列表。 | 保持 |
| F045 | 领导者随从列表、兽群成员/发情细节 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 仅简单 follower 信息与牛驯化字段。 | 按需补 |
| F046 | 未骑乘牛的基础驯化/顺从/倾向 hover | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 有 domesticatable 读数；独立 Beefalo Status Bar 只在骑牛时工作。 | 保持 |
| F047 | 自己的基础饥饿/理智变化速率 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 显示 hungerrate/sanity.rate，未归因全部环境与技能修正。 | 明确基础语义 |
| F048 | 玩家/生物完整饥饿、理智、光环与交互增减详情 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 骑乘 hunger 不等于通用 hunger 描述器，也没有 sanityaura、采花/跳虫洞理智损益说明。 | 应补常用理智光环及角色状态 |
| F049 | 角色专用状态：WX 扫描/电路、旺达年龄、温蒂羁绊、伍迪变身、沃尔夫冈力量等 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight 有 wx78_scanner/upgrademodule/oldager/ghostlybond/wereness/mightiness 等入口；Wildwise 无对应字段。 | 按原版角色使用频率逐项补 |
| F050 | 季节、剩余季节天数、世界日/阶段、世界温度/湿度 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 从 TheWorld.state 读出，世界日是 cycles 原始计数，未在该读取器加一。 | 应核对玩家界面的日数口径 |
| F051 | 已允许的 worldsettingstimer 摘要 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 最多 12 个，按键排序；原始内部事件名+秒数，不是完整危险面板。 | 应补语义化和按事件权限 |
| F052 | 天气趋势、雨雪/酸雨和洞穴梦魇周期 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 当前天气值不等于天气预报/洞穴周期。 | 应补日常可行动信息 |
| F053 | 猎犬/Boss 刷新、裂隙/墨荒/兔王/蝙蝠/月冰等专用事件信息 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight 有独立 world 描述器；Wildwise 通用前 12 个 timer 不能保证覆盖、命名或状态解释。 | 应分批补公开状态；隐藏信息保持服主许可 |
| F054 | 危险事件宣告与世界地图 hover 信息 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 无主动危险宣告；地图 hover 只给自己的标记信息。 | 宣告按需；先做好静态解释 |
| F055 | 淘气值：玩家计数/阈值及击杀贡献 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight 借私有闭包/upvalue 适配；Wildwise schema 有 naughtiness，但运行读取器不写该值，故 ❌。 | 可暂缓；不必为了齐全引入脆弱私有接口 |
| F056 | 淡水/海钓鱼量、鱼竿/浮标/鱼饵参数、海网进度 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight fishable/fishingrod/oceanfishingrod/oceanfishingtackle/oceantrawler；Wildwise 无专用字段。 | 海钓用户按需，常用海网进度可先补 |
| F057 | 交易价值、蚁狮安抚、修建投入、船体/桅杆等专属参数 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight tradable/appeasement/constructionsite/boathealth/mast；Wildwise 不提供对应专用详情。 | 交易/修建/船体常用项按需补 |
| F058 | 节庆玩法：鸦年华、牛年选美/评估、龙舟奖励等 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 无节庆专属描述器。 | 可暂缓 |
| F059 | DS 单机 RoG/SW/Hamlet 专用信息 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight 同源支持单机分支；本次 DST 需求不要求 Wildwise 实现火山/海妖/大灾变等单机机制。 | 可忽略，排除于 DST 缺口 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F036 | [I:descriptors/farmsoildrinker.lua](/tmp/wildwise-research/insight/scripts/descriptors/farmsoildrinker.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F037 | [I:descriptors/farmsoildrinker.lua](/tmp/wildwise-research/insight/scripts/descriptors/farmsoildrinker.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F038 | [I:descriptors/farmsoildrinker.lua](/tmp/wildwise-research/insight/scripts/descriptors/farmsoildrinker.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F039 | [I:descriptors/farmplantstress.lua](/tmp/wildwise-research/insight/scripts/descriptors/farmplantstress.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F040 | [I:descriptors/farmplantstress.lua](/tmp/wildwise-research/insight/scripts/descriptors/farmplantstress.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F041 | [I:descriptors/fertilizer.lua](/tmp/wildwise-research/insight/scripts/descriptors/fertilizer.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F042 | [I:descriptors/compostingbin.lua](/tmp/wildwise-research/insight/scripts/descriptors/compostingbin.lua)；[I:descriptors/forcecompostable.lua](/tmp/wildwise-research/insight/scripts/descriptors/forcecompostable.lua)；[I:descriptors/weighable.lua](/tmp/wildwise-research/insight/scripts/descriptors/weighable.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F043 | [I:descriptors/pollinator.lua](/tmp/wildwise-research/insight/scripts/descriptors/pollinator.lua)；[I:descriptors/childspawner.lua](/tmp/wildwise-research/insight/scripts/descriptors/childspawner.lua)；[I:descriptors/brushable.lua](/tmp/wildwise-research/insight/scripts/descriptors/brushable.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F044 | [I:descriptors/follower.lua](/tmp/wildwise-research/insight/scripts/descriptors/follower.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F045 | [I:descriptors/leader.lua](/tmp/wildwise-research/insight/scripts/descriptors/leader.lua)；[I:descriptors/herdmember.lua](/tmp/wildwise-research/insight/scripts/descriptors/herdmember.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F046 | [I:descriptors/domesticatable.lua](/tmp/wildwise-research/insight/scripts/descriptors/domesticatable.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua)；[B:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modmain.lua) |
| F047 | [I:descriptors/hunger.lua](/tmp/wildwise-research/insight/scripts/descriptors/hunger.lua)；[I:descriptors/sanity.lua](/tmp/wildwise-research/insight/scripts/descriptors/sanity.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F048 | [I:descriptors/hunger.lua](/tmp/wildwise-research/insight/scripts/descriptors/hunger.lua)；[I:descriptors/sanityaura.lua](/tmp/wildwise-research/insight/scripts/descriptors/sanityaura.lua)；[I:prefab_descriptors/wormhole.lua](/tmp/wildwise-research/insight/scripts/prefab_descriptors/wormhole.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F049 | [I:descriptors](/tmp/wildwise-research/insight/scripts/descriptors)；[I:prefab_descriptors](/tmp/wildwise-research/insight/scripts/prefab_descriptors)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F050 | [I:descriptors/clock.lua](/tmp/wildwise-research/insight/scripts/descriptors/clock.lua)；[I:descriptors/weather.lua](/tmp/wildwise-research/insight/scripts/descriptors/weather.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F051 | [I:descriptors/worldsettingstimer.lua](/tmp/wildwise-research/insight/scripts/descriptors/worldsettingstimer.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F052 | [I:descriptors/weather.lua](/tmp/wildwise-research/insight/scripts/descriptors/weather.lua)；[I:descriptors/caveweather.lua](/tmp/wildwise-research/insight/scripts/descriptors/caveweather.lua)；[I:descriptors/nightmareclock.lua](/tmp/wildwise-research/insight/scripts/descriptors/nightmareclock.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F053 | [I:descriptors/hounded.lua](/tmp/wildwise-research/insight/scripts/descriptors/hounded.lua)；[I:descriptors/riftspawner.lua](/tmp/wildwise-research/insight/scripts/descriptors/riftspawner.lua)；[I:descriptors/shadowthrallmanager.lua](/tmp/wildwise-research/insight/scripts/descriptors/shadowthrallmanager.lua)；[I:descriptors/rabbitkingmanager.lua](/tmp/wildwise-research/insight/scripts/descriptors/rabbitkingmanager.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F054 | [I:modinfo.lua:danger_announcements](/tmp/wildwise-research/insight/modinfo.lua:4500)；[I:modinfo.lua:show_map_info](/tmp/wildwise-research/insight/modinfo.lua:4458)；[W:ui/map.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/map.lua) |
| F055 | [I:descriptors/kramped.lua](/tmp/wildwise-research/insight/scripts/descriptors/kramped.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F056 | [I:descriptors](/tmp/wildwise-research/insight/scripts/descriptors)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F057 | [I:descriptors](/tmp/wildwise-research/insight/scripts/descriptors)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F058 | [I:descriptors/carnivaldecor.lua](/tmp/wildwise-research/insight/scripts/descriptors/carnivaldecor.lua)；[I:descriptors/yotb_stager.lua](/tmp/wildwise-research/insight/scripts/descriptors/yotb_stager.lua)；[I:descriptors/yotd_raceprizemanager.lua](/tmp/wildwise-research/insight/scripts/descriptors/yotd_raceprizemanager.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F059 | [I:modinfo.lua](/tmp/wildwise-research/insight/modinfo.lua)；[I:descriptors/aporkalypse.lua](/tmp/wildwise-research/insight/scripts/descriptors/aporkalypse.lua)；[I:descriptors/volcanomanager.lua](/tmp/wildwise-research/insight/scripts/descriptors/volcanomanager.lua)；[W:modinfo.lua](/usr/local/src/Wildwise/modinfo.lua) |

### 信息：定位与范围

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F060 | 允许范围内查询箱子和一层包裹内容 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 服主默认禁用；容器最多看前 80 格、包裹前 40 条，文本有总预算。 | 应补本地化/明确截断和个人包裹选择 |
| F061 | 普通/口袋容器及一层包裹同类定位 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 用上次 hover 的 prefab 手动查询；按观察权限/距离/所有权，返回短时文字标记。 | 保持并验证私有容器边界 |
| F062 | 手持物品/配方材料触发自动高亮 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 需要进物品页点击定位，不提供配方联动和自动材质高亮。 | 应补，减少操作成本 |
| F063 | 可补充燃料对象高亮 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 只有燃料信息和 ADDFUEL 动作，无燃料目标高亮。 | 按需补 |
| F064 | 数值型怪物攻击距离 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise info_attack_range 默认 false，只读 combat.attackrange。 | 保持；不标成范围圈 |
| F065 | 攻击/命中范围圈及两者区分 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 未生成范围指示实体。 | 应补经许可的范围圈 |
| F066 | 避雷针/灭火器/陷阱/爆炸等设施作用范围 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 攻击范围字段不能代替设施范围。 | 应补建家常用设施 |
| F067 | 闪现/灵魂/战歌/书籍/角色装备范围 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 无角色技能范围适配。 | 按需补 |
| F068 | Boss/小 Boss/重要物品/脚印/漂流瓶/玩具/死亡点指示 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 队友指示不包含上述追踪；参考可按种类甚至 prefab 多选。 | 已发现死亡点/重要目标按需；隐藏目标追踪可忽略 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F060 | [I:descriptors/container.lua](/tmp/wildwise-research/insight/scripts/descriptors/container.lua)；[I:descriptors/unwrappable.lua](/tmp/wildwise-research/insight/scripts/descriptors/unwrappable.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F061 | [I:descriptors/container_proxy.lua](/tmp/wildwise-research/insight/scripts/descriptors/container_proxy.lua)；[W:services/containers.lua](/usr/local/src/Wildwise/scripts/wildwise/services/containers.lua)；[W:components/wildwise_world.lua](/usr/local/src/Wildwise/scripts/components/wildwise_world.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F062 | [I:modinfo.lua:highlighting](/tmp/wildwise-research/insight/modinfo.lua:1466)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F063 | [I:modinfo.lua:fuel_highlighting](/tmp/wildwise-research/insight/modinfo.lua:1774)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F064 | [I:descriptors/combat.lua](/tmp/wildwise-research/insight/scripts/descriptors/combat.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F065 | [I:modinfo.lua:attack_range_type](/tmp/wildwise-research/insight/modinfo.lua:2043)；[I:prefabs/insight_range_indicator.lua](/tmp/wildwise-research/insight/scripts/prefabs/insight_range_indicator.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F066 | [I:descriptors/lightningblocker.lua](/tmp/wildwise-research/insight/scripts/descriptors/lightningblocker.lua)；[I:prefab_descriptors/firesuppressor.lua](/tmp/wildwise-research/insight/scripts/prefab_descriptors/firesuppressor.lua)；[I:descriptors/trap.lua](/tmp/wildwise-research/insight/scripts/descriptors/trap.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F067 | [I:modinfo.lua](/tmp/wildwise-research/insight/modinfo.lua)；[I:descriptors/book.lua](/tmp/wildwise-research/insight/scripts/descriptors/book.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F068 | [I:modinfo.lua](/tmp/wildwise-research/insight/modinfo.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua)；[W:ui/map.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/map.lua) |

### 地图协作与虫洞

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F069 | 同 shard 队友地图位置和名称 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Global Positions 有角色图标；Wildwise 统一光标图案+姓名。 | 保持并提升辨识度 |
| F070 | 原版角色头像/皮肤头像的地图与屏边提示 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 地图是统一图标，屏边是姓名文字，没有角色肖像。 | 按可读性需要补 |
| F071 | 队友屏边指示：始终/记分板/关闭 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 只显示同世界、屏幕外、未屏蔽队友。 | 保持 |
| F072 | 位置分享 opt-out | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | GP 在记分板切换；Wildwise 在 F7 地图页。 | 保持，记分板入口按需 |
| F073 | 共享获准探索及保存 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | GP 独立 MapExplorer/主机适配；Wildwise 来源点日志，最多 65,536 点，分批 RevealArea。 | 应补多人/主机/洞穴实际验收 |
| F074 | 位置分享与探索分享分别 opt-out | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | GP 联动 sharing 状态；Wildwise 两个个人设置，服主分别 auto/on/off。 | 保留独立权限 |
| F075 | 本地主机地图整幅拷贝给新加入者 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | GP 非专服直接 RecordMap 本地主机并 LearnRecordedMap 给加入者；专服改用共享副本。Wildwise 只回放获准来源点，不拷贝主机完整地图。 | Wildwise 可保持不回填个人私图 |
| F076 | 撤回队友已经学到的地形 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 与参考都没有可靠的已学地图撤回；关闭只影响后续共享。 | 可忽略，不作撤回承诺 |
| F077 | 荒野模式限制位置分享 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise auto 在荒野或 PvP 关闭；GP 荒野预设还有全火堆冒烟逻辑。 | 保留 Wildwise 默认 |
| F078 | PvP 自动关闭位置/探索分享 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 显式检查 pvp；GP 快照的模式特殊处理针对 wilderness。 | 保留 |
| F079 | 木炭触发营火/火坑信号 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | GP 木炭时长按热值累加至最多360秒；Wildwise 喂木炭后保留信号直到燃料耗尽，且额外支持冷火/冷火坑。 | 应补独立开关 |
| F080 | 所有点燃火堆都作为信号/关闭全部信号 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | GP FIREOPTIONS 三态；Wildwise 固定木炭规则。 | 关闭开关应补；全部点燃模式按需 |
| F081 | 信号火屏边指示及烟雾特效 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 仅地图 fire 标记；update_indicators 只遍历队友。 | 屏边提示按需；烟雾可忽略 |
| F082 | Alt+地图点击创建临时标记 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | GP 轮盘即时选类型；Wildwise 使用预先在 F7 选择的类型。 | 应补地图内快速选类型 |
| F083 | 标记语义类型 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | GP generic/omw/danger/explore/gohere 五种；Wildwise location/danger/resource/rally 四种，非逐一等价。 | 补在路上/探索等按需，保留资源类型 |
| F084 | 标记轮盘、取消/就近删除 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 只有菜单清除自己的所有标记；服务器有按 ID 删除接口，无地图就近删除入口。 | 应补地图内编辑入口 |
| F085 | 临时标记过期 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | GP 固定一个游戏日 TOTAL_DAY_TIME；Wildwise 固定 60 秒，没有 TTL 选项。 | 应补服主可控时长/个数，保留上限 |
| F086 | 每人标记数量限制及归属删除权限 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 每人 5 个、只删自己的，管理员可清全场；GP 删除/清理未做同等归属限制。 | 保持 |
| F087 | 屏蔽玩家后隐藏其标记 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 使用原版 muted 状态，也隐藏其队友位置。 | 保持并做联机验收 |
| F088 | 手柄创建地图标记 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | GP 有右摇杆/控制器路径；Wildwise 地图标记入口要求左 Alt+主操作。 | 若覆盖手柄用户则必须补，否则明确暂不支持 |
| F089 | 跨 shard 队友身份/所在 shard 提示 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 只交换 userid/name/prefab/shard，无远端精确坐标和地图合并；Master/Caves 真实往返待验收。 | 先验收已有设计 |
| F090 | 跨 shard 精确位置/地形合并 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 本组两个地图方案都不能据当前代码称为完整跨 shard 地图合并。 | 可暂缓 |
| F091 | 实际穿越后的同世界虫洞配对 | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | Wormhole Marks starttravelsound；Wildwise 包装 Activate 并核验双向连接，保存稳定编号。 | 保持并验收真实穿越 |
| F092 | 虫洞颜色/编号辨认 | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | 参考 22 对独立彩色图标；Wildwise 编号+6 色循环，不是 22 种独立颜色。 | 保持编号；图形外观按需 |
| F093 | 虫洞逐端遵守迷雾 | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | 参考默认 FoW，不独立实现私人发现账本；Wildwise 即使配对已知仍逐端 CanSeePointOnMiniMap。 | 保持 |
| F094 | 虫洞图标覆盖迷雾/向未探索者公开 | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | 参考 Draw over FoW；Wildwise 固定禁止该显示路径。 | 可忽略 |
| F095 | 巨型触手/有限虫洞同世界配对入口 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 注册 tentacle_pillar、wormhole_limited_1；仍要求有效双向 targetTeleporter，不保证所有特殊连接都通过。 | 先验证，不扩大承诺 |
| F096 | 地面洞穴入口/出口跨 shard 编号着色和迁移信息 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight sinkhole_marks/worldmigrator；Wildwise 跨 shard 队友提示不等于入口出口配对。 | 应补已发现入口匹配，依赖双 shard 验收 |
| F097 | 第三方实体注册全局位置/图标接口 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | GP globalposition 组件及公开图标表；Wildwise 未提供对应公开 API。 | 具体扩展需求出现后补 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F069 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:ui/map.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/map.lua) |
| F070 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:ui/map.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/map.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F071 | [G:modinfo.lua](/tmp/wildwise-research/global-positions/modinfo.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F072 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F073 | [G:prefabs/worldmapexplorer.lua](/tmp/wildwise-research/global-positions/scripts/prefabs/worldmapexplorer.lua)；[W:services/map.lua](/usr/local/src/Wildwise/scripts/wildwise/services/map.lua)；[W:components/wildwise_world.lua](/usr/local/src/Wildwise/scripts/components/wildwise_world.lua) |
| F074 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua)；[W:services/map.lua](/usr/local/src/Wildwise/scripts/wildwise/services/map.lua) |
| F075 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:services/map.lua](/usr/local/src/Wildwise/scripts/wildwise/services/map.lua) |
| F076 | [G:prefabs/worldmapexplorer.lua](/tmp/wildwise-research/global-positions/scripts/prefabs/worldmapexplorer.lua)；[W:services/map.lua](/usr/local/src/Wildwise/scripts/wildwise/services/map.lua) |
| F077 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua) |
| F078 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua) |
| F079 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:runtime/bootstrap.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/bootstrap.lua) |
| F080 | [G:modinfo.lua](/tmp/wildwise-research/global-positions/modinfo.lua)；[W:runtime/bootstrap.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/bootstrap.lua) |
| F081 | [G:components/smokeemitter.lua](/tmp/wildwise-research/global-positions/scripts/components/smokeemitter.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua)；[W:ui/map.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/map.lua) |
| F082 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:ui/map.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/map.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F083 | [G:prefabs/pings.lua](/tmp/wildwise-research/global-positions/scripts/prefabs/pings.lua)；[W:services/map.lua](/usr/local/src/Wildwise/scripts/wildwise/services/map.lua) |
| F084 | [G:widgets/pingwheel.lua](/tmp/wildwise-research/global-positions/scripts/widgets/pingwheel.lua)；[G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua)；[W:services/map.lua](/usr/local/src/Wildwise/scripts/wildwise/services/map.lua) |
| F085 | [G:prefabs/pings.lua](/tmp/wildwise-research/global-positions/scripts/prefabs/pings.lua)；[W:services/map.lua](/usr/local/src/Wildwise/scripts/wildwise/services/map.lua) |
| F086 | [G:modmain.lua:ReceivePing](/tmp/wildwise-research/global-positions/modmain.lua:594)；[W:services/map.lua](/usr/local/src/Wildwise/scripts/wildwise/services/map.lua) |
| F087 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:ui/map.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/map.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F088 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:ui/map.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/map.lua) |
| F089 | [W:components/wildwise_world.lua](/usr/local/src/Wildwise/scripts/components/wildwise_world.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F090 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:components/wildwise_world.lua](/usr/local/src/Wildwise/scripts/components/wildwise_world.lua) |
| F091 | [H:modmain.lua](/tmp/wildwise-research/wormhole/modmain.lua)；[W:runtime/bootstrap.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/bootstrap.lua)；[W:services/map.lua](/usr/local/src/Wildwise/scripts/wildwise/services/map.lua) |
| F092 | [H:modmain.lua](/tmp/wildwise-research/wormhole/modmain.lua)；[W:ui/map.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/map.lua) |
| F093 | [H:modinfo.lua](/tmp/wildwise-research/wormhole/modinfo.lua)；[H:scripts/components/wormhole_marks.lua](/tmp/wildwise-research/wormhole/scripts/components/wormhole_marks.lua)；[W:ui/map.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/map.lua) |
| F094 | [H:modinfo.lua](/tmp/wildwise-research/wormhole/modinfo.lua)；[H:scripts/components/wormhole_marks.lua](/tmp/wildwise-research/wormhole/scripts/components/wormhole_marks.lua)；[W:ui/map.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/map.lua) |
| F095 | [H:modmain.lua](/tmp/wildwise-research/wormhole/modmain.lua)；[W:runtime/bootstrap.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/bootstrap.lua) |
| F096 | [I:prefab_descriptors/cave_entrance.lua](/tmp/wildwise-research/insight/scripts/prefab_descriptors/cave_entrance.lua)；[I:descriptors/worldmigrator.lua](/tmp/wildwise-research/insight/scripts/descriptors/worldmigrator.lua)；[W:runtime/bootstrap.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/bootstrap.lua) |
| F097 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:components/wildwise_world.lua](/usr/local/src/Wildwise/scripts/components/wildwise_world.lua) |

### 自动合堆与拾取

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F098 | 新世界掉落自动合堆 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | 两者均可开关；Wildwise 只处理有已知来源的物体，等待实际落地。 | 保持并补特殊来源验收 |
| F099 | 玩家主动丢弃自动合堆 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | 两者默认关闭；Wildwise 同时保护被禁来源的合并目标。 | 保持 |
| F100 | 读档地面物品合堆开关 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | 参考 StackDuringPopulation 同时涉及生成；Wildwise items_stack_loaded 单独识别恢复。 | 保持默认关闭 |
| F101 | 世界首次生成摆设自动合堆开关 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Wildwise 没有与参考等价的 worldgen 合堆许可；不把读档开关算生成支持。 | 可忽略生成改写 |
| F102 | 世界/手丢/拾取三套独立半径 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Wildwise 共用 items_radius 2/4/6/8，参考分别 1～25。 | 应补 |
| F103 | 向现有堆合并 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Wildwise 固定选择更早合法堆，并使用原生 Put。 | 保持 |
| F104 | 向最新落地点聚拢附近堆 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Wildwise 不提供 Newest 方向。 | 可忽略，避免物品跟着新掉落移动 |
| F105 | 灰烬/粪便/种子分来源过滤 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Wildwise 默认没有这些独立白黑名单；开世界合堆时满足条件就处理。 | 应补 |
| F106 | 树枝树掉落枝条特殊保护 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | 参考可跳过附近 twiggy 树的枝条；Wildwise 无此判断，可能改变自动生产的地面堆计数条件，未实机复现。 | 应优先验证并补边界 |
| F107 | 企鹅蛋生成计数保护 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Wildwise 按 penguin_egg 标签全部排除；参考仅自动堆/拾取排除，允许手动堆路径。 | 保持保护；差异无需追齐 |
| F108 | 活体/重物/陷阱诱饵/飞行物排除 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | 两者都有保护，但具体标签集合不同；不是“全部物品兼容”的证明。 | 保持并补实体回归 |
| F109 | 尊重 no_autostack_all 排除标签 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Wildwise 明确检查该标签。 | 保持 |
| F110 | 分别尊重 no_autostack_w / no_autostack_m / no_autopickup | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Wildwise 未检查这三种分功能排除标签。 | 应优先补，防止违背其他实体声明 |
| F111 | 明确排除着火物品的合堆/拾取 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | 参考检查 fire；Wildwise eligible 没有 fire/IsBurning 检查。是静态保护缺口，尚未证明必然触发故障。 | 应优先验证并补保护 |
| F112 | 等掉落物落地后再处理 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | 参考针对不可拾取/物理/地震 updatetask 重试；Wildwise 检查 is_landed/y/速度/标签并至多重试 30 秒。 | 保持并验证新落石场景 |
| F113 | 自动拾取新世界产生的可堆物 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Wildwise 不对玩家手丢/旧地面物持续扫描，不是全地图吸物；参考同样由新生/掉落处理触发。 | 保持明确范围 |
| F114 | 拾取要求背包已有同类 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Wildwise 默认 true；参考默认 false，均可服主配置。 | 保持谨慎默认 |
| F115 | 每位玩家独立 opt-in 自动拾取 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 服主允许+个人开启；参考为服主统一开关。 | 保持 |
| F116 | 库存不足时先按可接收数量拆分，余量留地 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise CanAcceptCount+Get+GiveItem；参考直接 GiveItem，没有相同的预先容量分割机制。 | 保持并验收特殊背包 |
| F117 | 同平台限制、移动船的局部索引 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 分平台合堆/拾取，船用局部坐标分桶；参考仅世界半径扫描。 | 保持并实机验证船岸 |
| F118 | 最近玩家、同距稳定归属与队列物品预留 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 距离后按 userid 排序，队列预留租约 7 秒；参考缺少同等确定性和整合预留。 | 保持并验收同帧争抢 |
| F119 | 只装服务器即可使用自动整理 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | 参考 server_only_mod；Wildwise 所有客户端需要安装，不能只分发整理模块。 | 可忽略拆包，保持整合定位 |
| F120 | 合堆烟雾特效可开关 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Wildwise 无此特效。 | 可忽略 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F098 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua)；[W:runtime/items.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/items.lua) |
| F099 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F100 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:runtime/items.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/items.lua) |
| F101 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:runtime/items.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/items.lua) |
| F102 | [A:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua)；[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua) |
| F103 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F104 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F105 | [A:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua)；[A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F106 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F107 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F108 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F109 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F110 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F111 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F112 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F113 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F114 | [A:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua)；[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua) |
| F115 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua)；[W:components/wildwise_world.lua](/usr/local/src/Wildwise/scripts/components/wildwise_world.lua) |
| F116 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F117 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F118 | [A:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modmain.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |
| F119 | [A:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua)；[W:modinfo.lua](/usr/local/src/Wildwise/modinfo.lua) |
| F120 | [A:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua) |

### 行为队列与布点

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F121 | 仅客户端即可使用行为队列 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | 原版 RB3 为 client_only_mod；Wildwise 需服务器及所有客户端启用。 | 可忽略客户端独立模式，保持权限整合 |
| F122 | 修饰键单选/双击同类/拖框多选 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Wildwise 同类严格按 prefab，双击固定 0.35 秒/15 距离，框选最多 200 个任务。 | 应补双击参数及选择反馈 |
| F123 | 执行中追加选择/目标去重 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Wildwise queue:add 有去重和上限，执行保持单状态机。 | 保持并验收远程预测 |
| F124 | 手工选择后按原生动作执行 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Wildwise 仅 40 个白名单动作，仍需原生动作选择器返回有效动作；原版 RB3 清单更大且有目标条件。 | 逐动作评估；详见动作附表 |
| F125 | 砍/挖/挖矿/敲打直到单目标完成 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Wildwise 仅 CHOP/MINE/HAMMER/DIG 标记 repeated；其他实体动作不因仍可执行而无限重复。 | 保持；补明确任务终止条件 |
| F126 | 重复非建筑配方制作 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Wildwise 最多 200 次，缺材料/未解锁暂停；保留皮肤参数。 | 保持 |
| F127 | 一键再次制作上次配方 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | RB3 last_recipe_key 默认 C；Wildwise 需要再次找到配方点击。 | 应补 |
| F128 | 工具损坏后换用库存/背包工具 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Wildwise 按动作工具标签选兼容工具；参考 GetNewEquippedItemInHand 更偏向同 prefab。 | 保持，验收特殊角色/皮肤/工具 |
| F129 | 手持材料用尽后续接库存/背包同类 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Wildwise 同 prefab，缺料暂停；不自动制造材料。 | 保持 |
| F130 | 从任意打开容器自动续材料/工具 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 原版 RB3 4.3 与 Wildwise 主要查主库存/背包；衍生版有更广容器检索，不能混记原版。 | 按需，须尊重容器访问权 |
| F131 | 工作完成后自动走过去收集掉落 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | RB3 AutoCollect 加入附近允许的拾取动作；Wildwise 新掉落入包服务不同，既不走过去也不补收旧掉落。 | 应补任务内拾取阶段 |
| F132 | 淡水自动钓鱼抛竿/收竿循环 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | RB3 StartAutoFisher 使用普通 fishingrod 与 FISH/REEL，源码提示不兼容其检测到的延迟补偿路径；Wildwise 无对应循环。 | 按需，不是首批必需 |
| F133 | 新多格肉架自动开箱/取成品/重新挂肉 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | 原版 RB3 4.3 的 STORE/RUMMAGE 专用分支已读取容器槽并提交取物 RPC；Wildwise 明确不排 RUMMAGE，未实现同等闭环。 | 应补原版高频非战斗流程，分别验收主机/远程 |
| F134 | 手动移动/点击/攻击接管 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Wildwise 固定取消剩余任务；参考 always_clear_queue 可调保留选择策略。 | 保留接管优先 |
| F135 | 暂停/继续/清空的可见队列面板 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 有状态、原因、剩余任务和按钮；原版 RB3 主要依赖热键/选择线程，无同等面板。 | 保持并验收 UI |
| F136 | 聊天/地图/菜单/失焦自动暂停且需主动继续 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 显式 input_ready 和 paused 状态；不把 RB3 的 InGame 热键过滤算同等暂停协议。 | 保持 |
| F137 | 死亡/遇袭/虫洞/跨 shard 清理旧任务 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise world/client 两侧清理；参考主要清理线程及手动接管，未见同等事件/会话协议。 | 应先完成真实多人及双 shard 验收 |
| F138 | 显式区域内部署物品、墙体、地皮 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Wildwise 根据 DeploySpacingRadius/墙体1/地皮4生成点，只执行已确认点位，不接管普通建筑。 | 保持并补实际碰撞验收 |
| F139 | 农田 2×2/3×3/4×4 锄地网格 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Wildwise 按原版地块锚定；主手需原生 TILL_tool，不能算所有角色都能锄地。 | 保持 |
| F140 | 多块土地连续铲地皮 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | RB3 TerraFormAtPoint 并识别 pitchfork；Wildwise 虽列 TERRAFORM 白名单，Client:plan 只支持材料 DEPLOY 或 TILL，缺完整框选入口。 | 应补入口与执行链 |
| F141 | 多块土地逐块浇水/施肥 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | RB3 有专用 WaterAtPoint/FertilizeAtPoint；Wildwise 普通实体 FERTILIZE/POUR_WATER 不等于土地区域布点。 | 应补农业闭环 |
| F142 | 单块农田浇水至固定约 90% | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | 原版 RB3 读 nutrients_overlay 动画位置，阈值写死 0.9；Wildwise 没有此循环。 | 应采用可信状态与上限后再补 |
| F143 | 可配置浇水/施肥停止阈值 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 原版 RB3 4.3 无该配置，衍生版 3.2.14 才有 stop_watering_at/stop_fertilizing_at。 | 可按需作为新设计，不记原版必追齐 |
| F144 | 批量建造带 placer 的建筑 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | RB3 OnUp 通过 BufferBuild/MakeRecipeAtPoint 布点；Wildwise 明确过滤 recipe.placer 并放行单次原版建筑。 | 按需且先验证与原生放置兼容 |
| F145 | 无法部署的物品按网格批量丢放 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | RB3 DropActiveItem；Wildwise Client:plan 只创建 DEPLOY/TILL，普通不可部署物不能完成该流程。 | 按需；不作为默认自动整理的一部分 |
| F146 | 墙/陷阱/地皮间距与独立地皮网格显示 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | RB3 F3 网格、半径、颜色、牙陷阱间距；Wildwise 仅任务预览，无独立地皮覆盖层。 | 独立网格按需，陷阱间距可补 |
| F147 | 蛇形扫描区域点位 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Wildwise 固定按世界 X/Z 蛇形；RB3 支持镜头朝向和 double_snake 扩展。 | 保持有界路径 |
| F148 | 可旋转朝向/双蛇形/无尽部署 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | Wildwise 无相应配置，始终有限区域；原版 endless_deploy 是扩展部署，不等于衍生版递归选实体。 | 可暂缓或忽略无尽模式 |
| F149 | 执行前有效/无效点预览并显式确认 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 临时原生轮廓、叉号、有效点计数、执行按钮；RB3 拖框完成即开始，没有同等确认流程。 | 保持 |
| F150 | 移动平台上保存局部坐标并重投影 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise Planner.project；不代表船上所有可部署物已实机验收。 | 保持并验收 |
| F151 | 公开动作注册/CherryPick 条件扩展接口 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | RB3 AddActionQueuerAction/List 与 AddModCherryPickFn；Wildwise 白名单是内部表。 | 核心稳定后按需补 |
| F152 | 自动选敌/战斗 AI/躲避 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | RB3 的 ATTACK 只允许墙目标，不等于自动战斗；Wildwise 明确排除 ATTACK/CASTSPELL 自动化。 | 可忽略且保持范围外 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F121 | [Q:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua)；[W:modinfo.lua](/usr/local/src/Wildwise/modinfo.lua) |
| F122 | [Q:scripts/components/actionqueuer.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua)；[W:runtime/input.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/input.lua) |
| F123 | [Q:scripts/components/actionqueuer.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua)；[W:services/queue.lua](/usr/local/src/Wildwise/scripts/wildwise/services/queue.lua) |
| F124 | [Q:scripts/components/actionqueuer.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F125 | [Q:scripts/components/actionqueuer.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F126 | [Q:scripts/components/actionqueuer.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua)；[W:runtime/input.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/input.lua)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F127 | [Q:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modmain.lua)；[W:runtime/input.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/input.lua) |
| F128 | [Q:scripts/components/actionqueuer.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F129 | [Q:scripts/components/actionqueuer.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F130 | [Q:scripts/components/actionqueuer.lua:GetNewActiveItem](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:824)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F131 | [Q:scripts/components/actionqueuer.lua:AutoCollect](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:949)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua)；[W:services/queue.lua](/usr/local/src/Wildwise/scripts/wildwise/services/queue.lua) |
| F132 | [Q:scripts/components/actionqueuer.lua:StartAutoFisher](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:1315)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F133 | [Q:scripts/components/actionqueuer.lua:SendAction](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:484)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F134 | [Q:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modmain.lua)；[W:runtime/input.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/input.lua) |
| F135 | [Q:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modmain.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua)；[W:services/queue.lua](/usr/local/src/Wildwise/scripts/wildwise/services/queue.lua) |
| F136 | [Q:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modmain.lua)；[W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua)；[W:services/queue.lua](/usr/local/src/Wildwise/scripts/wildwise/services/queue.lua) |
| F137 | [Q:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modmain.lua)；[W:components/wildwise_world.lua](/usr/local/src/Wildwise/scripts/components/wildwise_world.lua)；[W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua) |
| F138 | [Q:scripts/components/actionqueuer.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua)；[W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua)；[W:services/planner.lua](/usr/local/src/Wildwise/scripts/wildwise/services/planner.lua) |
| F139 | [Q:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua)；[W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua) |
| F140 | [Q:scripts/components/actionqueuer.lua:OnUp](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:714)；[W:runtime/client.lua:plan](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua:12) |
| F141 | [Q:scripts/components/actionqueuer.lua:OnUp](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:714)；[W:runtime/client.lua:plan](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua:12) |
| F142 | [Q:scripts/components/actionqueuer.lua:WaterTile](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:781)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F143 | [Q:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua)；[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua) |
| F144 | [Q:scripts/components/actionqueuer.lua:OnUp](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:714)；[W:runtime/input.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/input.lua)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F145 | [Q:scripts/components/actionqueuer.lua:DropActiveItem](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:766)；[W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua) |
| F146 | [Q:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua)；[Q:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modmain.lua)；[W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua) |
| F147 | [Q:scripts/components/actionqueuer.lua:DeployToSelection](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:29)；[W:services/planner.lua](/usr/local/src/Wildwise/scripts/wildwise/services/planner.lua) |
| F148 | [Q:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua)；[Q:scripts/components/actionqueuer.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua)；[W:services/planner.lua](/usr/local/src/Wildwise/scripts/wildwise/services/planner.lua) |
| F149 | [Q:scripts/components/actionqueuer.lua:OnUp](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:714)；[W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F150 | [W:services/planner.lua](/usr/local/src/Wildwise/scripts/wildwise/services/planner.lua) |
| F151 | [Q:scripts/components/actionqueuer.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F152 | [Q:scripts/components/actionqueuer.lua:AddAction](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:61)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |

### 智能小木牌

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F153 | 普通木箱首个非空格的物品图标 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | 参考与 Wildwise 都不是固定第1格；Wildwise 空箱不生成牌。 | 保持 |
| F154 | 龙鳞箱/冰箱/盐盒独立支持 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | 参考三个默认 false；Wildwise 龙鳞箱默认 true，冰箱/盐盒默认 false。 | 保持并说明默认差异 |
| F155 | 切斯特/哈奇/鱼类箱/远古船货舱内置支持 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 4 种额外内置 prefab；参考提供外部 API，但未直接注册这四种。 | 保持；不要把 API 可能性算内置支持 |
| F156 | 包裹内部首件图标 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | 参考 BundleItems 默认 false，通过 SpawnPrefab 取图；Wildwise 固定读取保存记录，无独立开关。 | 应补显示开关；保持无副作用读取 |
| F157 | 调味图层/物品自带绘图覆盖 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | Wildwise 走原版 drawimageoverride/drawatlasoverride/inv_image_bg；未知资产跳过，图形客户端未验收。 | 保持并补皮肤/调味客户端验证 |
| F158 | 小木牌本体随箱中 minisign_item 换肤 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | 参考 ChangeSkin 重建小木牌并传 linked_skinname；Wildwise 不支持本体皮肤交换。 | 按需 |
| F159 | 空箱清除旧图 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | 参考保留空牌清 OverrideSymbol；Wildwise 移除辅助牌，不留空标识。 | 保持；空牌保留可忽略 |
| F160 | 内容增减/首件 imagechange 即时刷新 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | 参考主要 onclose；Wildwise 监听 itemget/itemlose/imagechange/onremove 并合并更新。 | 保持 |
| F161 | 可挖除、仅玩家可挖、保存不再生牌状态 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | 参考 Digornot/OnlyPlayer+nohuaminisign；Wildwise NOCLICK/FX 且移除 workable，不可逐箱拆牌。 | 建议补显示控制；挖除与持久实体玩法可忽略 |
| F162 | 容器移除/烧毁后释放辅助牌 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | Wildwise parent+scope 清理，辅助牌不进存档；参考还保存牌皮肤/移除状态。 | 保持并验收移动/烧毁外观 |
| F163 | 第三方箱子通过公开 API 增加小木牌 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | 参考 SMART_SIGN_DRAW；Wildwise 8 prefab 硬白名单，改配置不能增加任意箱子。 | 具体第三方需求出现后补 |
| F164 | 已正确注册原生图集的第三方物品绘图 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | Wildwise 在其已支持容器内可使用原生库存/绘图接口；不承诺所有第三方图像正确。 | 保持，并选择真实模组验证 |
| F165 | 扫描其他模组资产并包装全局 RegisterPrefabs | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | Wildwise 不采用该加载方式；缺少本能力不是产品缺陷。 | 可忽略，维持原生图集接口 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F153 | [S:scripts/components/smart_minisign.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/scripts/components/smart_minisign.lua)；[W:services/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/services/signs.lua) |
| F154 | [S:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modinfo.lua)；[S:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modmain.lua)；[W:modinfo.lua](/usr/local/src/Wildwise/modinfo.lua) |
| F155 | [S:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modmain.lua)；[W:services/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/services/signs.lua) |
| F156 | [S:scripts/components/smart_minisign.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/scripts/components/smart_minisign.lua)；[W:services/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/services/signs.lua) |
| F157 | [S:scripts/components/smart_minisign.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/scripts/components/smart_minisign.lua)；[W:services/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/services/signs.lua) |
| F158 | [S:scripts/components/smart_minisign.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/scripts/components/smart_minisign.lua)；[W:runtime/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/signs.lua) |
| F159 | [S:scripts/components/smart_minisign.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/scripts/components/smart_minisign.lua)；[W:runtime/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/signs.lua) |
| F160 | [S:scripts/components/smart_minisign.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/scripts/components/smart_minisign.lua)；[W:runtime/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/signs.lua) |
| F161 | [S:scripts/components/smart_minisign.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/scripts/components/smart_minisign.lua)；[W:runtime/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/signs.lua) |
| F162 | [S:scripts/components/smart_minisign.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/scripts/components/smart_minisign.lua)；[W:runtime/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/signs.lua) |
| F163 | [S:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modmain.lua)；[W:services/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/services/signs.lua) |
| F164 | [S:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modmain.lua)；[W:services/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/services/signs.lua) |
| F165 | [S:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modmain.lua)；[W:runtime/signs.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/signs.lua) |

### 骑牛状态栏

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F166 | 骑乘牛时显示、下牛时隐藏 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | 参考明确限 beefalo prefab；Wildwise 读当前坐骑实际具备字段，不给 Woby 虚构驯化信息。 | 保持并验收骑乘切换 |
| F167 | 骑乘生命、驯化、顺从、倾向数值 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | Wildwise 文字面板；参考独立徽章，倾向由徽章颜色编码。 | 先补布局可读性验收 |
| F168 | 骑乘原版踢落剩余时间 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | 两者均适配顺从提升后的 bucktask 重置；Wildwise 直接订阅读取任务剩余时间。 | 保持并验证当前引擎 |
| F169 | 鞍具剩余使用次数 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | Wildwise 固定文本行；参考悬停骑乘计时徽章显示鞍名/次数。 | 保持，鞍名可补 |
| F170 | 按最大值归一化的生命/饥饿进度徽章 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | 参考以当前值/上限驱动徽章；Wildwise schema 虽读取上限，但 mount_text 只列当前值，没有归一化徽章或当前/上限文本。 | 应补 当前/上限，避免只看见绝对数 |
| F171 | 饥饿阈值激活、归零收起 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | 默认均15；两者骑乘期间达到阈值也会激活，饥饿归零后收起。 | 保持 |
| F172 | 饥饿徽章可独立禁用 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | 参考 HungerThreshold=false；Wildwise 0 是阈值为零，不是关闭，不能混用。 | 应补字段显示开关 |
| F173 | 运行中热键开关和位置调整 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | 参考 T；Wildwise B，可重绑定；Wildwise F7 保存设置，B 仅改内存值直到后续设置保存。 | 应补细调和持久语义 |
| F174 | 牛栏单独缩放与精细偏移 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | Wildwise 仅全 HUD 缩放及粗档偏移，无独立缩放。 | 应补 |
| F175 | 徽章主题、颜色、背景、间距、动画/声音 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | Wildwise 文字面板，无等价外观/动画/声音参数。 | 装饰项可暂缓，信息可读性优先 |
| F176 | Combined Status / 原版 HUD 换肤与背包布局专用集成 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | 参考有 RepositionStatusBar/主题路径；Wildwise 未作同等集成，不能以全局缩放替代。 | 应先做兼容验收，再决定适配 |
| F177 | Woby/自定义坐骑提供与牛等价的全部驯化面板 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 参考只接受牛；Wildwise 仅按现有组件读字段，不能称为所有坐骑完整支持。 | 按需，为各坐骑分别建信息边界 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F166 | [B:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modmain.lua)；[W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F167 | [B:widgets/beefaloStatusBar.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/scripts/widgets/beefaloStatusBar.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F168 | [B:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modmain.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F169 | [B:widgets/beefaloStatusBar.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/scripts/widgets/beefaloStatusBar.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F170 | [B:widgets/beefaloStatusBar.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/scripts/widgets/beefaloStatusBar.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F171 | [B:widgets/beefaloStatusBar.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/scripts/widgets/beefaloStatusBar.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F172 | [B:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua)；[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F173 | [B:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modmain.lua)；[W:runtime/input.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/input.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F174 | [B:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F175 | [B:modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua)；[B:widgets/beefaloStatusBar.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/scripts/widgets/beefaloStatusBar.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F176 | [B:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modmain.lua)；[B:widgets/beefaloStatusBar.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/scripts/widgets/beefaloStatusBar.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F177 | [B:modmain.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modmain.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |

### Wildwise 整合和交付边界

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F178 | 七类功能统一设置，信息/血条/骑乘共用实体订阅 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Wildwise 信息、血条、骑乘合并实体订阅，使用统一 F7 五页设置；此行比较七类整合范围，不表示其他模组没有自己的缓存和设置页。 | 保持并验收模块交互 |
| F179 | 基于敌意的战斗血条 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | 本次7个核心参考没有独立同等模块；Wildwise 关注敌对自己/随从/附近玩家，可选4种范围。 | 作为自有能力保留，不捏造参考血条模组 |
| F180 | 血条数量、脱战保留、比例、数值显示配置 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | 4/8/12/16/20 条；0/1/2/3/5秒；0.75/1/1.25/1.5；numbers 开关。个人 linger 有保存字段但 F7 无调整入口。 | 应补个人脱战时间菜单入口 |
| F181 | 血条显示时抑制 hover 重复血量 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | 实际血条不可见时保留 hover 血量；信息/血条关闭仍分别受服务器许可约束。 | 保持并验收遮挡/目标切换 |
| F182 | 已知参考模组启用时按模块自动避让 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | 10 个已知工坊 ID，仅关闭重叠功能；虫洞仅关闭内部 wormholes。不是所有组合兼容认证。 | 保持，补真实组合验收 |
| F183 | 中英文个人设置持久化与服主权限分离 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Insight 有多语言个人配置、KnownModIndex 保存与服主强制项；Wildwise 为38个服主选项及 wildwise_client_v2 个人偏好，显示项初始值不覆盖已保存偏好。两者许可模型并不逐项相同。 | 保持并补完整设置导出/重置评估 |
| F184 | 描述器错误提示与局部降级 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Insight LoadDescriptor 捕获加载错误并返回错误描述；Wildwise 每类读取器独立 pcall，diagnostics 首次失败日志。都不能据此宣称任何运行错误均不会崩溃。 | 保持；客户端真实问题需要更可读原因 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F178 | [W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F179 | [W:services/health.lua](/usr/local/src/Wildwise/scripts/wildwise/services/health.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F180 | [W:modinfo.lua](/usr/local/src/Wildwise/modinfo.lua)；[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F181 | [W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua)；[W:ui/format.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/format.lua) |
| F182 | [W:core/config.lua:conflicts](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua:236) |
| F183 | [I:modmain.lua](/tmp/wildwise-research/insight/modmain.lua)；[I:scripts/screens/insightconfigurationscreen.lua](/tmp/wildwise-research/insight/scripts/screens/insightconfigurationscreen.lua)；[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua)；[W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua) |
| F184 | [I:modmain.lua:LoadDescriptor](/tmp/wildwise-research/insight/modmain.lua:810)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |

### 需要单独说明的实现细节

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F185 | 冷火/冷火坑作为信号火 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | GP 本快照直接注册 campfire/firepit，另适配指定 Deluxe Campfires；Wildwise 还注册 coldfire/coldfirepit。 | 保持；信号寿命/关闭规则应可控 |
| F186 | 食谱结果界面显示候选概率和预测耗时 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Wildwise 服务层有 weight/cooktime，菜单未渲染；Insight 快照未见同等四格候选概率界面。 | 可补 Wildwise 现有结果解释，不记参考独占 |
| F187 | 对自动化动作增加目标级/上下文级允许条件 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | RB3 对 ATTACK/ACTIVATE/HEAL/STORE 等逐动作加限定；Wildwise 多数只用 action.id 白名单和原生 picker，没有等价的目标策略表。 | 应先逐动作审查副作用；非战斗不等于可无条件批量执行 |
| F193 | 信息查询与目标选择的手柄专用适配 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight 有 inventorybar/followtext/controller 路径；Wildwise 仅菜单局部原生焦点导航，不能算完整查询手柄支持。 | 若面向手柄玩家则应补 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F185 | [G:modmain.lua](/tmp/wildwise-research/global-positions/modmain.lua)；[W:runtime/bootstrap.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/bootstrap.lua) |
| F186 | [I:scripts/uichanges/recipelookup.lua](/tmp/wildwise-research/insight/scripts/uichanges/recipelookup.lua)；[W:services/recipes.lua](/usr/local/src/Wildwise/scripts/wildwise/services/recipes.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F187 | [Q:scripts/components/actionqueuer.lua:AddAction](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/scripts/components/actionqueuer.lua:61)；[W:runtime/actions.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/actions.lua) |
| F193 | [I:modinfo.lua](/tmp/wildwise-research/insight/modinfo.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua)；[W:runtime/input.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/input.lua) |

### 补充的专用信息与集成

| ID | 能力 | I | G | H | A | Q | S | B | W | 实现边界 | 评估 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F188 | 针对当前查看者防御/角色修正的伤害估算 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight combat.GetRealDamage 结合攻击者/目标倍率、护甲和旺达年龄转换；Wildwise 只有基础普通/位面值。参考也未涵盖所有自定义回调，不能保证任意最终伤害。 | 应补可信常见修正，不承诺任意实战精确值 |
| F189 | 作物/整块土地的养分净增减及耗水速率 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight farmsoildrinker 有单株和整地块营养/水分delta；Wildwise 只显示三类存量和湿润布尔值。 | 农业用户需求明确时补，优先解释缺什么 |
| F190 | 记分板队友生命等共享状态 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight display_shared_stats 与 playerstatusscreen 有专用入口；Wildwise 队友列表只有姓名/所在shard，敌意血条不是队友状态面板。 | 按需并需独立分享许可 |
| F191 | 与 Status Announcements 的信息宣告集成 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight itemdetail/wxchargedisplay 可调用已安装模组的_StatusAnnouncer；不是无需依赖的独立聊天分享。Wildwise 无对应集成。 | 具体多人协作需求后补，不应自动对外发送 |
| F192 | 可选崩溃报告上传与错误报告状态界面 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Insight crash_reporter 配置和 CrashReporter 按客户端/主机/专服状态判断是否可上报，并有报告状态组件；Wildwise diagnostics 仅本地诊断，无上传入口。这里只确认源码路径，不验证远端报告服务当前可用。 | 自动上传可忽略；本地可读诊断优先 |

源码证据：

| 行 | 具体源码 |
| --- | --- |
| F188 | [I:descriptors/combat.lua](/tmp/wildwise-research/insight/scripts/descriptors/combat.lua)；[I:descriptors/weapon.lua](/tmp/wildwise-research/insight/scripts/descriptors/weapon.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F189 | [I:descriptors/farmsoildrinker.lua](/tmp/wildwise-research/insight/scripts/descriptors/farmsoildrinker.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua) |
| F190 | [I:scripts/uichanges/playerstatusscreen.lua](/tmp/wildwise-research/insight/scripts/uichanges/playerstatusscreen.lua)；[W:components/wildwise_world.lua](/usr/local/src/Wildwise/scripts/components/wildwise_world.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |
| F191 | [I:scripts/widgets/itemdetail.lua](/tmp/wildwise-research/insight/scripts/widgets/itemdetail.lua)；[I:scripts/uichanges/wxchargedisplay.lua](/tmp/wildwise-research/insight/scripts/uichanges/wxchargedisplay.lua)；[W:ui/hud.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/hud.lua) |
| F192 | [I:scripts/services/crashreporter.lua](/tmp/wildwise-research/insight/scripts/services/crashreporter.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua)；[W:ui/menu.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/menu.lua) |

## 只评估：建议补齐与可忽略项

以下基于“保留Wildwise统一权限、有界任务、原生资源、常用体验整合”的当前实现定位；若以后明确要求逐项替代全部参考模组，范围和优先级需另行重估。没有按功能数量最多来排序。

| 顺序 | 建议对象 | 为什么 | 相对工作量/依赖 | 补齐后应达到的边界 |
| --- | --- | --- | --- | --- |
| P0：先验证正确性和边界 | 物品分功能排除标签、着火物、树枝树生产计数；队列目标条件；文案/字段真实含义 | 关系到玩家已有世界行为及误操作。当前确认的是缺少检查，不把静态缺口伪报成已复现故障。 | 较小～中等；各需当前引擎实体复现 | 不改变数量/来源/实体生命周期；允许与禁止条件有可复核证据 |
| P0：已有功能实机验收 | 图形UI、主机+远程玩家、Master/Caves往返、移动船、真实背包、并发争抢/共享、长时运行 | 现有专服与Lua测试没有覆盖这些完整场景；再加功能不会补上这层证据。 | 中等～较大，依赖真实客户端和多人环境 | 当前启用功能在目标组合下完成流程，无丢物、串数据、旧队列残留 |
| P1：高频配置和隐私控制 | 信息独立开关/时间单位/截断提示；三套物品半径/类别过滤；地图玩家/火/标记独立开关；木牌包裹开关 | 现有实现很多是固定策略，服主和玩家难以调到需要的行为；独立权限比花哨主题更有价值。 | 中等，需统一服务器许可/个人显示/默认值 | 默认值安全且兼容已有偏好；关闭某项不必关整个模块 |
| P1：非战斗日常任务闭环 | 肉架开取挂、直接烹烤/灌装/缝补/海网/镰刀等动作；工作后收集；农业区域铲地/浇水/施肥 | 当前“白名单有动作”与“用户能完成整段任务”差距明确，参考原版已有可比流程。 | 中等～较大；先终止条件与副作用检查，再接交互 | 明确选定目标/区域；材料不足/失败能停；手工接管立即有效；主机/远程分别验证 |
| P1：常用信息的可信程度 | 腐败倍率估时、加工产物/暂停原因、通用冷却/计时器、压力源、常用维修/装备效果 | 比罗列大量小众 prefab 更能帮助玩家决定吃/换/补水/施肥/等多久。 | 中等；逐组件受当前引擎约束 | 缺字段显式降级；不把基础值、估计和最终值混写 |
| P1/P2：显示与快捷操作 | 牛栏独立缩放/细偏移/饥饿隐藏、生命/饥饿归一化；地图内标记轮盘/删除；上次配方；双击参数；血条脱战时间菜单 | 直接减少切页和误点。参考方案可借鉴，但应统一原版HUD风格。 | 较小～中等，取决于图形布局 | 不同分辨率/中文/背包/Combined Status等实际可读、不遮挡 |
| P2：需求驱动的能力扩展 | 角色专用状态、海钓详情/自动钓鱼、已发现Boss/物品/死亡点指示、洞穴入口对应、批量建筑、第三方API | 有明确用户后再加；复杂兼容和新的权限面会增加维护成本。 | 中等～较大 | 每项有单独使用场景和清楚权限；不将API潜力算内置覆盖 |
| 可忽略/暂缓 | 穿迷雾、隐藏目标/淘气值私有接口、无尽/递归执行、自动战斗、世界生成改写、Newest聚堆、全资产扫描、烟雾/音效/主题大量组合、DS单机/节庆长尾 | 或超出当前边界，或价值低于维护与行为风险；没有必须追成一比一替代的依据。 | 不建议当前投入 | 保留明确的不支持说明，不用未实现字段/无效配置伪装支持 |

以下几项尤其不宜被误写成“已支持”：`naughtiness` 只有schema；腐败值只是基础余量；`recipe.weight/cooktime`未在菜单展示；`health_max/hunger_max`未在牛栏形成上限文本或比例条；`TERRAFORM`/土块浇水的白名单不等于区域操作；`map.wormholes`和处理预算不是可配置字段。

只需要先做一轮有限补齐：物品保护与过滤、已有联机/图形验收、少量高频控制项、肉架/农业/工作后拾取闭环。角色长尾、批量建筑、第三方扩展和装饰主题等，应有真实使用需求再进入范围。手柄如果属于目标用户，则从“按需”上调为核心输入验收要求。

## 全量清单与完整性校验

| 清单 | 本轮覆盖 | 为什么单独列出 |
| --- | --- | --- |
| 功能矩阵 | 193行 × 8个模组 | 按可判断的功能边界拆分；不做支持率排名 |
| 原生/运行时配置 | 232项：参考194 + Wildwise38 | 逐项记录键、默认值、完整枚举、对应差异与评估 |
| 队列动作 | 76种候选/专用动作入口 | 显式区分白名单、专门交互流程和目标条件 |
| Wildwise个人设置 | 32个保存叶子字段 | 区分F7入口、纯内部状态、已保存但无菜单项 |
| Wildwise信息字段 | 61个schema字段 | 排查声明存在但不赋值，以及赋值但界面不显示 |
| Insight描述器 | 289个非example入口文件（209组件+82prefab，减2示例） | 逐文件列配置引用、命名输出和语义键；包括单机分支，入口数不当功能数 |

全量配置通过受限Lua 5.1环境求值得到，剔除标题/分隔项；仅暴露必要标准库与翻译函数，没有运行参考 modmain，也没有网络/游戏回调。动作清单只抽实际点击注册及显式执行方法，未把注释/工具分类当支持。每条功能证据都解析为实际存在的本地源文件/目录；所有参考Lua文件保留SHA-256。

Insight逐文件索引是防漏入口清单，并不声称每个描述器在DST都生效。有些文件服务DS单机、只安装hook、转调其他描述器，或本身不输出文本；核心玩家能力已经按上面分组归纳。要查特定prefab的长尾能力，可沿索引直接回到对应源码。

## 验证边界

本轮验证了配置枚举、动作入口清单、源码链接、计数和快照一致性；没有因为只是交付分析而改动运行实现。Wildwise原有验证层次仍以 [testing.md](/usr/local/src/Wildwise/docs/testing.md)、[features.md](/usr/local/src/Wildwise/docs/features.md) 为准。图形客户端、真实多人、Master/Caves往返、复杂外部模组组合及长期稳定性仍需分别完成。参考支持标记表示版本源码实现，不等于本轮在最新引擎全部实测通过。
