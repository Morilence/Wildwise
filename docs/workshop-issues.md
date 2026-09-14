# 三年工坊问题与回归清单

采集日期：2026-09-14。近三年窗口为北京时间 **2023-09-14～2026-09-14**。本轮通过 Steam 公开评论接口取得 **35 个 DST 模组、58 页、4,584 条去重评论**，其中 **3,588 条**在窗口内；全部翻页到时间边界或末页。相比首轮 16 个模组的缓存分页，本轮使用评论 ID 和 Unix 时间去重／筛选，不再拿日期标签数当评论数。

保留 R01～R20 并展开具体触发，本清单现有 **74 个可行动场景**。它们不是 74 个已复现的独立根因：同一机制可覆盖多个触发，作者已修复、尚未证实和不在 Wildwise 范围内的报告分别标明。

## 数据取得与判断

- 从 Exa 搜索、原模组说明和评论中继续追踪替代版本，共做 12 次搜索；另取得 27 个讨论串分页和 6 个讨论目录。Insight Bug Reporting 补取第 49～69 页，含时间边界与最新尾页。讨论贴按回复日期判断，不用 2020 年的主帖日期排除新回复。
- 普通评论页面遇到限流后改用公开 render 接口；按服务端 offset/total、精确时间和评论 ID 校验，出现截断、重复整页或错误偏移会记录缺口。未绕过私有资料；一个 Craft Pot 讨论分页仍抓取失败。
- 排除同名但属于 DayZ／单机 Don’t Starve 的两个候选。外部专有模组冲突暂缓；信息＋血条＋地图＋牛＋队列＋木牌＋料理／定位的组合均纳入。
- 隐藏、删除或未公开日志无法恢复。审核占位文本不被解释成问题；公开接口分页也不是原子历史快照，不能宣称所有历史反馈均已找到。
- 正文与完整玩家日志只保留在本地研究目录。仓库仅保留必要转述、来源 ID／日期／链接和校验值。采集清单见 [workshop-coverage.json](evidence/workshop-coverage.json)，结构化案例见 [workshop-cases.json](evidence/workshop-cases.json)。

## 模组覆盖

