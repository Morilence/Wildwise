# 参考模组与 Wildwise：配置逐项对照

审查日期：2026-09-14。这里比较的是**同一类配置是否可由用户实际调整**。✅ 可以有取值范围差异，差异全部写在旁边；❌ 也可能代表功能固定存在但无法单独调整，不能倒推功能不存在。功能支持请看 [完整功能矩阵](/usr/local/src/Wildwise/exa-results/mod-capability-comparison-2026-09-14/report.md)。

共核对参考模组 **194 项**公开配置（Insight 110 个普通项+4个运行时多选项），Wildwise **38 项**原生配置。标题/分隔行不计入。默认关闭仍算支持；不把内部 Lua 常量当公开配置。CSV 保留所有键位枚举，Markdown 对连续数字和长键位表做范围缩写。

Insight 的 `undefined` 是“服主未强制指定”，并非 false；此时采用个人选择，个人也未另选才退回 original_default。`client=true` 优先用个人选择；其余 `independent` 项由远程客户端/主机各用本端值，普通项默认服主优先。依据 scripts/clientmodmain.lua 的 GenerateConfiguration。CSV保留原始client/tags及枚举说明。原作者的中文标签可能有翻译错误，例如 `display_mob_attack_damage` 的中文标签写成攻击范围，功能判断仍依代码键和读取器。

## Insight

来源：[modinfo.lua](/tmp/wildwise-research/insight/modinfo.lua)。版本 6.0.6。

| 配置键 | 原项含义 | 参考 | 默认值 | 可选值 | 生效范围 | Wildwise | 对应边界/评估 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [language](/tmp/wildwise-research/insight/modinfo.lua:6769) | 语言 | ✅ | automatic | automatic（自动） / en（英语） / zh（中文） / br（Portuguese） / es（Spanish） / ru（Russian） / ko（韩国语） | 个人优先 | ✅ | language：auto/zh/en；不支持参考的葡/西/俄/韩。 按用户群体按需增加语言 |
| [info_style](/tmp/wildwise-research/insight/modinfo.lua:6784) | 信息类型 | ✅ | text | text（文字） / icon（图标） | 个人优先 | ❌ | 固定原生文本/单位/行数；检查键展开、3 档预设不能替代该独立配置。 信息开关、时间单位、截断提示优先；字体样式按需 |
| [text_coloring](/tmp/wildwise-research/insight/modinfo.lua:6794) | 文字着色 | ✅ | true | false（禁用） / true（启用） | 个人优先 | ❌ | 固定原生文本/单位/行数；检查键展开、3 档预设不能替代该独立配置。 信息开关、时间单位、截断提示优先；字体样式按需 |
| [insight_font](/tmp/wildwise-research/insight/modinfo.lua:6804) | 字体 | ✅ | UIFONT | UIFONT / TITLEFONT / DIALOGFONT / NUMBERFONT / BODYTEXTFONT / TALKINGFONT | 个人优先 | ❌ | 固定原生文本/单位/行数；检查键展开、3 档预设不能替代该独立配置。 信息开关、时间单位、截断提示优先；字体样式按需 |
| [hoverer_insight_font_size](/tmp/wildwise-research/insight/modinfo.lua:6811) | 鼠标悬停文本大小 | ✅ | 30 | 20 / 21 / 22 / 23 / 24 / 25 / 26 / 27 / 28 / 29 / 30 | 个人优先 | ✅ | info_font_size / 个人 info.font_size：18/22/26/30，粒度不同。 保留；需要时扩展字号 |
| [inventorybar_insight_font_size](/tmp/wildwise-research/insight/modinfo.lua:6818) | 控制器物品栏文本大小 | ✅ | 25 | 20 / 21 / 22 / 23 / 24 / 25 | 个人优先 | ❌ | 固定原生文本/单位/行数；检查键展开、3 档预设不能替代该独立配置。 信息开关、时间单位、截断提示优先；字体样式按需 |
| [followtext_insight_font_size](/tmp/wildwise-research/insight/modinfo.lua:6825) | 控制器跟随文本大小 | ✅ | 28 | 20 / 21 / 22 / 23 / 24 / 25 / 26 / 27 / 28 | 个人优先 | ❌ | 固定原生文本/单位/行数；检查键展开、3 档预设不能替代该独立配置。 信息开关、时间单位、截断提示优先；字体样式按需 |
| [hoverer_line_truncation](/tmp/wildwise-research/insight/modinfo.lua:6832) | 悬停文本截断 | ✅ | None | None / 1 / 2 / 3 / 4 / 5 | 个人优先 | ❌ | 固定原生文本/单位/行数；检查键展开、3 档预设不能替代该独立配置。 信息开关、时间单位、截断提示优先；字体样式按需 |
| [alt_only_information](/tmp/wildwise-research/insight/modinfo.lua:6839) | 仅在检查时显示 | ✅ | false | false（禁用） / true（启用） | 个人优先 | ❌ | 固定原生文本/单位/行数；检查键展开、3 档预设不能替代该独立配置。 信息开关、时间单位、截断提示优先；字体样式按需 |
| [itemtile_display](/tmp/wildwise-research/insight/modinfo.lua:6861) | 库存物品栏信息 | ✅ | percentages | none（无） / numbers（数字） / percentages（百分比） / mixed（兼用） | 个人优先 | ❌ | 固定原生文本/单位/行数；检查键展开、3 档预设不能替代该独立配置。 信息开关、时间单位、截断提示优先；字体样式按需 |
| [time_style](/tmp/wildwise-research/insight/modinfo.lua:6873) | 时间样式 | ✅ | realtime_short | gametime（游戏时间） / realtime（现实时间） / both（兼用两种模式） / gametime_short（游戏时间（精简）） / realtime_short（现实时间（精简）） / both_short（兼用两种模式（精简）） | 个人优先 | ❌ | 固定原生文本/单位/行数；检查键展开、3 档预设不能替代该独立配置。 信息开关、时间单位、截断提示优先；字体样式按需 |
| [temperature_units](/tmp/wildwise-research/insight/modinfo.lua:6888) | 温度单位 | ✅ | game | game（游戏温度） / celsius（摄氏度） / fahrenheit（华氏度） | 个人优先 | ❌ | 固定原生文本/单位/行数；检查键展开、3 档预设不能替代该独立配置。 信息开关、时间单位、截断提示优先；字体样式按需 |
| [highlighting](/tmp/wildwise-research/insight/modinfo.lua:6899) | 高亮显示 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 只提供手动同类定位和 8 秒文字标记，缺少自动/材质/燃料高亮配置。 补自动定位及易辨认反馈；黑暗穿透可忽略 |
| [experimental_highlighting](/tmp/wildwise-research/insight/modinfo.lua:6909) | 实验性高亮显示 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 只提供手动同类定位和 8 秒文字标记，缺少自动/材质/燃料高亮配置。 补自动定位及易辨认反馈；黑暗穿透可忽略 |
| [highlighting_darkness](/tmp/wildwise-research/insight/modinfo.lua:6919) | 高亮黑暗中的物品 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 只提供手动同类定位和 8 秒文字标记，缺少自动/材质/燃料高亮配置。 补自动定位及易辨认反馈；黑暗穿透可忽略 |
| [highlighting_color](/tmp/wildwise-research/insight/modinfo.lua:6929) | 高亮颜色 | ✅ | GREEN | RED（红色） / GREEN（绿色） / BLUE（蓝色） / LIGHT_BLUE（亮蓝色） / PURPLE（紫色） / YELLOW（黄色） / WHITE（白色） / ORANGE（橙色） / PINK（粉色） | 个人优先 | ❌ | 只提供手动同类定位和 8 秒文字标记，缺少自动/材质/燃料高亮配置。 补自动定位及易辨认反馈；黑暗穿透可忽略 |
| [fuel_highlighting](/tmp/wildwise-research/insight/modinfo.lua:6946) | 燃料高亮显示 | ✅ | false | false（否） / true（是） | 个人优先 | ❌ | 只提供手动同类定位和 8 秒文字标记，缺少自动/材质/燃料高亮配置。 补自动定位及易辨认反馈；黑暗穿透可忽略 |
| [fuel_highlighting_color](/tmp/wildwise-research/insight/modinfo.lua:6956) | 燃料高亮颜色 | ✅ | RED | RED（红色） / GREEN（绿色） / BLUE（蓝色） / LIGHT_BLUE（亮蓝色） / PURPLE（紫色） / YELLOW（黄色） / WHITE（白色） / ORANGE（橙色） / PINK（粉色） | 个人优先 | ❌ | 只提供手动同类定位和 8 秒文字标记，缺少自动/材质/燃料高亮配置。 补自动定位及易辨认反馈；黑暗穿透可忽略 |
| [display_attack_range](/tmp/wildwise-research/insight/modinfo.lua:6974) | 攻击范围 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ✅ | info_attack_range 服主许可；只允许数值提示，没有范围圈。 先补范围显示，再细分样式 |
| [attack_range_type](/tmp/wildwise-research/insight/modinfo.lua:6983) | 攻击范围类型 | ✅ | undefined；个人未另选时的回退值 hit | hit（敲击） / attack（攻击） / both（兼用） / undefined（默认） | 个人优先 | ❌ | 没有实体范围圈、命中/攻击区分、设施/角色范围的设置。 战斗与设施范围优先；角色专用按需 |
| [hover_range_indicator](/tmp/wildwise-research/insight/modinfo.lua:6994) | 物品范围 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 没有实体范围圈、命中/攻击区分、设施/角色范围的设置。 战斗与设施范围优先；角色专用按需 |
| [boss_indicator](/tmp/wildwise-research/insight/modinfo.lua:7004) | Boss 指示器 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [miniboss_indicator](/tmp/wildwise-research/insight/modinfo.lua:7014) | 小 Boss 指示器 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [notable_indicator](/tmp/wildwise-research/insight/modinfo.lua:7024) | 其他物品指示器 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [pipspook_indicator](/tmp/wildwise-research/insight/modinfo.lua:7034) | 小惊吓玩具指示器 | ✅ | true | false（否） / true（是） | 服主/共享配置 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [bottle_indicator](/tmp/wildwise-research/insight/modinfo.lua:7043) | 漂流瓶指示器 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [suspicious_marble_indicator](/tmp/wildwise-research/insight/modinfo.lua:7053) | 可疑的大理石指示器 | ✅ | false | false（否） / true（是） | 个人优先 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [death_indicator](/tmp/wildwise-research/insight/modinfo.lua:7063) | 死亡指示器 | ✅ | false | false（否） / true（是） | 服主/共享配置 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [hunt_indicator](/tmp/wildwise-research/insight/modinfo.lua:7072) | 动物脚印指示器 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [orchestrina_indicator](/tmp/wildwise-research/insight/modinfo.lua:7081) | 远古迷宫 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [tumbleweed_info](/tmp/wildwise-research/insight/modinfo.lua:7090) | 风滚草指示器 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [lightningrod_range](/tmp/wildwise-research/insight/modinfo.lua:7099) | 避雷针范围 | ✅ | 1 | 0（禁用） / 1（策略性地显示） / 2（总是） | 个人优先 | ❌ | 没有实体范围圈、命中/攻击区分、设施/角色范围的设置。 战斗与设施范围优先；角色专用按需 |
| [blink_range](/tmp/wildwise-research/insight/modinfo.lua:7110) | 瞬移范围 | ✅ | false | false（否） / true（是） | 个人优先 | ❌ | 没有实体范围圈、命中/攻击区分、设施/角色范围的设置。 战斗与设施范围优先；角色专用按需 |
| [wortox_soul_range](/tmp/wildwise-research/insight/modinfo.lua:7120) | 沃拓克斯灵魂范围 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 没有实体范围圈、命中/攻击区分、设施/角色范围的设置。 战斗与设施范围优先；角色专用按需 |
| [battlesong_range](/tmp/wildwise-research/insight/modinfo.lua:7130) | 战歌生效范围 | ✅ | both | none（无） / detach（脱离） / attach（生效） / both（兼用） | 个人优先 | ❌ | 没有实体范围圈、命中/攻击区分、设施/角色范围的设置。 战斗与设施范围优先；角色专用按需 |
| [klaus_sack_markers](/tmp/wildwise-research/insight/modinfo.lua:7142) | 克劳斯袋子标记 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [sinkhole_marks](/tmp/wildwise-research/insight/modinfo.lua:7151) | 洞穴标记 | ✅ | 2 | 0（无） / 1（仅地图模式） / 2（兼用） | 个人优先 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [display_food](/tmp/wildwise-research/insight/modinfo.lua:7163) | 食物信息 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [food_style](/tmp/wildwise-research/insight/modinfo.lua:7172) | 食物属性格式 | ✅ | long | short（精简） / long（详细） | 个人优先 | ❌ | 食物只有固定字段排序；食物记忆仅参与估算，缺少这些独立展示配置。 常用食物信息优先；样式按需 |
| [food_order](/tmp/wildwise-research/insight/modinfo.lua:7182) | 食物属性显示顺序 | ✅ | interface | interface（界面） / wiki（维基） | 个人优先 | ❌ | 食物只有固定字段排序；食物记忆仅参与估算，缺少这些独立展示配置。 常用食物信息优先；样式按需 |
| [food_units](/tmp/wildwise-research/insight/modinfo.lua:7192) | 食物系数 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 食物只有固定字段排序；食物记忆仅参与估算，缺少这些独立展示配置。 常用食物信息优先；样式按需 |
| [food_effects](/tmp/wildwise-research/insight/modinfo.lua:7202) | 食物加成属性 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 食物只有固定字段排序；食物记忆仅参与估算，缺少这些独立展示配置。 常用食物信息优先；样式按需 |
| [stewer_chef](/tmp/wildwise-research/insight/modinfo.lua:7212) | 烹饪厨师显示 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 食物只有固定字段排序；食物记忆仅参与估算，缺少这些独立展示配置。 常用食物信息优先；样式按需 |
| [food_memory](/tmp/wildwise-research/insight/modinfo.lua:7221) | 食物记忆 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 个人优先 | ❌ | 食物只有固定字段排序；食物记忆仅参与估算，缺少这些独立展示配置。 常用食物信息优先；样式按需 |
| [display_perishable](/tmp/wildwise-research/insight/modinfo.lua:7231) | 腐烂信息 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [display_cawnival](/tmp/wildwise-research/insight/modinfo.lua:7241) | 鸦年华信息 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 没有节庆专属描述器或开关。 可暂缓 |
| [display_yotb_winners](/tmp/wildwise-research/insight/modinfo.lua:7250) | 选美大赛冠军 ["皮弗娄牛之年" 更新] | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 没有节庆专属描述器或开关。 可暂缓 |
| [display_yotb_appraisal](/tmp/wildwise-research/insight/modinfo.lua:7259) | 评价值 ["皮弗娄牛之年" 更新] | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 没有节庆专属描述器或开关。 可暂缓 |
| [display_shared_stats](/tmp/wildwise-research/insight/modinfo.lua:7268) | 玩家列表中的数据 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_worldmigrator](/tmp/wildwise-research/insight/modinfo.lua:7277) | 传送信息 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_unwrappable](/tmp/wildwise-research/insight/modinfo.lua:7286) | 打包信息 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | info_container_contents 同时控制箱子、包裹和定位，没有独立包裹开关。 应补独立隐私开关 |
| [display_simplefishing](/tmp/wildwise-research/insight/modinfo.lua:7295) | 淡水垂钓信息 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_oceanfishing](/tmp/wildwise-research/insight/modinfo.lua:7304) | 海洋垂钓信息 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_tackle_information](/tmp/wildwise-research/insight/modinfo.lua:7313) | 渔具信息 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_spawner_information](/tmp/wildwise-research/insight/modinfo.lua:7322) | 生物生成计时器 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [weapon_damage](/tmp/wildwise-research/insight/modinfo.lua:7331) | 武器伤害值 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [armor](/tmp/wildwise-research/insight/modinfo.lua:7340) | 护甲 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [repair_values](/tmp/wildwise-research/insight/modinfo.lua:7349) | 修补数值 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [klaus_sack_info](/tmp/wildwise-research/insight/modinfo.lua:7358) | 赃物袋信息 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [soil_moisture](/tmp/wildwise-research/insight/modinfo.lua:7367) | 土壤潮湿度 | ✅ | 2 | 0（禁用） / 1（仅土壤） / 2（土壤/植株） / 3（土壤，植株，耕地） / 4（全部） | 个人优先 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [soil_nutrients](/tmp/wildwise-research/insight/modinfo.lua:7380) | 土壤养分值 | ✅ | undefined；个人未另选时的回退值 2 | 1（仅土壤） / 2（土壤/植株） / 3（土壤，植株，耕地） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [soil_nutrients_needs_hat](/tmp/wildwise-research/insight/modinfo.lua:7392) | 土壤养分值显示 | ✅ | undefined；个人未另选时的回退值 always | off（禁用） / hatonly（高级耕作先驱帽） / always（总是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [display_plant_stressors](/tmp/wildwise-research/insight/modinfo.lua:7402) | 植物压力 | ✅ | undefined；个人未另选时的回退值 2 | 0（否） / 1（佩戴高级耕作先驱帽） / 2（总是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [display_fertilizer](/tmp/wildwise-research/insight/modinfo.lua:7412) | 肥料 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [display_compostvalue](/tmp/wildwise-research/insight/modinfo.lua:7421) | 堆肥值 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_weighable](/tmp/wildwise-research/insight/modinfo.lua:7430) | 物品重量 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_gyminfo](/tmp/wildwise-research/insight/modinfo.lua:7439) | 健身房信息 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_world_events](/tmp/wildwise-research/insight/modinfo.lua:7448) | 世界事件 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ✅ | info_world_events；只读前 12 个 worldsettingstimer，不等于参考的语义事件集合。 优先完善内容及逐类开关 |
| [show_map_info](/tmp/wildwise-research/insight/modinfo.lua:7457) | 地图信息 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [danger_announcements](/tmp/wildwise-research/insight/modinfo.lua:7466) | 危险宣告 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_shadowthrall_information](/tmp/wildwise-research/insight/modinfo.lua:7475) | 墨荒信息 | ✅ | undefined；个人未另选时的回退值 1 | 0（无） / 1（世界级） / 2（全部） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_batwave_information](/tmp/wildwise-research/insight/modinfo.lua:7485) | 蝙蝠袭击信息 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_itemmimic_information](/tmp/wildwise-research/insight/modinfo.lua:7494) | 模拟物品信息 | ✅ | undefined；个人未另选时的回退值 0 | 0（无） / 1（世界级） / 2（全部） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_rabbitking_information](/tmp/wildwise-research/insight/modinfo.lua:7504) | 兔王信息 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_weather](/tmp/wildwise-research/insight/modinfo.lua:7513) | 天气信息 | ✅ | undefined；个人未另选时的回退值 2 | 0（否） / 1（存在雨量计） / 2（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [weather_detail](/tmp/wildwise-research/insight/modinfo.lua:7523) | 天气明细 | ✅ | undefined；个人未另选时的回退值 0 | 0（标准） / 1（高级） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [nightmareclock_display](/tmp/wildwise-research/insight/modinfo.lua:7532) | 洞穴暴动阶段 | ✅ | undefined；个人未另选时的回退值 2 | 0（禁用） / 1（拥有铥矿勋章） / 2（启用） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [wx78_scanner_info](/tmp/wildwise-research/insight/modinfo.lua:7542) | WX-78 扫描信息 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_health](/tmp/wildwise-research/insight/modinfo.lua:7551) | 生命值 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [display_hunger](/tmp/wildwise-research/insight/modinfo.lua:7560) | 饥饿值 | ✅ | undefined；个人未另选时的回退值 1 | 0（否） / 1（标准） / 2（完整） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_sanity](/tmp/wildwise-research/insight/modinfo.lua:7570) | 理智 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_sanityaura](/tmp/wildwise-research/insight/modinfo.lua:7579) | 理智光环 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_sanity_interactions](/tmp/wildwise-research/insight/modinfo.lua:7588) | 影响理智交互显示 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_mob_attack_damage](/tmp/wildwise-research/insight/modinfo.lua:7597) | 怪物攻击范围 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [growth_verbosity](/tmp/wildwise-research/insight/modinfo.lua:7606) | 植物生长阶段 | ✅ | undefined；个人未另选时的回退值 1 | 0（无） / 1（简短） / 2（详细） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [display_pickable](/tmp/wildwise-research/insight/modinfo.lua:7616) | 可采集信息 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [display_harvestable](/tmp/wildwise-research/insight/modinfo.lua:7625) | 可收获信息 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [display_finiteuses](/tmp/wildwise-research/insight/modinfo.lua:7634) | 工具耐久度 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [display_timers](/tmp/wildwise-research/insight/modinfo.lua:7644) | 计时器 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_rechargeable](/tmp/wildwise-research/insight/modinfo.lua:7653) | 充能信息显示 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_upgradeable](/tmp/wildwise-research/insight/modinfo.lua:7662) | 可升级物品显示 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [naughtiness_verbosity](/tmp/wildwise-research/insight/modinfo.lua:7671) | 淘气值 | ✅ | undefined；个人未另选时的回退值 2 | 0（禁用） / 1（生物的淘气值） / 2（玩家/生物的淘气值） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [follower_info](/tmp/wildwise-research/insight/modinfo.lua:7681) | 随从信息 | ✅ | undefined；个人未另选时的回退值 true | false（禁用） / true（启用） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [herd_information](/tmp/wildwise-research/insight/modinfo.lua:7690) | 兽群信息 | ✅ | undefined；个人未另选时的回退值 false | false（禁用） / true（启用） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [domestication_information](/tmp/wildwise-research/insight/modinfo.lua:7699) | 牛驯服度 | ✅ | undefined；个人未另选时的回退值 true | false（禁用） / true（启用） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [display_pollination](/tmp/wildwise-research/insight/modinfo.lua:7708) | 授粉信息 | ✅ | undefined；个人未另选时的回退值 true | false（禁用） / true（启用） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [item_worth](/tmp/wildwise-research/insight/modinfo.lua:7717) | 物品价值 | ✅ | undefined；个人未另选时的回退值 true | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [appeasement_value](/tmp/wildwise-research/insight/modinfo.lua:7726) | 蚁狮 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [fuel_verbosity](/tmp/wildwise-research/insight/modinfo.lua:7735) | 燃料 | ✅ | undefined；个人未另选时的回退值 2 | 0（无） / 1（标准） / 2（全面） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 有部分对应信息，但仅按大类或密度预设控制；没有此字段的独立开关/详细度/资格条件。 应补常用项独立设置 |
| [display_shelter_info](/tmp/wildwise-research/insight/modinfo.lua:7745) | 遮蔽处信息 | ✅ | undefined；个人未另选时的回退值 false | false（否） / true（是） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |
| [display_crafting_lookup_button](/tmp/wildwise-research/insight/modinfo.lua:7766) | 建造查看按钮 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | HUD 菜单按钮固定显示；无制造查询按钮及其显示开关。 菜单按钮可隐藏应补；制造查询按需 |
| [display_insight_menu_button](/tmp/wildwise-research/insight/modinfo.lua:7776) | Insight 目录按钮 | ✅ | true | false（否） / true（是） | 个人优先 | ❌ | HUD 菜单按钮固定显示；无制造查询按钮及其显示开关。 菜单按钮可隐藏应补；制造查询按需 |
| [extended_info_indicator](/tmp/wildwise-research/insight/modinfo.lua:7786) | 更多信息提示 | ✅ | false | false（否） / true（是） | 个人优先 | ❌ | 固定原生文本/单位/行数；检查键展开、3 档预设不能替代该独立配置。 信息开关、时间单位、截断提示优先；字体样式按需 |
| [info_preload](/tmp/wildwise-research/insight/modinfo.lua:7819) | 信息预载 | ✅ | undefined；个人未另选时的回退值 2 | 0（否） / 1（容器） / 2（所有） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 缓存/刷新由固定内部预算控制，无用户可配入口。 先做多人性能验收，暂不开放底层预算 |
| [refresh_delay](/tmp/wildwise-research/insight/modinfo.lua:7829) | 信息刷新延时 | ✅ | undefined；个人未另选时的回退值 true | true（自动设定） / 0（实时） / 0.25（0.25秒） / 0.5（0.5秒） / 1（1秒） / 3（3秒） / undefined（默认） | 服主指定；undefined 时由个人选择 | ❌ | 缓存/刷新由固定内部预算控制，无用户可配入口。 先做多人性能验收，暂不开放底层预算 |
| [crash_reporter](/tmp/wildwise-research/insight/modinfo.lua:7844) | 崩溃报告器 | ✅ | false | false（否） / true（是） | 远程客户端/主机各用本端配置 | ❌ | diagnostics 仅本地日志；无自动上传。 可忽略自动上传 |
| [DEBUG_SHOW_NOTIMPLEMENTED](/tmp/wildwise-research/insight/modinfo.lua:7853) | 执行调试显示信息 | ✅ | false | false（否） / true（是） | 个人优先 | ❌ | 只有 diagnostics 和诊断页，不等价于各调试覆盖层。 按排错需要，非玩家必需 |
| [DEBUG_SHOW_DISABLED](/tmp/wildwise-research/insight/modinfo.lua:7863) | 禁用调试显示 | ✅ | false | false（否） / true（是） | 个人优先 | ❌ | 只有 diagnostics 和诊断页，不等价于各调试覆盖层。 按排错需要，非玩家必需 |
| [DEBUG_SHOW_PREFAB](/tmp/wildwise-research/insight/modinfo.lua:7873) | 预设调试显示 | ✅ | false | false（否） / true（是） | 个人优先 | ❌ | 只有 diagnostics 和诊断页，不等价于各调试覆盖层。 按排错需要，非玩家必需 |
| [DEBUG_ENABLED](/tmp/wildwise-research/insight/modinfo.lua:7883) | 开启调试功能 | ✅ | false | false（否） / true（是） | 远程客户端/主机各用本端配置 | ❌ | 只有 diagnostics 和诊断页，不等价于各调试覆盖层。 按排错需要，非玩家必需 |
| [boss_indicator_prefabs](/tmp/wildwise-research/insight/modinfo.lua:7898) | boss_indicator_prefabs | ✅ | ["minotaur", "bearger", "deerclops", "dragonfly", "antlion", "beequeen", "crabking", "klaus", "malbatross", "moose", "stalker_atrium", "toadstool", "eyeofterror", "twinofterror1", "twinofterror2", "daywalker"] | minotaur / bearger / deerclops / dragonfly / antlion / beequeen / crabking / klaus / malbatross / moose / stalker_atrium / toadstool / eyeofterror / twinofterror1 / twinofterror2 / daywalker / ancient_herald / ancient_hulk / pugalisk / twister / twister_seal / tigershark / kraken / antqueen（候选全集；实际只显示运行时已注册prefab，unique也接受已有名称） | 个人优先 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [miniboss_indicator_prefabs](/tmp/wildwise-research/insight/modinfo.lua:7921) | miniboss_indicator_prefabs | ✅ | ["leif", "warg", "spat", "spiderqueen", "claywarg", "gingerbreadwarg", "lordfruitfly", "stalker"] | leif / warg / spat / spiderqueen / claywarg / gingerbreadwarg / lordfruitfly / stalker / ancient_robot_ribs / ancient_robot_claw / ancient_robot_leg / ancient_robot_head / treeguard（候选全集；实际只显示运行时已注册prefab，unique也接受已有名称） | 个人优先 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [notable_indicator_prefabs](/tmp/wildwise-research/insight/modinfo.lua:7944) | notable_indicator_prefabs | ✅ | ["chester_eyebone", "hutch_fishbowl", "atrium_key", "klaus_sack", "gingerbreadpig", "wanderingtrader"] | chester_eyebone / hutch_fishbowl / atrium_key / klaus_sack / gingerbreadpig / wanderingtrader（候选全集；实际只显示运行时已注册prefab，unique也接受已有名称） | 个人优先 | ❌ | 只支持队友/临时点/已穿越虫洞/信号火，不支持这些实体追踪及多选列表。 死亡点、已发现入口优先；隐藏目标透视可忽略 |
| [unique_info_prefabs](/tmp/wildwise-research/insight/modinfo.lua:7968) | unique_info_prefabs | ✅ | ["alterguardianhat", "batbat", "eyeplant", "ancient_statue", "armordreadstone", "voidcloth_scythe", "lunarthrall_plant", "shadow_battleaxe"] | alterguardianhat / batbat / eyeplant / ancient_statue / armordreadstone / voidcloth_scythe / lunarthrall_plant / shadow_battleaxe（候选全集；实际只显示运行时已注册prefab，unique也接受已有名称） | 服主/共享配置 | ❌ | 未提供此项独立配置；具体信息是否部分覆盖见功能矩阵，不能由 schema 名称推定。 依功能矩阵优先级分批评估 |