| 模组 | 窗口内去重评论 | 到达边界 |
|---|---:|---|
| [Insight (Show Me+)](https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162) | 992 | 是 |
| [Global Positions](https://steamcommunity.com/sharedfiles/filedetails/?id=378160973) | 276 | 是 |
| [Wormhole Marks [DST]](https://steamcommunity.com/sharedfiles/filedetails/?id=362175979) | 96 | 是 |
| [Auto Stack and Pick Up](https://steamcommunity.com/sharedfiles/filedetails/?id=1803285852) | 67 | 是 |
| [ActionQueue RB3](https://steamcommunity.com/sharedfiles/filedetails/?id=2873533916) | 130 | 是 |
| [Smart Minisign](https://steamcommunity.com/sharedfiles/filedetails/?id=1595631294) | 74 | 是 |
| [Beefalo Status Bar](https://steamcommunity.com/sharedfiles/filedetails/?id=2477889104) | 55 | 是 |
| [Show Me (Origin)](https://steamcommunity.com/sharedfiles/filedetails/?id=666155465) | 124 | 是 |
| [Simple Health Bar DST](https://steamcommunity.com/sharedfiles/filedetails/?id=1207269058) | 207 | 是 |
| [Global Positions (CompleteSync)](https://steamcommunity.com/sharedfiles/filedetails/?id=3138571948) | 244 | 是 |
| [Auto Stack Pro](https://steamcommunity.com/sharedfiles/filedetails/?id=2115943953) | 1 | 是 |
| [Smart Minisign Revisited](https://steamcommunity.com/sharedfiles/filedetails/?id=2881739960) | 0 | 是 |
| [ActionQueue Reborn](https://steamcommunity.com/sharedfiles/filedetails/?id=1608191708) | 75 | 是 |
| [Beefalo Widget](https://steamcommunity.com/sharedfiles/filedetails/?id=1852257480) | 56 | 是 |
| [😶‍🌫️骑牛状态显示 Beefalo Status Bar](https://steamcommunity.com/sharedfiles/filedetails/?id=2995399263) | 30 | 是 |
| [Fix for 'Beefalo information'](https://steamcommunity.com/sharedfiles/filedetails/?id=2158755579) | 5 | 是 |
| [Health Info](https://steamcommunity.com/sharedfiles/filedetails/?id=375859599) | 62 | 是 |
| [Epic Healthbar](https://steamcommunity.com/sharedfiles/filedetails/?id=1185229307) | 274 | 是 |
| [[DST] Monster Healthbars](https://steamcommunity.com/sharedfiles/filedetails/?id=786566397) | 1 | 是 |
| [ActionQueue RB2 (RWYS supported)](https://steamcommunity.com/sharedfiles/filedetails/?id=2325441848) | 24 | 是 |
| [ActionQueue Reborn v2](https://steamcommunity.com/sharedfiles/filedetails/?id=2701099322) | 2 | 是 |
| [ActionQueue Expansion: Extra Actions](https://steamcommunity.com/sharedfiles/filedetails/?id=2892856427) | 5 | 是 |
| [Finder Redux](https://steamcommunity.com/sharedfiles/filedetails/?id=2281925291) | 8 | 是 |
| [Item Info](https://steamcommunity.com/sharedfiles/filedetails/?id=836583293) | 58 | 是 |
| [Craft Pot [DS, ROG, SW, DST]](https://steamcommunity.com/sharedfiles/filedetails/?id=727774324) | 161 | 是 |
| [Finder 2026](https://steamcommunity.com/sharedfiles/filedetails/?id=3705461241) | 1 | 是 |
| [Show Me (Refresh)](https://steamcommunity.com/sharedfiles/filedetails/?id=3436020204) | 30 | 是 |
| [Beefalo Info HUD](https://steamcommunity.com/sharedfiles/filedetails/?id=3439927311) | 353 | 是 |
| [Beefalo information](https://steamcommunity.com/sharedfiles/filedetails/?id=801304958) | 1 | 是 |
| [Beefalo Buck Timer (Client-Side)](https://steamcommunity.com/sharedfiles/filedetails/?id=2858947939) | 36 | 是 |
| [Domestication Calculator](https://steamcommunity.com/sharedfiles/filedetails/?id=2622561786) | 1 | 是 |
| [Item Info Updated](https://steamcommunity.com/sharedfiles/filedetails/?id=3118627881) | 62 | 是 |
| [Where's My Stuff, Dude? (Finder For Gamepad)](https://steamcommunity.com/sharedfiles/filedetails/?id=837819197) | 17 | 是 |
| [Wormhole Marks [DST Continued]](https://steamcommunity.com/sharedfiles/filedetails/?id=3571706033) | 15 | 是 |
| [Health indicators](https://steamcommunity.com/sharedfiles/filedetails/?id=3424494226) | 45 | 是 |

## 问题、处置与测试

下面“已修复”指 Wildwise 自身发现的缺陷，不意味着修复了参考模组。`WW2-*` 是新增纯 Lua 用例，`WWE-*` 是当前真实引擎用例；旧编号复用首轮回归。所有 `MAN-*` 均有[操作步骤](manual-regressions.md)，**仍待图形客户端／真实联机执行**。`WWE-01` 的检查范围是指定原生实体的创建、只读信息和移除，并非完整 Boss 战。

| ID／场景 | 来源与判断 | Wildwise 处置 | 验证 |
|---|---|---|---|
| R01 组件接口变动或信息字段类型错误导致 hover 崩溃 | [Insight (Show Me+) 2026-05-31](https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162#comment_660485761139808420)；[Insight (Show Me+) 2026-09-12](https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162#comment_520883440134067707)。有效机制风险。 | 公共读取器和查看者读取器分别隔离异常；按字段类型过滤。 | `WW-O01`、`WW-O03`、`WW2-08`、`WW2-20` |
| R02 提示、牛条遮挡库存或在 HUD 重建后残留 | [Beefalo Widget 2023-11-04](https://steamcommunity.com/sharedfiles/filedetails/?id=1852257480#comment_3941272762728799964)；[Item Info 2026-09-08](https://steamcommunity.com/sharedfiles/filedetails/?id=836583293#comment_592940620292783468)。具体 UI 反馈，外观待复现。 | 复用原生 hoverer 并释放自有文本；保留位置和缩放。 | `WW-U01`、`MAN-UI01` |
| R03 地图／信息组合泄露远处兴趣点并铺满屏幕边缘 | [Global Positions 2024-12-19](https://steamcommunity.com/sharedfiles/filedetails/?id=378160973#comment_597387460190730285)。有效权限风险。 | 观察不授予探索；只回放明确获准的玩家探索点。 | `WW-X01`、`MAN-M01` |
| R04 虚空面具怪失效后洞穴崩溃或掉线 | [Simple Health Bar DST 2025-08-16](https://steamcommunity.com/sharedfiles/filedetails/?id=1207269058#comment_615423511478078253)；[Simple Health Bar DST 2025-11-28](https://steamcommunity.com/sharedfiles/filedetails/?id=1207269058#comment_687490526751139116)。可能；玩家后来报告原版已修复，不能统一归因。 | 实体移除立即清理订阅，健康读取隔离；保留真正洞穴场景。 | `WW-H01`、`WW-O03`、`MAN-L01` |
| R05 地震／遗迹掉落物尚未落地即被处理 | [Auto Stack and Pick Up 2025-02-21](https://steamcommunity.com/sharedfiles/filedetails/?id=1803285852#comment_600770973001658480)；[Auto Stack and Pick Up 2026-05-08](https://steamcommunity.com/sharedfiles/filedetails/?id=1803285852#comment_832746196752847377)。有效落地风险，原投诉未完整复现。 | 同时检查来源、落地、高度、速度和保护标签。 | `WW-I02`、`MAN-I01` |
| R06 合堆方向把岸上物品带入水中 | [Auto Stack and Pick Up 2025-08-16](https://steamcommunity.com/sharedfiles/filedetails/?id=1803285852#comment_605290412319609837)；[Auto Stack and Pick Up 2025-08-25](https://steamcommunity.com/sharedfiles/filedetails/?id=1803285852#comment_592906450273072172)。作者解释了合并方向风险。 | 合入更旧的合法堆；船岸分离，保持原版数量与属性。 | `WW-I02`、`MAN-I01` |
| R07 读档、主动丢弃与新掉落来源混淆 | [Auto Stack and Pick Up 2025-03-28](https://steamcommunity.com/sharedfiles/filedetails/?id=1803285852#comment_592892850991097537)。Wildwise 源码发现，评论只是来源／库存风险线索。 | 只在 POPULATING 内标记恢复物，拾取许可不等于合堆许可；运行期解包不是读档。 | `WW-I01`、`WW-I03`、`WW-I04`、`WW-I05`、`MAN-SAVE01` |
| R08 旧世界地热洞穴与虫洞初始化崩溃 | [Wormhole Marks [DST] 2026-04-02](https://steamcommunity.com/sharedfiles/filedetails/?id=362175979#comment_809099128024976646)。可能；保留分片与旧存档触发。 | 确认双向原生传送器，按世界保存；损坏存档原样保留。 | `WW-M01`、`WW-M04`、`MAN-M02` |
| R09 专服虫洞地图图标变成粉蓝缺失贴图 | [Wormhole Marks [DST] 2026-06-13](https://steamcommunity.com/sharedfiles/filedetails/?id=362175979#comment_571540589652416873)。具体渲染反馈。 | 使用原版符号和编号；无画面测试不能确认颜色与材质。 | `MAN-UI01`、`MAN-M02` |
| R10 重启、回档、切换地图模组后丢失探索 | [Global Positions (CompleteSync) 2024-02-22](https://steamcommunity.com/sharedfiles/filedetails/?id=3138571948#comment_4348858679324065759)；[Global Positions (CompleteSync) 2025-07-20](https://steamcommunity.com/sharedfiles/filedetails/?id=3138571948#comment_594029097881995681)。有效持久化风险。 | 深拷贝保存，完整验证后加载；网络快照完成后才切换。 | `WW-M01`、`WW-M02`、`WW-M03`、`MAN-SAVE01` |
| R11 玩家进入／洞穴旅行触发整图同步卡顿 | [Global Positions (CompleteSync) 2025-04-16](https://steamcommunity.com/sharedfiles/filedetails/?id=3138571948#comment_506200271931605709)；[Global Positions (CompleteSync) 2024-05-20](https://steamcommunity.com/sharedfiles/filedetails/?id=3138571948#comment_6297799348956875093)。多条具体反馈，时长仅为报告值。 | 探索点去重、分批回放与字节／节点预算；不同步原版地图二进制。 | `WW-M03`、`MAN-P01` |
| R12 地图覆盖层干扰 WX 绘图或运输无人机 | [Global Positions (CompleteSync) 2026-04-17](https://steamcommunity.com/sharedfiles/filedetails/?id=3138571948#comment_801219096906786738)；[Global Positions (CompleteSync) 2026-04-18](https://steamcommunity.com/sharedfiles/filedetails/?id=3138571948#comment_801219423226562724)。作者回应修复；保留原生交互风险。 | 不包装无人机地图控制，不把无人机当玩家会话。 | `MAN-M03` |
| R13 Shift 放置吞掉原版网格或放置行为 | [ActionQueue RB3 2026-05-30](https://steamcommunity.com/sharedfiles/filedetails/?id=2873533916#comment_654855914502986973)。布点／输入反馈，具体间距仍需图形验证。 | 普通 placer 透传，批量部署使用原生间距与 CanDeploy。 | `WW-Q02`、`MAN-Q01` |
| R14 队列开启后不能手动攻击，或晾肉架反复开关 | [ActionQueue RB3 2026-09-13](https://steamcommunity.com/sharedfiles/filedetails/?id=2873533916#comment_617711086156659570)；[ActionQueue RB3 2026-09-11](https://steamcommunity.com/sharedfiles/filedetails/?id=2873533916#comment_617710833111269581)。具体原版操作报告。 | 手动攻击透传并取消队列；不循环 RUMMAGE，新肉架仍手动取物。 | `WW-Q02`、`WW-O05`、`MAN-Q01` |
| R15 取消、目标移除或船销毁后旧任务继续操作 | [ActionQueue RB3 2026-03-30](https://steamcommunity.com/sharedfiles/filedetails/?id=2873533916#comment_807973052001319796)。有效引用失效风险。 | 取消清回调与预览；已毁平台不退回旧世界坐标。 | `WW-Q01`、`WW-Q03`、`MAN-Q02` |
| R16 包裹木牌无图、箱体遮挡及重复更新 | [Smart Minisign 2024-05-27](https://steamcommunity.com/sharedfiles/filedetails/?id=1595631294#comment_4328601129273578452)。图像与生命周期风险。 | 不生成包裹内容物；首件图像变化合并更新，辅助牌不保存且不可交互。 | `WW-S01`、`WW-S02`、`WW-S03`、`WW-S04`、`WW-S05`、`MAN-S01` |
| R17 骑乘喂食或技能改变后倒计时不重置 | [Beefalo Widget 2025-03-20](https://steamcommunity.com/sharedfiles/filedetails/?id=1852257480#comment_501694185121844877)；[Beefalo Widget 2025-06-01](https://steamcommunity.com/sharedfiles/filedetails/?id=1852257480#comment_596276418836464588)；[Beefalo Widget 2023-12-20](https://steamcommunity.com/sharedfiles/filedetails/?id=1852257480#comment_4036978698784670600)。具体原生计时变化。 | 读取原版当前踢落任务，不另写旧技能／喂食公式。 | `WWE-01`、`MAN-B01` |
| R18 空坐骑、Woby 或旧存档开启牛条时不显示／崩溃 | [Beefalo Status Bar 2025-08-27](https://steamcommunity.com/sharedfiles/filedetails/?id=2477889104#comment_598536186508620419)；[Beefalo Status Bar 2025-10-12](https://steamcommunity.com/sharedfiles/filedetails/?id=2477889104#comment_592910856401980926)。可能，显示开关与接口分别处理。 | 缺失组件不伪造牛字段；新客户端会话重新订阅。 | `WW-B01`、`MAN-B01`、`MAN-L01` |
| R19 牛状态与 Show Me 信息组合影响温度／冻伤 | [Beefalo Widget 2024-03-22](https://steamcommunity.com/sharedfiles/filedetails/?id=1852257480#comment_4293692116967274318)。内部组合必须保留，原因未确认。 | 牛和信息共用只读事实，不改温度、受伤或食用方法。 | `WW-O04`、`WW-X02`、`MAN-B02` |
| R20 菜单快捷键、重置或个人／服务器设置混淆 | [Simple Health Bar DST 2025-12-26](https://steamcommunity.com/sharedfiles/filedetails/?id=1207269058#comment_695374430750197699)；[Simple Health Bar DST 2025-04-25](https://steamcommunity.com/sharedfiles/filedetails/?id=1207269058#comment_599650845622055032)。具体输入／配置反馈。 | 类型清洗、服主许可与个人偏好分离，所有菜单页构造验证。 | `WW-C01`、`MAN-UI01` |
| R21 草、树枝、浆果已采摘后没有再生时间 | [Insight (Show Me+) 2026-07-27](https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162#comment_588433186648910125)。已复现 Wildwise 遗漏。 | 接入 pickable 本地与外部定时器；暂停、可采摘和枯萎状态不显示运行倒计时。 | `WW2-01`、`WW2-02`、`WW2-03`、`WWE-02` |
| R22 无限燃料或无限时间使时间格式化崩溃 | [Insight (Show Me+) Bug Reporting Feb 11, 2024](https://steamcommunity.com/workshop/filedetails/discussion/2189004162/2793873675751084957/?ctp=56)。明确数值边界；不要求兼容外部无限燃料模组。 | 非有限数值不进入 UI；格式化函数也防御 Infinity／NaN。 | `WW2-08` |
| R23 Woby 晾肉架的成熟物信息导致崩溃／缺失 | [Show Me (Origin) 2025-03-02](https://steamcommunity.com/sharedfiles/filedetails/?id=666155465#comment_592890533790092917)；[Finder Redux 2025-03-01](https://steamcommunity.com/sharedfiles/filedetails/?id=2281925291#comment_604149434011407589)。多个信息／定位模组重复报告；Wildwise 漏读计时。 | 使用当前 wobyrack 继承的 dryingrack 快照，不访问不存在的 stewer。 | `WW2-27`、`WWE-10`、`MAN-WOBY01` |
| R24 鼠标经过鱼人劣质工具时崩溃 | [Item Info 2026-05-31](https://steamcommunity.com/sharedfiles/filedetails/?id=836583293#comment_662737213850933064)；[Item Info 2026-08-24](https://steamcommunity.com/sharedfiles/filedetails/?id=836583293#comment_591813437999452166)；[Item Info Updated 2025-12-30](https://steamcommunity.com/sharedfiles/filedetails/?id=3118627881#comment_686367559407223181)。原版实体的重复报告及更新者说明。 | 只读取数值武器伤害，工具用途不假定等同武器；两种真实工具检查。 | `WWE-01` |
| R25 薇格弗德盾牌在库存提示或制作时崩溃 | [Item Info 2024-09-30](https://steamcommunity.com/sharedfiles/filedetails/?id=836583293#comment_4847652375940306046)。具体原版盾牌报告。 | 真实 wathgrithr_shield 和 shieldofterror 检查；未知动态伤害不猜测。 | `WWE-01`、`MAN-CRAFT01` |
| R26 虚空回旋镖 hover／冷却读取崩溃 | [Item Info Updated 2024-09-14](https://steamcommunity.com/sharedfiles/filedetails/?id=3118627881#comment_6610810166138716645)；[Insight (Show Me+) 2025-01-14](https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162#comment_603019333728277977)。多个版本重复报告。 | 真实 voidcloth_boomerang 读取与移除，不执行武器回调。 | `WWE-01` |
| R27 兔王装备拾取或库存 hover 崩溃 | [Insight (Show Me+) 2025-09-27](https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162#comment_594035123771768868)。具体实体报告，原因未确认。 | 真实 rabbitkingspear／rabbitkinghorn 组件检查。 | `WWE-01`、`MAN-BOSS01` |
| R28 天体后裔血量读取假定存在 minhealth | [Show Me (Origin) 2025-06-14](https://steamcommunity.com/sharedfiles/filedetails/?id=666155465#comment_603033083890910163)。提供了具体 nil 字段日志。 | 使用当前 health 的 currenthealth/GetMaxWithPenalty；真实天体后裔检查。 | `WWE-01`、`MAN-BOSS01` |
| R29 月亮变异巨兽与致命亮茄没有血量 | [Health Info 2024-10-09](https://steamcommunity.com/sharedfiles/filedetails/?id=375859599#comment_4851030962512962042)；[Health Info 2024-10-11](https://steamcommunity.com/sharedfiles/filedetails/?id=375859599#comment_6966596977781348861)。具体漏显示反馈。 | 按健康组件观察，不用旧 prefab 白名单；三种变异巨兽和亮茄检查。 | `WWE-01`、`MAN-BOSS01` |
| R30 阿比盖尔快速回血药使健康包装方法报错 | [Simple Health Bar DST 2025-09-25](https://steamcommunity.com/sharedfiles/filedetails/?id=1207269058#comment_594035123771515120)。具体 DoDelta 日志。 | 不包装 DoDelta；原生回血前后保持函数、生命值变化和订阅释放。 | `WWE-07`、`MAN-BOSS01` |
| R31 伏特羊角冻后的电击攻击使服务器断开 | [Simple Health Bar DST 2024-02-01](https://steamcommunity.com/sharedfiles/filedetails/?id=1207269058#comment_4210371088510449762)。具体战斗反馈，当前未复现。 | 观察不改伤害／电击方法，保留实际吃药战斗验收。 | `WW-X02`、`MAN-BOSS01` |
| R32 黄金工具的剩余次数被显示成普通工具次数 | [Insight (Show Me+) Bug Reporting Sep 17, 2024](https://steamcommunity.com/workshop/filedetails/discussion/2189004162/2793873675751084957/?ctp=58)。具体次数报告；未采信附带外部客户端模组的根因。 | 读取实体自己的有限次数和上限，真实 goldenaxe 验证。 | `WWE-01` |
| R33 位面武器伤害与位面防御没有显示 | [Item Info 2024-05-26](https://steamcommunity.com/sharedfiles/filedetails/?id=836583293#comment_4338734234985548220)；[Item Info Updated 2025-03-30](https://steamcommunity.com/sharedfiles/filedetails/?id=3118627881#comment_597396690608062603)。已复现 Wildwise 字段遗漏。 | 独立展示 planardamage/GetDamage 与 planardefense/GetDefense；基础伤害不冒充最终实伤。 | `WW2-19`、`WWE-01` |
| R34 WX 插电路增加最大生命后显示 575/125 | [Health indicators 2026-04-04](https://steamcommunity.com/sharedfiles/filedetails/?id=3424494226#comment_804595528394653097)；[Health indicators 2026-04-18](https://steamcommunity.com/sharedfiles/filedetails/?id=3424494226#comment_797841730484310168)。作者确认修复的数值刷新问题。 | 即使没有受伤事件也周期刷新最大生命；条宽钳制到画布内。 | `WW2-28`、`MAN-HEALTH01` |
| R35 加州卷错误排除两个海带，正确输入无菜谱 | [Craft Pot [DS, ROG, SW, DST] 2024-12-31](https://steamcommunity.com/sharedfiles/filedetails/?id=727774324#comment_591759121392374230)；[Craft Pot [DS, ROG, SW, DST] 2026-04-06](https://steamcommunity.com/sharedfiles/filedetails/?id=727774324#comment_803469937487294105)。具体配方错误。 | 直接运行当前原版四格 test，真实加州卷验证；同时修复熟肉三种 prefab 别名。 | `WW2-09`、`WWE-03` |
| R36 沃利骨头汤配方错误包含树枝 | [Craft Pot [DS, ROG, SW, DST] 2024-12-31](https://steamcommunity.com/sharedfiles/filedetails/?id=727774324#comment_591759121392375891)。具体配方错误。 | 可切换普通锅／便携锅，沃利默认便携锅；分别用原版配方，与带树枝／正确材料的原版结果对照。 | `WW2-31`、`WWE-03`、`MAN-RECIPE01` |
| R37 火鸡正餐最小材料推导错误 | [Craft Pot [DS, ROG, SW, DST] 2024-04-03](https://steamcommunity.com/sharedfiles/filedetails/?id=727774324#comment_4361247379736595077)。同类开发者说明。 | 不推导最小菜谱；四个明确输入直接判定，保留真实双鸡腿对照。 | `WWE-03` |
| R38 料理列表排序或载入时与 nil 比较 | [Craft Pot [DS, ROG, SW, DST] 2025-02-16](https://steamcommunity.com/sharedfiles/filedetails/?id=727774324#comment_632295800477591236)；[Craft Pot [DS, ROG, SW, DST] 2026-09-09](https://steamcommunity.com/sharedfiles/filedetails/?id=727774324#comment_572674734038235749)。明确日志与载入触发。 | 输入必须四个连续格；校验标签和配方，失败不误报低优先级菜；换食材／锅时清结果并丢弃过期响应。 | `WW2-10`、`WW2-11`、`WW2-12`、`WW2-13`、`WW2-14`、`WW2-30`、`MAN-RECIPE01` |
| R39 沃尔夫冈最爱食物未计算额外饥饿收益 | [Item Info Updated 2025-04-03](https://steamcommunity.com/sharedfiles/filedetails/?id=3118627881#comment_597397069919974489)；[Item Info Updated 2024-03-04](https://steamcommunity.com/sharedfiles/filedetails/?id=3118627881#comment_4300446114899949517)。重复食用数值报告。 | 把实际查看者传给原版 edible，真实最爱土豆预测与食用差值对照。 | `WW2-23`、`WWE-04` |
| R40 保鲜背包内食物时间仍被当成准确腐败倒计时 | [Item Info Updated 2024-09-23](https://steamcommunity.com/sharedfiles/filedetails/?id=3118627881#comment_4844274022645082330)。数值语义问题。 | 标为基础腐败余量；不执行可能有副作用的 preserver 回调，不承诺环境条件下 ETA。 | `WW2-24`、`MAN-FOOD01` |
| R41 礼物／包裹信息读取 nil 导致崩溃 | [Insight (Show Me+) Bug Reporting Oct 8, 2025](https://steamcommunity.com/workshop/filedetails/discussion/2189004162/2793873675751084957/?ctp=65)。具体 unwrappable 日志。 | 只读保存摘要，异常独立于角色食用／世界信息；不临时 SpawnPrefab。 | `WW2-18`、`WW2-20`、`WWE-05` |
| R42 节日礼物中的物品无法被定位 | [Insight (Show Me+) 2025-09-20](https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162#comment_594034489924339791)。Wildwise 原先只匹配直接内容，能力缺口已补。 | 容器定位读取有界一层包裹快照，保留权限与总访问预算。 | `WW2-17`、`WWE-05`、`MAN-FIND01` |
| R43 暗影切斯特／魔术箱的共享内容无法定位 | [Show Me (Origin) 2024-02-11](https://steamcommunity.com/sharedfiles/filedetails/?id=666155465#comment_4199112956967750002)。原版口袋存储形态风险。 | 经当前 container_proxy 公开主存储接口查询，失效主存储不读取。 | `WW2-21`、`MAN-FIND01` |
| R44 拆分箱中堆叠或离开箱子后高亮永久残留 | [Where's My Stuff, Dude? (Finder For Gamepad) 2025-05-11](https://steamcommunity.com/sharedfiles/filedetails/?id=837819197#comment_594022757599048463)；[Where's My Stuff, Dude? (Finder For Gamepad) 2025-04-29](https://steamcommunity.com/sharedfiles/filedetails/?id=837819197#comment_594021624312805630)；[Finder Redux 2023-12-03](https://steamcommunity.com/sharedfiles/filedetails/?id=2281925291#comment_4034725235914491668)。多个定位模组重复反馈。 | 使用有时限的自有屏幕标记，不改实体 highlight 组件；保留拆堆与离屏实机用例。 | `MAN-FIND01`、`MAN-L01` |
| R45 切换背包／护甲后提示堆在左下角 | [Item Info 2026-09-08](https://steamcommunity.com/sharedfiles/filedetails/?id=836583293#comment_592940620292783468)；[Item Info Updated 2025-03-09](https://steamcommunity.com/sharedfiles/filedetails/?id=3118627881#comment_595142971903488063)；[Item Info Updated 2024-08-22](https://steamcommunity.com/sharedfiles/filedetails/?id=3118627881#comment_4425436358662253430)。重复且有稳定步骤。 | 提示归属当前 hoverer；食材选择忽略失效背包物并包含鼠标物品。 | `WW-U01`、`WW2-15`、`MAN-UI02` |
| R46 长时间游戏后断线重进导致客户端崩溃 | [Item Info 2026-07-02](https://steamcommunity.com/sharedfiles/filedetails/?id=836583293#comment_571542424813465513)。内存泄漏是玩家推测，保留长时场景。 | 有界 LRU、按玩家销毁观察和 UI，不接收已关闭实例更新。 | `WW2-29`、`MAN-L01`、`MAN-P01` |
| R47 客户端 RPC 到达时 ThePlayer 为空 | [Epic Healthbar 2025-07-06](https://steamcommunity.com/sharedfiles/filedetails/?id=1185229307#comment_595153695607452384)。明确 RPC 日志。 | 先有当前客户端会话才接收；旧会话和已销毁实例不更新。 | `WW2-29`、`MAN-L01` |
| R48 过多信息序列化造成卡死／丢失提示 | [Insight (Show Me+) 2025-01-03](https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162#comment_603018408517202212)。已发现 Wildwise 预算和发送确认缺陷。 | 文本按 UTF-8 边界裁剪并限制总量；失败快照／增量不推进已发送缓存。 | `WW2-04`、`WW2-05`、`WW2-06`、`WW2-07`、`WWE-08`、`WWE-09` |
| R49 血条代理网络字段越界，日志持续刷屏 | [Epic Healthbar 2025-10-09](https://steamcommunity.com/sharedfiles/filedetails/?id=1185229307#comment_596288191849387433)；[Epic Healthbar 2026-03-04](https://steamcommunity.com/sharedfiles/filedetails/?id=1185229307#comment_760682600544364512)。具体类型／范围日志。 | 消息先过 schema 类型过滤，客户端再次验证；不使用参考模组的窄位宽代理。 | `WW2-08`、`WW2-29` |
| R50 智能小木牌与 Insight 同时开启卡在加载阶段 | [Smart Minisign 2026-07-22](https://steamcommunity.com/sharedfiles/filedetails/?id=1595631294#comment_586181093023038696)。内部木牌＋信息组合，根因尚未确认。 | 避免全局 RegisterPrefabs 接管；真实全模块启动与原版 drawable 检查。 | `WW-S01`、`WWE-05`、`MAN-SIGN01` |
| R51 Craft Pot 与 ActionQueue 一起新建世界崩溃 | [Craft Pot [DS, ROG, SW, DST] 2026-06-16](https://steamcommunity.com/sharedfiles/filedetails/?id=727774324#comment_568163224011351737)；[Insight (Show Me+) 2025-04-05](https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162#comment_599648970674849509)。内部料理＋队列组合必须保留。 | 服务器读取配方、客户端 UI 只负责选择；菜单焦点不触发批量制作。 | `WW2-16`、`WWE-03`、`MAN-RECIPE01` |
| R52 骑牛耕地与列队行为学组合使人物消失并卡住 | [Beefalo Info HUD 2025-07-12](https://steamcommunity.com/sharedfiles/filedetails/?id=3439927311#comment_546740620659555265)。明确内部牛＋队列组合。 | 缺少原生骑乘动作时暂停，不循环换工具强制动作；不改骑乘 StateGraph。 | `WW2-26`、`MAN-RIDEQUEUE01` |
| R53 镀金骑士掉落马蹄铁时自动整理崩溃 | [Auto Stack and Pick Up 2026-08-16](https://steamcommunity.com/sharedfiles/filedetails/?id=1803285852#comment_589561020200073617)。具体掉落实体报告。 | 用真实 horseshoe 检查信息与整理资格，不对不适合堆叠实体改组件。 | `WWE-01`、`WWE-06`、`MAN-I02` |
| R54 满背包制作／转移后出现幽灵格或重复物品 | [Auto Stack and Pick Up 2025-03-28](https://steamcommunity.com/sharedfiles/filedetails/?id=1803285852#comment_592892850991097537)。可能，作者未确认归因；保留内部库存＋制作风险。 | 使用原版容量与部分接收，余量留地；排队预留防止重复消费。 | `WW-I02`、`MAN-I02`、`MAN-CRAFT01` |
| R55 Shift 点击种子把它丢在农田上而未种植 | [ActionQueue Reborn 2026-03-05](https://steamcommunity.com/sharedfiles/filedetails/?id=1608191708#comment_806844795448297990)。具体输入报告。 | 每项执行前重新用原版动作选择器判断；不把 DROP 映射成种植。 | `WW-Q02`、`MAN-Q03` |
| R56 穿虫洞后采草却跑回旧虫洞并忽略操作 | [ActionQueue Reborn 2025-02-02](https://steamcommunity.com/sharedfiles/filedetails/?id=1608191708#comment_592887920829998734)。Wildwise 缺少同世界旅行取消通知，已补。 | 监听原版 wormholetravel；跨分片监听世界事件；清队列、预览与旧按下状态。 | `WWE-09`、`MAN-Q03` |
| R57 打开制作栏就连续制作上次物品 | [ActionQueue Reborn 2025-02-12](https://steamcommunity.com/sharedfiles/filedetails/?id=1608191708#comment_598518433314774927)；[ActionQueue Reborn 2025-01-05](https://steamcommunity.com/sharedfiles/filedetails/?id=1608191708#comment_592885445492229155)。已复现 Wildwise 焦点判断遗漏。 | 只有输入就绪且主动按 Shift 才建立制作队列；菜单／文本焦点走原生路径。 | `WW2-16`、`MAN-CRAFT01` |
| R58 沃拓克斯框选后角色锁定方向持续行走 | [ActionQueue Reborn 2025-03-21](https://steamcommunity.com/sharedfiles/filedetails/?id=1608191708#comment_595144081821163053)。具体客户端控制反馈。 | 手动接管清队列；失焦、服务器取消会使旧鼠标按下失效。 | `WW-Q02`、`WW-Q03`、`MAN-Q03` |
| R59 船上制作最后一个箱子时崩溃 | [ActionQueue Reborn 2025-06-13](https://steamcommunity.com/sharedfiles/filedetails/?id=1608191708#comment_563626538148320470)。具体制作／平台反馈，未确认根因。 | 带 placer 的配方走原版；平台销毁不能使用旧坐标。 | `WW-Q01`、`WW-Q02`、`MAN-CRAFT01` |
| R60 新桥梁套件部署时队列崩溃 | [ActionQueue Reborn 2024-12-24](https://steamcommunity.com/sharedfiles/filedetails/?id=1608191708#comment_595136186401467725)。具体新版部署触发。 | 保留原生 DEPLOY/CanDeploy 与特殊 placer；测试实际船岸点位。 | `WW-Q01`、`MAN-Q03` |
| R61 手柄操作料理锅后按键失灵或声音消失 | [Craft Pot [DS, ROG, SW, DST] 2025-08-30](https://steamcommunity.com/sharedfiles/filedetails/?id=727774324#comment_591780787069868223)；[Craft Pot [DS, ROG, SW, DST] 2024-07-15](https://steamcommunity.com/sharedfiles/filedetails/?id=727774324#comment_6918175214330229463)；[Craft Pot [DS, ROG, SW, DST] 2024-01-02](https://steamcommunity.com/sharedfiles/filedetails/?id=727774324#comment_4038104984931637641)。重复且有明确操作顺序。 | 队列不抢菜单焦点；纯键鼠／无画面构造不能替代手柄回归。 | `WW2-16`、`MAN-PAD01` |
| R62 把菜单按钮隐藏并删除热键后无法重置 | [Simple Health Bar DST 2025-04-25](https://steamcommunity.com/sharedfiles/filedetails/?id=1207269058#comment_599650845622055032)；[Simple Health Bar DST 2025-05-08](https://steamcommunity.com/sharedfiles/filedetails/?id=1207269058#comment_599652058746853631)。具体无法恢复设置的报告。 | Wildwise 菜单入口固定保留，F7 可改绑；配置恢复清洗非法键值。 | `WW-C01`、`MAN-UI01` |
| R63 旧存档已绑定牛铃，启用模块后不显示牛信息 | [Beefalo Info HUD 2026-08-25](https://steamcommunity.com/sharedfiles/filedetails/?id=3439927311#comment_589561710754570806)；[Beefalo Info HUD 2026-02-16](https://steamcommunity.com/sharedfiles/filedetails/?id=3439927311#comment_814724377262468547)。绑定时机／显示状态反馈。 | 显示读取当前原生坐骑，不要求重新绑定牛铃；按 B 控制当前面板。 | `WW-B01`、`MAN-B01` |
| R64 窗口缩放后牛 HUD 移到屏幕外 | [Beefalo Info HUD 2026-03-12](https://steamcommunity.com/sharedfiles/filedetails/?id=3439927311#comment_797838226728518552)。作者说明坐标处理问题。 | 按当前屏幕尺寸重新布局，保留偏移／缩放；图形尺寸验收待执行。 | `MAN-UI02` |
| R65 牛 HUD 回档崩溃、打包恢复后血量错或复制牛 | [Beefalo Info HUD 2025-09-22](https://steamcommunity.com/sharedfiles/filedetails/?id=3439927311#comment_597412591711661593)；[Beefalo Info HUD 2025-11-18](https://steamcommunity.com/sharedfiles/filedetails/?id=3439927311#comment_658216290030333744)。具体持久化反馈；该同类还修改牛属性。 | Wildwise 不保存牛副本、不改牛血量或驯化；只保存自有地图设置。 | `WW-X02`、`MAN-SAVE02` |
| R66 骑牛开箱后下牛，右键只剩打不开的存放选项 | [Beefalo Info HUD 2026-03-20](https://steamcommunity.com/sharedfiles/filedetails/?id=3439927311#comment_797838866430241935)；[Beefalo Info HUD 2026-06-19](https://steamcommunity.com/sharedfiles/filedetails/?id=3439927311#comment_565911724530803560)。同类扩展容器导致动作优先级问题。 | Wildwise 不给牛加箱子或改变剃毛／骑乘动作；保留原生交互检查。 | `WW2-26`、`MAN-RIDEQUEUE01` |
| R67 智能木牌持续打印测试日志 | [Smart Minisign 2026-06-17](https://steamcommunity.com/sharedfiles/filedetails/?id=1595631294#comment_565911724530655651)。具体日志污染反馈。 | 运行期诊断默认关闭；读取器同类异常只打印第一次，计数有固定类别。 | `WW2-22`、`MAN-SIGN01` |
| R68 箱子里小丑牌没有木牌图像 | [Smart Minisign 2026-08-01](https://steamcommunity.com/sharedfiles/filedetails/?id=1595631294#comment_587307906418923736)。特定原版新物图标反馈。 | 读取原生 inventoryitem 图像与皮肤；图集渲染仍需真实客户端核对。 | `MAN-SIGN01` |
| R69 WX 备用躯体或切斯特的地图揭示扫描遇到伪玩家崩溃 | [Global Positions (CompleteSync) 2026-05-01](https://steamcommunity.com/sharedfiles/filedetails/?id=3138571948#comment_845130655609151157)；[Global Positions (CompleteSync) 2026-05-01](https://steamcommunity.com/sharedfiles/filedetails/?id=3138571948#comment_845130655609129438)。作者未确认伪实体归属，原版标签／组件契约风险有效。 | 不创建带 maprevealer 标签的伪玩家，地图分享只操作真实玩家。 | `MAN-M03`、`MAN-M04` |
| R70 角色变幽灵或 Wonkey 时地图模组持有旧引用 | [Global Positions (CompleteSync) 2024-11-02](https://steamcommunity.com/sharedfiles/filedetails/?id=3138571948#comment_4637112066660969883)。明确玩家生命周期日志。 | 玩家离开时释放观察与地图会话；迁移取消仅作用对应玩家。 | `WW2-29`、`MAN-L01`、`MAN-M04` |
| R71 32:9 屏幕的定位箭头方向偏移 | [Global Positions Bug Reports May 16, 2025](https://steamcommunity.com/workshop/filedetails/discussion/378160973/613948093871206440/?ctp=13)。明确超宽屏反馈。 | 沿用原版屏幕／地图投影，保留超宽屏和缩放实测，不凭构造测试判定正确。 | `MAN-M04` |
| R72 Alt 查看曼德拉草却使附近角色睡眠 | [Insight (Show Me+) Bug Reporting Mar 30, 2025](https://steamcommunity.com/workshop/filedetails/discussion/2189004162/2793873675751084957/?ctp=61)。查询触发游戏行为的具体报告。 | 读取器不调用食用／激活动作，包裹也不生成临时实体；原版睡眠事件作对照。 | `WW-O04`、`WWE-05`、`MAN-FOOD01` |
| R73 WX 喝舒缓茶、沃姆伍德用堆肥时崩溃 | [Insight (Show Me+) Bug Reporting Jun 26–27, 2024](https://steamcommunity.com/workshop/filedetails/discussion/2189004162/2793873675751084957/?ctp=57)。含信息＋血条＋地图＋牛等内部组合，作者称修复 buff 错误。 | 信息层不包装 buff／食用／自我施肥事件；真实角色操作另留人工对照。 | `WW-O04`、`WW-X02`、`MAN-FOOD01` |
| R74 最新狩猎终点的提示贴图缺失导致崩溃 | [Insight (Show Me+) Bug Reporting Jan 24, 2025](https://steamcommunity.com/workshop/filedetails/discussion/2189004162/2793873675751084957/?ctp=61)。作者确认修复的版本适配问题。 | Wildwise 暂无追踪足迹提示；不替换该图集或狩猎过程，记录为范围外能力。 | `MAN-BOSS01` |

## 未采纳为 Wildwise 缺陷的内容

- “不好用／崩了／不能下载”但没有触发、有效日志或可区分条件的评论，不推断根因。模组出现在崩溃报告尾部不证明它导致崩溃。
- 作者或用户撤回的归因、窗口外报告、纯支持／订阅请求、明确只涉及外部改角色／改装备槽／特殊生态的冲突不计为本轮有效缺陷。保留合理边界测试不等于确认外部归因。
- Auto Stack Pro 的主要复制物报告在窗口外；Smart Minisign Revisited 的可见评论均在窗口前。仍记录为“采集到零条”，不伪造近期问题。
- Woby 自动批量晾肉、骑牛强制耕地／牛箱、自动攻击、狩猎提示、精确腐败 ETA 不是当前承诺能力。相应原版操作保留，并明确记录扩展边界。

## 自动化与复现

```bash
python3 tools/workshop_collect.py --ids 2189004162 2873533916 --start 2023-09-14 --end 2026-09-14 --output /tmp/wildwise-comments
npm test
npm run test:research
```

采集可重跑，但后来新增、删除和审核状态变化会改变数量。当前版本与测试结果见[测试报告](testing.md)。