## Global Positions

来源：[modinfo.lua](/tmp/wildwise-research/global-positions/modinfo.lua)。版本 1.7.6。

| 配置键 | 原项含义 | 参考 | 默认值 | 可选值 | 生效范围 | Wildwise | 对应边界/评估 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [SHOWPLAYERSOPTIONS](/tmp/wildwise-research/global-positions/modinfo.lua:44) | Player Indicators | ✅ | 2 | 3（Always） / 2（Scoreboard） / 1（Never） | 服主 | ✅ | 个人 map.indicators：always/scoreboard/off；off 仅关闭屏边提示，不隐藏地图名字。 保留并明确语义差别 |
| [SHOWPLAYERICONS](/tmp/wildwise-research/global-positions/modinfo.lua:55) | Player Icons | ✅ | true | true（Show） / false（Hide） | 服主 | ❌ | 位置共享开关控制是否向他人分享；没有只隐藏接收方地图玩家图标的开关。 应补 |
| [FIREOPTIONS](/tmp/wildwise-research/global-positions/modinfo.lua:65) | Show Fires | ✅ | 2 | 1（Always） / 2（Charcoal） / 3（Disabled） | 服主 | ❌ | 信号火固定木炭触发；火图标与标记都跟随 map_enabled，无独立许可。 应补独立服主许可和个人显示开关 |
| [SHOWFIREICONS](/tmp/wildwise-research/global-positions/modinfo.lua:77) | Fire Icons | ✅ | true | true（Show） / false（Hide） | 服主 | ❌ | 信号火固定木炭触发；火图标与标记都跟随 map_enabled，无独立许可。 应补独立服主许可和个人显示开关 |
| [SHAREMINIMAPPROGRESS](/tmp/wildwise-research/global-positions/modinfo.lua:88) | Share Map | ✅ | true | true（Enabled） / false（Disabled） | 服主 | ✅ | map_share_exploration auto/on/off + 个人分享开关；只回放获准来源点。 保留 |
| [OVERRIDEMODE](/tmp/wildwise-research/global-positions/modinfo.lua:99) | Wilderness Override | ✅ | false | true（Enabled） / false（Disabled） | 服主 | ❌ | 可通过 on 覆盖位置/探索默认规则，但没有荒野全部火堆暴露的预设。 可忽略原版荒野火堆玩法 |
| [ENABLEPINGS](/tmp/wildwise-research/global-positions/modinfo.lua:110) | Pings | ✅ | true | true（Enabled） / false（Disabled） | 服主 | ❌ | 信号火固定木炭触发；火图标与标记都跟随 map_enabled，无独立许可。 应补独立服主许可和个人显示开关 |

## Wormhole Marks

来源：[modinfo.lua](/tmp/wildwise-research/wormhole/modinfo.lua)。版本 1.4.5。

| 配置键 | 原项含义 | 参考 | 默认值 | 可选值 | 生效范围 | Wildwise | 对应边界/评估 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [Draw over FoW](/tmp/wildwise-research/wormhole/modinfo.lua:13) | Draw over FoW | ✅ | disabled | disabled（Disabled） / enabled（Enabled） | 服主 | ❌ | 固定逐端迷雾限制，无穿透迷雾配置。 可忽略，保留探索边界 |

## Auto Stack and Pick Up

来源：[modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua)。版本 0.3.1。

| 配置键 | 原项含义 | 参考 | 默认值 | 可选值 | 生效范围 | Wildwise | 对应边界/评估 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [SmokePuffOnStacking](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:40) | Puff On Stack | ✅ | true | true（Yes） / false（No） | 服主 | ❌ | 无烟雾特效及其开关。 可忽略 |
| [AutoStackEnabled](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:61) | World Drop Auto Stack | ✅ | true | true（On） / false（Off） | 服主 | ✅ | 对应 items_stack_world/items_stack_manual/items_pickup_allowed/items_pickup_existing；拾取额外要求个人 opt-in。 保留更谨慎默认值 |
| [StackDuringPopulation](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:71) | World Gen Auto Stack | ✅ | false | true（Yes） / false（No） | 服主 | ❌ | items_stack_loaded 仅读档恢复合堆，不等价于世界生成+读档统一开关。 保留生成保护；仅需明确文档 |
| [AutoStackRange](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:82) | World Auto Stack Range | ✅ | 10 | 1～25，步长 1（25 档） | 服主 | ❌ | 三种操作共用 items_radius，2/4/6/8；不能分别设置 1～25。 应补独立半径 |
| [AutoStackMakeNewStackMainStack](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:115) | World Auto Stack In | ✅ | true | true（Newest） / false（Existing） | 服主 | ❌ | 固定向较早的合法堆合并，没有 Newest/Existing 选择。 默认保持 Existing；Newest 可忽略 |
| [AutoStackTwiggyTreeTwigs](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:125) | Auto Stack Twiggy Tree Twigs | ✅ | false | true（Yes） / false（No） | 服主 | ❌ | 没有树枝树附近落枝的独立保护条件或配置。 应先补生产机制边界 |
| [AutoStackAsh](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:135) | Auto Stack Ash | ✅ | false | true（Yes） / false（No） | 服主 | ❌ | 没有按灰烬/粪便/种子及来源划分的过滤选项。 应补可配置过滤 |
| [AutoStackPoop](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:145) | Auto Stack Poop | ✅ | false | true（Yes） / false（No） | 服主 | ❌ | 没有按灰烬/粪便/种子及来源划分的过滤选项。 应补可配置过滤 |
| [AutoStackSeeds](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:155) | Auto Stack Seeds | ✅ | false | true（Yes） / false（No） | 服主 | ❌ | 没有按灰烬/粪便/种子及来源划分的过滤选项。 应补可配置过滤 |
| [AutoStackManuallyDroppedItems](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:174) | Manual Drop Auto Stack | ✅ | false | true（On） / false（Off） | 服主 | ✅ | 对应 items_stack_world/items_stack_manual/items_pickup_allowed/items_pickup_existing；拾取额外要求个人 opt-in。 保留更谨慎默认值 |
| [ManualDropStackRange](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:184) | Manual Auto Stack Range | ✅ | 5 | 1～25，步长 1（25 档） | 服主 | ❌ | 三种操作共用 items_radius，2/4/6/8；不能分别设置 1～25。 应补独立半径 |
| [ManualStackMakeNewStackMainStack](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:217) | Manual Auto Stack In | ✅ | false | true（Newest） / false（Existing） | 服主 | ❌ | 固定向较早的合法堆合并，没有 Newest/Existing 选择。 默认保持 Existing；Newest 可忽略 |
| [ManualStackAsh](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:227) | Manual Auto Stack Ash | ✅ | false | true（Yes） / false（No） | 服主 | ❌ | 没有按灰烬/粪便/种子及来源划分的过滤选项。 应补可配置过滤 |
| [ManualStackPoop](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:237) | Manual Auto Stack Poop | ✅ | false | true（Yes） / false（No） | 服主 | ❌ | 没有按灰烬/粪便/种子及来源划分的过滤选项。 应补可配置过滤 |
| [ManualStackSeeds](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:247) | Manual Auto Stack Seeds | ✅ | false | true（Yes） / false（No） | 服主 | ❌ | 没有按灰烬/粪便/种子及来源划分的过滤选项。 应补可配置过滤 |
| [AutoPickupEnabled](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:266) | Auto Pickup Items | ✅ | false | true（On） / false（Off） | 服主 | ✅ | 对应 items_stack_world/items_stack_manual/items_pickup_allowed/items_pickup_existing；拾取额外要求个人 opt-in。 保留更谨慎默认值 |
| [AutoPickupRange](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:276) | Auto Pickup Range | ✅ | 10 | 1～25，步长 1（25 档） | 服主 | ❌ | 三种操作共用 items_radius，2/4/6/8；不能分别设置 1～25。 应补独立半径 |
| [PlayerMustHaveOneOfItemToAutoPickup](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:309) | Require Existing Stack? | ✅ | false | true（Yes） / false（No） | 服主 | ✅ | 对应 items_stack_world/items_stack_manual/items_pickup_allowed/items_pickup_existing；拾取额外要求个人 opt-in。 保留更谨慎默认值 |
| [AutoPickupAsh](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:319) | Auto Pickup Ash | ✅ | false | true（Yes） / false（No） | 服主 | ❌ | 没有按灰烬/粪便/种子及来源划分的过滤选项。 应补可配置过滤 |
| [AutoPickupPoop](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:329) | Auto Pickup Poop | ✅ | false | true（Yes） / false（No） | 服主 | ❌ | 没有按灰烬/粪便/种子及来源划分的过滤选项。 应补可配置过滤 |
| [AutoPickupSeeds](/home/ubuntu/Steam/steamapps/workshop/content/322330/1803285852/modinfo.lua:339) | Auto Pickup Seeds | ✅ | false | true（Yes） / false（No） | 服主 | ❌ | 没有按灰烬/粪便/种子及来源划分的过滤选项。 应补可配置过滤 |

## ActionQueue RB3

来源：[modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua)。版本 4.3。

| 配置键 | 原项含义 | 参考 | 默认值 | 可选值 | 生效范围 | Wildwise | 对应边界/评估 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [Languages](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:100) | 語言 | ✅ | english | english（英文） / korean（韩语） / chinese（中文） | 客户端 | ✅ | language 自动/中/英；参考支持英/韩/中，取值及韩语覆盖不同。 韩语按需 |
| [action_queue_key](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:101) | 列队行为键 | ✅ | KEY_LSHIFT | 70 个键位选项，包含禁用；完整枚举见 CSV | 客户端 | ✅ | 个人 queue.modifier_key，默认左 Shift，F7 中重绑定。 保留 |
| [always_clear_queue](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:102) | 始终清除队列 | ✅ | true | true（Yes） / false（No） | 客户端 | ❌ | 手動接管固定取消，失焦固定暂停；不能切成保留选择策略。 可保持既有接管规则 |
| [selection_color](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:103) | 列队行为颜色 | ✅ | WHITE | WHITE（白色） / FIREBRICK（红色） / TAN（橙色） / LIGHTGOLD（黄色） / GREEN（绿色） / TEAL（青色） / OTHERBLUE（蓝色） / DARKPLUM（紫色） / ROSYBROWN（粉色） / GOLDENROD（金色） | 客户端 | ❌ | 选择框/预览使用固定样式。 颜色和透明度按可读性需要补 |
| [selection_opacity](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:104) | 列队行为透明度 | ✅ | 0.5 | 0.05（5%） / 0.1（10%） / 0.15（15%） / 0.2（20%） / 0.25（25%） / 0.3（30%） / 0.35（35%） / 0.4（40%） / 0.45（45%） / 0.5（50%） / 0.55（55%） / 0.6（60%） / 0.65（65%） / 0.7（70%） / 0.75（75%） / 0.8（80%） / 0.85（85%） / 0.9（90%） / 0.95（95%） | 客户端 | ❌ | 选择框/预览使用固定样式。 颜色和透明度按可读性需要补 |
| [double_click_speed](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:105) | 双击速度 | ✅ | 0.3 | 0 / 0.05 / 0.1 / 0.15 / 0.2 / 0.25 / 0.3 / 0.35 / 0.4 / 0.45 / 0.5 | 客户端 | ❌ | 固定 0.35 秒、15 距离，未公开配置。 应补交互参数 |
| [double_click_range](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:106) | 双击选择范围 | ✅ | 25 | 10 / 15 / 20 / 25 / 30 / 35 / 40 / 45 / 50 / 55 / 60 | 客户端 | ❌ | 固定 0.35 秒、15 距离，未公开配置。 应补交互参数 |
| [turf_grid_key](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:107) | 显示地皮网格键 | ✅ | KEY_F3 | 70 个键位选项，包含禁用；完整枚举见 CSV | 客户端 | ❌ | 仅有有限区域布点和固定蛇形，无独立网格层、陷阱间距、强制网格或双蛇形配置。 网格/间距按需；双蛇形可暂缓 |
| [turf_grid_radius](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:108) | 地皮网格半径 | ✅ | 5 | 1～50，步长 1（50 档） | 客户端 | ❌ | 仅有有限区域布点和固定蛇形，无独立网格层、陷阱间距、强制网格或双蛇形配置。 网格/间距按需；双蛇形可暂缓 |
| [turf_grid_color](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:109) | 地皮网格颜色 | ✅ | WHITE | WHITE（白色） / FIREBRICK（红色） / TAN（橙色） / LIGHTGOLD（黄色） / GREEN（绿色） / TEAL（青色） / OTHERBLUE（蓝色） / DARKPLUM（紫色） / ROSYBROWN（粉色） / GOLDENROD（金色） | 客户端 | ❌ | 选择框/预览使用固定样式。 颜色和透明度按可读性需要补 |
| [deploy_on_grid](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:110) | 只在网格上部署 | ✅ | false | true（Yes） / false（No） | 客户端 | ❌ | 仅有有限区域布点和固定蛇形，无独立网格层、陷阱间距、强制网格或双蛇形配置。 网格/间距按需；双蛇形可暂缓 |
| [auto_collect_key](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:111) | 自动拾取键 | ✅ | KEY_F4 | 70 个键位选项，包含禁用；完整枚举见 CSV | 客户端 | ❌ | 世界新掉落自动入包与工作后主动走过去收集是不同流程。 应补任务范围内工作后收集 |
| [auto_collect](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:112) | 默认启用自动拾取 | ✅ | false | true（Yes） / false（No） | 客户端 | ❌ | 世界新掉落自动入包与工作后主动走过去收集是不同流程。 应补任务范围内工作后收集 |
| [endless_deploy_key](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:113) | 无尽部署切换键 | ✅ | KEY_F5 | 70 个键位选项，包含禁用；完整枚举见 CSV | 客户端 | ❌ | 只允许选定区域内最多 200 项，不提供无尽部署。 可忽略无尽模式 |
| [endless_deploy](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:114) | 默认无尽部署 | ✅ | false | true（Yes） / false（No） | 客户端 | ❌ | 只允许选定区域内最多 200 项，不提供无尽部署。 可忽略无尽模式 |
| [last_recipe_key](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:115) | 制作上一个物品 | ✅ | KEY_C | 70 个键位选项，包含禁用；完整枚举见 CSV | 客户端 | ❌ | 支持 Shift 点配方重复制作，没有上次配方快捷键。 应补常用快捷操作 |
| [tooth_trap_spacing](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:116) | 狗牙陷阱间距 | ✅ | 2 | 1 / 1.5 / 2 / 2.5 / 3 / 3.5 / 4 | 客户端 | ❌ | 仅有有限区域布点和固定蛇形，无独立网格层、陷阱间距、强制网格或双蛇形配置。 网格/间距按需；双蛇形可暂缓 |
| [farm_grid](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:117) | 耕地网格 | ✅ | 3x3 | 2x2 / 3x3 / 4x4 | 客户端 | ✅ | queue_farm_grid / 个人 queue.farm_grid：2/3/4。 保留 |
| [double_snake](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:118) | Z形种植 | ✅ | false | true（Yes） / false（No） | 客户端 | ❌ | 仅有有限区域布点和固定蛇形，无独立网格层、陷阱间距、强制网格或双蛇形配置。 网格/间距按需；双蛇形可暂缓 |
| [qaaq](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:119) | 排队论加强兼容 | ✅ | false | true（Yes） / false（No） | 客户端 | ❌ | 按 ID 关闭重叠队列，无 QAAQ 联合运行模式。 暂缓到具体兼容需求 |
| [debug_mode](/home/ubuntu/Steam/steamapps/workshop/content/322330/2873533916/modinfo.lua:120) | 启用调试 | ✅ | false | true（Yes） / false（No） | 客户端 | ❌ | diagnostics 仅信息读取诊断，未实现 RB3 队列详细调试。 开发需要时补 |

## 智能小木牌

来源：[modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modinfo.lua)。版本 1.1.8。

| 配置键 | 原项含义 | 参考 | 默认值 | 可选值 | 生效范围 | Wildwise | 对应边界/评估 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [Icebox](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modinfo.lua:30) | Icebox/冰箱 | ✅ | false | false（No(关闭)） / true（Yes(打开)） | 服主 | ✅ | 对应独立容器开关；龙鳞箱 Wildwise 默认 true，参考 false。 保留 |
| [ChangeSkin](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modinfo.lua:41) | ChangeSkin/皮肤 | ✅ | true | true（Yes(是)） / false（No(否)） | 服主 | ❌ | 参考控制小木牌本体换肤，不是内容物皮肤图标；Wildwise 没有本体换肤入口。 按需 |
| [DragonflyChest](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modinfo.lua:52) | DragonflyChest/龙鳞箱 | ✅ | false | false（No(关闭)） / true（Yes(打开)） | 服主 | ✅ | 对应独立容器开关；龙鳞箱 Wildwise 默认 true，参考 false。 保留 |
| [SaltBox](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modinfo.lua:63) | SaltBox/盐盒 | ✅ | false | false（No(关闭)） / true（Yes(打开)） | 服主 | ✅ | 对应独立容器开关；龙鳞箱 Wildwise 默认 true，参考 false。 保留 |
| [BundleItems](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modinfo.lua:74) | BundleItems/包裹 | ✅ | false | false（No(关闭)） / true（Yes(打开)） | 服主 | ❌ | 包裹首件显示固定开启；不能改为包裹图标。 应补，支持包裹隐私/视觉选择 |
| [Digornot](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modinfo.lua:85) | CanbeDug/挖起 | ✅ | false | false（No(关闭)） / true（Yes(打开)） | 服主 | ❌ | 辅助牌固定不可点击/挖除，无逐箱永久移除。 可改为个人/逐箱隐藏，挖掘玩法可忽略 |
| [OnlyPlayer](/home/ubuntu/Steam/steamapps/workshop/content/322330/1595631294/modinfo.lua:95) | OnlyPlayer/仅玩家 | ✅ | false | false（Yes(仅限玩家)） / true（No(所有破坏)） | 服主 | ❌ | 辅助牌固定不可点击/挖除，无逐箱永久移除。 可改为个人/逐箱隐藏，挖掘玩法可忽略 |

## Beefalo Status Bar

来源：[modinfo.lua](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua)。版本 1.4.0。

| 配置键 | 原项含义 | 参考 | 默认值 | 可选值 | 生效范围 | Wildwise | 对应边界/评估 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [ShowByDefault](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:113) | Show Automatically | ✅ | true | true（Enabled） / false（Disabled） | 服主；显示项可能允许客户端覆盖 | ✅ | 个人 beefalo.visible，可保存；B 临时切换本身不立即调用 save_settings。 保留并明确临时/持久语义 |
| [ToggleKey](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:123) | Toggle Key | ✅ | KEY_T | 103 个键位选项，包含禁用；完整枚举见 CSV | 服主；显示项可能允许客户端覆盖 | ✅ | 个人 beefalo.toggle_key 默认 B；参考默认 T，可选禁用。 保留；禁用热键入口可补 |
| [EnableSounds](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:130) | Sounds | ✅ | false | false（Disabled） / true（Enabled） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [ClientConfig](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:140) | Prefer Client Configuration | ✅ | false | false（Disabled） / true（Enabled） | 服主；显示项可能允许客户端覆盖 | ❌ | Wildwise 固定服主授权+个人偏好模型，无两份配置来源切换选项。 可忽略该旧模型切换 |
| [Theme](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:157) | Theme | ✅ | TheForge | TheForge（The Forge） / Default（Default Theme） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [Scale](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:167) | Scale | ✅ | 1 | 0.5～2，步长 0.05（31 档） | 服主；显示项可能允许客户端覆盖 | ❌ | 只有全 HUD ui_scale，无牛栏独立缩放。 应补 |
| [HungerThreshold](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:174) | Hunger Badge Threshold | ✅ | 15 | false（禁用）或 5～375，步长 5 | 服主；显示项可能允许客户端覆盖 | ✅ | 服务器/个人阈值 0/5/15/25；无参考 false 或 30～375 等范围。 应补独立关闭饥饿字段 |
| [HEALTH_BADGE_CLEAR_BG](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:181) | Health Badge Background | ✅ | false | false（Distinct） / true（Standard） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [BADGE_BG_BRIGHTNESS](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:191) | Background Brightness | ✅ | 60 | 0（0%） / 5（5%） / 10（10%） / 15（15%） / 20（20%） / 25（25%） / 30（30%） / 35（35%） / 40（40%） / 45（45%） / 50（50%） / 55（55%） / 60（60%） / 65（65%） / 70（70%） / 75（75%） / 80（80%） / 85（85%） / 90（90%） / 95（95%） / 100（100%） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [BADGE_BG_OPACITY](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:198) | Background Opacity | ✅ | 100 | 0（0%） / 5（5%） / 10（10%） / 15（15%） / 20（20%） / 25（25%） / 30（30%） / 35（35%） / 40（40%） / 45（45%） / 50（50%） / 55（55%） / 60（60%） / 65（65%） / 70（70%） / 75（75%） / 80（80%） / 85（85%） / 90（90%） / 95（95%） / 100（100%） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [GapModifier](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:205) | Gap Modifier | ✅ | 0 | -15～30，步长 1（46 档） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [COLOR_DOMESTICATION_ORNERY](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:218) | Domestication (Ornery) | ✅ | ORANGE | ORANGE（Orange） / ORANGE_ALT（Orange Alt） / BLUE（Blue） / BLUE_ALT（Blue Alt） / PURPLE（Purple） / PURPLE_ALT（Purple Alt） / RED（Red） / RED_ALT（Red Alt） / GREEN（Green） / GREEN_ALT（Green Alt） / BEIGE（Beige） / WHITE（White） / YELLOW（Yellow） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [COLOR_DOMESTICATION_RIDER](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:225) | Domestication (Rider) | ✅ | BLUE | ORANGE（Orange） / ORANGE_ALT（Orange Alt） / BLUE（Blue） / BLUE_ALT（Blue Alt） / PURPLE（Purple） / PURPLE_ALT（Purple Alt） / RED（Red） / RED_ALT（Red Alt） / GREEN（Green） / GREEN_ALT（Green Alt） / BEIGE（Beige） / WHITE（White） / YELLOW（Yellow） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [COLOR_DOMESTICATION_PUDGY](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:232) | Domestication (Pudgy) | ✅ | PURPLE | ORANGE（Orange） / ORANGE_ALT（Orange Alt） / BLUE（Blue） / BLUE_ALT（Blue Alt） / PURPLE（Purple） / PURPLE_ALT（Purple Alt） / RED（Red） / RED_ALT（Red Alt） / GREEN（Green） / GREEN_ALT（Green Alt） / BEIGE（Beige） / WHITE（White） / YELLOW（Yellow） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [COLOR_DOMESTICATION_DEFAULT](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:239) | Domestication (Default) | ✅ | BEIGE | ORANGE（Orange） / ORANGE_ALT（Orange Alt） / BLUE（Blue） / BLUE_ALT（Blue Alt） / PURPLE（Purple） / PURPLE_ALT（Purple Alt） / RED（Red） / RED_ALT（Red Alt） / GREEN（Green） / GREEN_ALT（Green Alt） / BEIGE（Beige） / WHITE（White） / YELLOW（Yellow） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [COLOR_OBEDIENCE](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:246) | Obedience | ✅ | RED | ORANGE（Orange） / ORANGE_ALT（Orange Alt） / BLUE（Blue） / BLUE_ALT（Blue Alt） / PURPLE（Purple） / PURPLE_ALT（Purple Alt） / RED（Red） / RED_ALT（Red Alt） / GREEN（Green） / GREEN_ALT（Green Alt） / BEIGE（Beige） / WHITE（White） / YELLOW（Yellow） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [COLOR_TIMER](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:253) | Ride Timer | ✅ | GREEN | ORANGE（Orange） / ORANGE_ALT（Orange Alt） / BLUE（Blue） / BLUE_ALT（Blue Alt） / PURPLE（Purple） / PURPLE_ALT（Purple Alt） / RED（Red） / RED_ALT（Red Alt） / GREEN（Green） / GREEN_ALT（Green Alt） / BEIGE（Beige） / WHITE（White） / YELLOW（Yellow） | 服主；显示项可能允许客户端覆盖 | ❌ | 当前为文字面板，无徽章主题/声音/分项颜色/背景/间隔配置。 可读性优先，装饰样式按需 |
| [OffsetX](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:266) | X Offset (Horizontal) | ✅ | 0 | -200～200，步长 5（81 档） | 服主；显示项可能允许客户端覆盖 | ✅ | 个人横纵偏移；菜单横向 -300～300、纵向 -200～200，步长 100。 应补更细偏移 |
| [OffsetXMult](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:273) | X Offset Multiplier | ✅ | 1 | 1（None） / 2（2x） / 3（3x） / 4（4x） / 5（5x） / 6（6x） / 7（7x） / 8（8x） / 9（9x） / 10（10x） / 11（11x） / 12（12x） / 13（13x） / 14（14x） / 15（15x） / 16（16x） / 17（17x） / 18（18x） / 19（19x） / 20（20x） | 服主；显示项可能允许客户端覆盖 | ❌ | 无倍数及微调入口；保存校验只接受绝对值≤600。 直接提供细粒度偏移即可，无需照搬倍数 |
| [OffsetXFine](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:280) | X Offset Fine Tune | ✅ | 0 | -50～50，步长 1（101 档） | 服主；显示项可能允许客户端覆盖 | ❌ | 无倍数及微调入口；保存校验只接受绝对值≤600。 直接提供细粒度偏移即可，无需照搬倍数 |
| [OffsetY](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:293) | Y Offset (Vertical) | ✅ | 0 | -200～200，步长 5（81 档） | 服主；显示项可能允许客户端覆盖 | ✅ | 个人横纵偏移；菜单横向 -300～300、纵向 -200～200，步长 100。 应补更细偏移 |
| [OffsetYMult](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:300) | Y Offset Multiplier | ✅ | 1 | 1（None） / 2（2x） / 3（3x） / 4（4x） / 5（5x） / 6（6x） / 7（7x） / 8（8x） / 9（9x） / 10（10x） / 11（11x） / 12（12x） / 13（13x） / 14（14x） / 15（15x） / 16（16x） / 17（17x） / 18（18x） / 19（19x） / 20（20x） | 服主；显示项可能允许客户端覆盖 | ❌ | 无倍数及微调入口；保存校验只接受绝对值≤600。 直接提供细粒度偏移即可，无需照搬倍数 |
| [OffsetYFine](/home/ubuntu/Steam/steamapps/workshop/content/322330/2477889104/modinfo.lua:307) | Y Offset Fine Tune | ✅ | 0 | -50～50，步长 1（101 档） | 服主；显示项可能允许客户端覆盖 | ❌ | 无倍数及微调入口；保存校验只接受绝对值≤600。 直接提供细粒度偏移即可，无需照搬倍数 |

## Wildwise

来源：[modinfo.lua](/usr/local/src/Wildwise/modinfo.lua)。版本 0.2.1。

所有 38 项都是服主/原生配置入口。显示选项作为个人偏好初始值；修改原生配置需重启对应 shard，不是 F7 在线改服主规则。

| 配置键 | 说明 | 默认值 | 取值 | 支持 |
| --- | --- | --- | --- | --- |
| [language](/usr/local/src/Wildwise/modinfo.lua) | 语言 | auto | auto（跟随游戏） / en（English） / zh（简体中文） | ✅ |
| [ui_scale](/usr/local/src/Wildwise/modinfo.lua) | 界面缩放 | 1 | 0.75 / 1 / 1.25 / 1.5 | ✅ |
| [menu_key](/usr/local/src/Wildwise/modinfo.lua) | 菜单按键 | 288 | 287（F6） / 288（F7） / 289（F8） | ✅ |
| [diagnostics](/usr/local/src/Wildwise/modinfo.lua) | 本地诊断日志 | false | true（开启） / false（关闭） | ✅ |
| [info_enabled](/usr/local/src/Wildwise/modinfo.lua) | 信息洞察 | true | true（开启） / false（关闭） | ✅ |
| [info_container_contents](/usr/local/src/Wildwise/modinfo.lua) | 允许容器内容查询 | false | true（开启） / false（关闭） | ✅ |
| [info_world_events](/usr/local/src/Wildwise/modinfo.lua) | 允许世界事件详情 | false | true（开启） / false（关闭） | ✅ |
| [info_attack_range](/usr/local/src/Wildwise/modinfo.lua) | 允许攻击范围提示 | false | true（开启） / false（关闭） | ✅ |
| [info_font_size](/usr/local/src/Wildwise/modinfo.lua) | 信息字号 | 22 | 18 / 22 / 26 / 30 | ✅ |
| [healthbars_enabled](/usr/local/src/Wildwise/modinfo.lua) | 战斗血条 | true | true（开启） / false（关闭） | ✅ |
| [healthbars_limit](/usr/local/src/Wildwise/modinfo.lua) | 血条数量上限 | 12 | 4 / 8 / 12 / 16 / 20 | ✅ |
| [healthbars_linger_seconds](/usr/local/src/Wildwise/modinfo.lua) | 脱战收起延迟 | 2 | 0 / 1 / 2 / 3 / 5 | ✅ |
| [healthbars_scale](/usr/local/src/Wildwise/modinfo.lua) | 血条缩放 | 1 | 0.75 / 1 / 1.25 / 1.5 | ✅ |
| [healthbars_numbers](/usr/local/src/Wildwise/modinfo.lua) | 血量数值 | true | true（开启） / false（关闭） | ✅ |
| [healthbars_hostile_scope](/usr/local/src/Wildwise/modinfo.lua) | 敌意范围 | self | self（仅自己） / followers（自己及随从） / nearby（附近玩家） / nearby_followers（附近玩家及随从） | ✅ |
| [map_enabled](/usr/local/src/Wildwise/modinfo.lua) | 地图协作 | true | true（开启） / false（关闭） | ✅ |
| [map_share_position](/usr/local/src/Wildwise/modinfo.lua) | 位置共享 | auto | auto（跟随游戏模式） / on（开启） / off（关闭） | ✅ |
| [map_share_exploration](/usr/local/src/Wildwise/modinfo.lua) | 探索共享 | auto | auto（跟随游戏模式） / on（开启） / off（关闭） | ✅ |
| [items_enabled](/usr/local/src/Wildwise/modinfo.lua) | 物品整理 | true | true（开启） / false（关闭） | ✅ |
| [items_stack_world](/usr/local/src/Wildwise/modinfo.lua) | 合堆新世界掉落 | true | true（开启） / false（关闭） | ✅ |
| [items_stack_manual](/usr/local/src/Wildwise/modinfo.lua) | 合堆玩家丢弃物 | false | true（开启） / false（关闭） | ✅ |
| [items_stack_loaded](/usr/local/src/Wildwise/modinfo.lua) | 合堆读档地面物品 | false | true（开启） / false（关闭） | ✅ |
| [items_pickup_allowed](/usr/local/src/Wildwise/modinfo.lua) | 允许玩家开启自动拾取 | false | true（开启） / false（关闭） | ✅ |
| [items_pickup_existing](/usr/local/src/Wildwise/modinfo.lua) | 拾取要求背包已有同类 | true | true（开启） / false（关闭） | ✅ |
| [items_radius](/usr/local/src/Wildwise/modinfo.lua) | 物品处理半径 | 4 | 2 / 4 / 6 / 8 | ✅ |
| [queue_enabled](/usr/local/src/Wildwise/modinfo.lua) | 行为队列 | true | true（开启） / false（关闭） | ✅ |
| [queue_farm_grid](/usr/local/src/Wildwise/modinfo.lua) | 农田布点 | 3 | 2 / 3 / 4 | ✅ |
| [signs_enabled](/usr/local/src/Wildwise/modinfo.lua) | 智能小木牌 | true | true（开启） / false（关闭） | ✅ |
| [signs_treasurechest](/usr/local/src/Wildwise/modinfo.lua) | 木箱小木牌 | true | true（开启） / false（关闭） | ✅ |
| [signs_dragonflychest](/usr/local/src/Wildwise/modinfo.lua) | 龙鳞宝箱小木牌 | true | true（开启） / false（关闭） | ✅ |
| [signs_boat_ancient_container](/usr/local/src/Wildwise/modinfo.lua) | 远古船货舱小木牌 | true | true（开启） / false（关闭） | ✅ |
| [signs_chester](/usr/local/src/Wildwise/modinfo.lua) | 切斯特小木牌 | false | true（开启） / false（关闭） | ✅ |
| [signs_hutch](/usr/local/src/Wildwise/modinfo.lua) | 哈奇小木牌 | false | true（开启） / false（关闭） | ✅ |
| [signs_icebox](/usr/local/src/Wildwise/modinfo.lua) | 冰箱小木牌 | false | true（开启） / false（关闭） | ✅ |
| [signs_saltbox](/usr/local/src/Wildwise/modinfo.lua) | 盐盒小木牌 | false | true（开启） / false（关闭） | ✅ |
| [signs_fish_box](/usr/local/src/Wildwise/modinfo.lua) | 鱼类储物箱小木牌 | false | true（开启） / false（关闭） | ✅ |
| [beefalo_enabled](/usr/local/src/Wildwise/modinfo.lua) | 牛状态栏 | true | true（开启） / false（关闭） | ✅ |
| [beefalo_hunger_threshold](/usr/local/src/Wildwise/modinfo.lua) | 牛饥饿显示阈值 | 15 | 0 / 5 / 15 / 25 | ✅ |

## Wildwise 的个人设置：保存字段与实际入口

个人设置树共有 32 个叶子字段，其中 `first_tip_seen` 是内部状态；`healthbars.linger_seconds` 有保存/读取但没有 F7 控件。位置与探索的个人选择还由当前服务器按 userid 保存，welcome 采用该世界数据。其余具体值见下表与原生设置。

| 个人字段 | 初始值 | 存在保存字段 | 有公开操作入口 | 边界 |
| --- | --- | --- | --- | --- |
| map.ping_kind | location | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| map.share_exploration | true | ✅ | ✅ | F7 可切换，服务端按 userid 保存；welcome 采用当前世界返回值，不简单跨服沿用本地值。 |
| map.indicators | scoreboard | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| map.share_position | true | ✅ | ✅ | F7 可切换，服务端按 userid 保存；welcome 采用当前世界返回值，不简单跨服沿用本地值。 |
| menu_key | 288 | ✅ | ✅ | F7 重绑定任意引擎键码；restore允许0～512整数，菜单未提供明确禁用选项。 |
| queue.farm_grid | 3 | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| queue.modifier_key | 304 | ✅ | ✅ | F7 重绑定任意引擎键码；restore允许0～512整数，菜单未提供明确禁用选项。 |
| items.pickup | false | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| ui_scale | 1 | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| healthbars.enabled | true | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| healthbars.numbers | true | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| healthbars.limit | 12 | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| healthbars.scale | 1 | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| healthbars.hostile_scope | self | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| healthbars.linger_seconds | 2 | ✅ | ❌ | 有偏好字段/恢复/实际使用，但 F7 未提供入口；初始继承服主值。 |
| beefalo.visible | true | ✅ | ✅ | F7 保存；B 热键只改内存，后续其他设置保存可能一并持久化。 |
| beefalo.offset_x | 0 | ✅ | ✅ | F7 -300/-200/-100/0/100/200/300；restore只接受绝对值≤600。 |
| beefalo.toggle_key | 98 | ✅ | ✅ | F7 重绑定任意引擎键码；restore允许0～512整数，菜单未提供明确禁用选项。 |
| beefalo.offset_y | 0 | ✅ | ✅ | F7 -200/-100/0/100/200；restore只接受绝对值≤600。 |
| beefalo.hunger_threshold | 15 | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| info.font_size | 22 | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| info.preset | standard | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| info.categories.equipment | true | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| info.categories.world | true | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| info.categories.combat | true | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| info.categories.food | true | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| info.categories.progress | true | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| info.categories.farm | true | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| info.categories.follower | true | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| info.categories.container | true | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| language | auto | ✅ | ✅ | F7 可设置，持久化到 wildwise_client_v2；不越过服主许可。 |
| first_tip_seen | false | ✅ | ❌ | 首次提示内部标志；不是公开配置，首次welcome后写入。 |

## Wildwise 不能通过 modoverrides.lua 设置的内部边界

| 领域 | 固定值/策略 | 公开可配置 |
| --- | --- | --- |
| 观察 | 半径40；每玩家最多24实体订阅；实体缓存由无订阅时释放 | ❌ |
| 客户端缓存 | LRU上限256；健康/其它事实不同节奏 | ❌ |
| 查询 | 定位访问预算2048；最多40个结果；容器80格/包裹40条；每个文本240、总文本960字符预算 | ❌ |
| 信息行数 | minimal 4；常规10；检查键25；detailed预设常规仍10 | ❌ |
| 动作 | 任务上限200；双击0.35秒；同类范围15；动作白名单；4种重复工作动作 | ❌ |
| 合堆 | 每轮16候选/约2ms服务预算；最多2048待处理；落地重试最多30秒；向更早堆合并 | ❌ |
| 地图 | 标记60秒/每人5个；4种类型；探索日志65536点；虫洞6色+编号 | ❌ |
| 信号火 | 木炭触发，到燃料耗尽移除；没有信号火独立开关 | ❌ |
| 木牌 | 8种容器；尺寸0.65/固定位置；不可挖；包裹首件显示固定开启 | ❌ |
| 虫洞 | map.wormholes内部开关只由冲突检测控制；无公开单项开关 | ❌ |

读取依据：[W:core/config.lua](/usr/local/src/Wildwise/scripts/wildwise/core/config.lua)；[W:services/items.lua](/usr/local/src/Wildwise/scripts/wildwise/services/items.lua)；[W:services/map.lua](/usr/local/src/Wildwise/scripts/wildwise/services/map.lua)；[W:services/facts.lua](/usr/local/src/Wildwise/scripts/wildwise/services/facts.lua)；[W:services/observer.lua](/usr/local/src/Wildwise/scripts/wildwise/services/observer.lua)；[W:runtime/input.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/input.lua)；[W:runtime/client.lua](/usr/local/src/Wildwise/scripts/wildwise/runtime/client.lua)；[W:ui/format.lua](/usr/local/src/Wildwise/scripts/wildwise/ui/format.lua)；[W:components/wildwise_world.lua](/usr/local/src/Wildwise/scripts/components/wildwise_world.lua)。
