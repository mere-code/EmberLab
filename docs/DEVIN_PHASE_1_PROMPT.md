# Devin 第一阶段完整任务书

> 本文是交给 Devin 执行的未来开发任务。仓库初始化不代表这些功能、测试和报告已经完成。仓库已有骨架时直接在根目录继续，不要再嵌套创建 EmberLab，也不要覆盖已有用户改动。

你负责从零实现一个 Godot 2D 横版闯关原型，项目名称 EmberLab（火借万物）。

请直接完成项目、运行验证并交付，不要只提供设计方案。自行处理常规实现细节；遇到无法安装引擎、缺少图形环境等实际阻塞时，如实说明，并继续完成不受阻塞的部分。

## 一、项目目标与边界

玩家是一团火，可以移动、跳跃，按住按钮收拢，松开恢复展焰。

第一阶段只实现：

1. 稳定的角色控制。
2. 水滴弹跳。
3. 风场交互。
4. 热量消耗与熄灭。
5. 调试面板、输入录制与回放。
6. 自动验收脚本和小规模参数扫描。

暂不实现木材、真空、敌人、背包、联网、真实流体模拟或正式美术。

使用独立的 EmberLab 项目目录，不要改造或混入已有的其他应用项目。若从空目录开始且目标目录发生冲突，选择新的目录，不覆盖现有文件；若已有本仓库骨架，则在其基础上完成任务。

遵守所在仓库的 AGENTS.md；不推送远程，不混入无关修改。远程推送由仓库所有者另行授权。

## 二、技术选型

- Godot 4.x 稳定版，使用 GDScript。
- 优先使用环境中已安装的稳定版本，记录完整版本号。
- 使用 Compatibility 渲染器。
- 角色使用 CharacterBody2D，静态场景使用 StaticBody2D。
- 水滴与风场使用 Area2D 或等价的可靠空间查询。
- 固定物理频率 60 Hz。
- 游戏规则在物理步更新，视觉动画不能修改物理状态。
- 不引入第三方插件或测试框架。
- 窗口逻辑分辨率 640×360，像素风采用最近邻过滤。
- 手写代码的说明性注释、文档和脚本文档字符串使用中文。

## 三、目标目录结构

以下为完成第一阶段后的目标，不是当前实现清单。

```text
EmberLab/
├── project.godot
├── .gitignore
├── README.md
├── scenes/
│   ├── main.tscn
│   ├── player.tscn
│   ├── water_drop.tscn
│   └── wind_zone.tscn
├── scripts/
│   ├── player_controller.gd
│   ├── flame_rules.gd
│   ├── flame_state.gd
│   ├── water_drop.gd
│   ├── wind_zone.gd
│   ├── lab_controller.gd
│   ├── input_source.gd
│   ├── replay_controller.gd
│   └── debug_panel.gd
├── config/
│   ├── physics_config.gd
│   └── default_physics.tres
├── docs/
│   ├── DEVIN_PHASE_1_PROMPT.md
│   ├── mechanics.md
│   └── acceptance.md
└── tools/
    └── physics_lab/
        ├── README.md
        ├── run_tests.sh
        ├── test_runner.gd
        ├── test_rules.gd
        ├── test_integration.gd
        ├── replay_runner.gd
        ├── sweep_runner.gd
        ├── fixtures/
        │   ├── integration_lab.tscn
        │   └── reference_replay.json
        └── reports/
            └── .gitkeep
```

可以合理增加文件，但不要创建 tool/ 目录。忽略 .godot/、临时日志和自动生成的测试报告。保留项目运行所需的资源、稳定 UID 文件与测试夹具。

## 四、参数配置

使用带 @export 变量的自定义 Resource 保存参数，default_physics.tres 是默认参数的唯一来源。游戏、测试和参数扫描共用同一配置结构。公式不得另写一套隐藏常量。

单位：距离 px，时间 s，速度 px/s，加速度 px/s²。热量为游戏数值，不代表摄氏温度。

```yaml
simulation:
  physics_hz: 60

movement:
  move_speed: 180
  ground_acceleration: 1400
  air_acceleration: 700
  gravity: 1100
  jump_speed: 380
  max_horizontal_speed: 360
  max_rise_speed: 560
  max_fall_speed: 700

heat:
  initial: 70
  maximum: 100
  spread_loss_per_second: 2
  compact_loss_per_second: 0.5
  full_wind_extra_loss_per_second: 4

wind:
  full_strength_acceleration: 1500
  spread_multiplier: 1.0
  compact_multiplier: 0.15

water:
  bounce_min_heat: 35
  bounce_heat_cost: 25
  bounce_speed_min: 480
  bounce_speed_max: 560
  failed_contact_heat_damage: 30
```

已有 Resource 使用 initial_heat / maximum_heat 对应 heat.initial / heat.maximum。物理频率以配置为准加载到引擎，project.godot 中的初始 60 Hz 必须保持一致；测试中检查这种一致性。

配置加载时验证范围：

- 物理频率为正。
- 热量上限大于弹跳门槛，初始热量在合法范围。
- 弹跳门槛不小于弹跳成本。
- 速度、加速度、成本、耗热不为负。
- 最小弹跳速度不大于最大弹跳速度。
- 最大弹跳速度不超过向上速度上限。
- 拒绝 NaN、Inf 等非有限值。

非法配置给出明确错误，不静默使用错误数值。

## 五、角色与交互规则

操作：

- A/D 或左右方向键：移动。
- Space：跳跃，仅落地时可触发。
- 按住 Shift：收拢；松开：展焰。
- R：重置整个实验场。
- F1：显示或隐藏调试面板。
- F5：开始或结束录制。
- F6：从相同初始状态播放最近一次录制。

收拢和展焰共用同一个碰撞体，避免切换时卡墙。视觉尺寸可以变化。坐标约定：Y 正方向向下。

每个固定物理步按统一顺序执行：

1. 读取这一物理步的输入和环境。
2. 更新收拢/展焰状态。
3. 计算持续耗热。
4. 若热量归零，进入熄灭状态。
5. 更新移动速度、重力与风加速度。
6. 处理当前待结算的水滴接触。
7. 再次检查熄灭、限制速度。
8. 执行 move_and_slide。
9. 记录状态与事件，更新显示。

接触检测需要适配真实物理查询时序，避免使用过期重叠列表；在 mechanics.md 说明采样和结算发生在哪个物理步。

角色移动：

- 根据输入轴，以地面/空中加速度将水平速度趋近目标速度。
- 然后叠加风加速度，不要在叠加风之后直接覆盖水平速度。
- 重力和所有持续变化均乘 dt。
- move_and_slide 使用速度，不要再次把速度乘 dt。
- 跳跃设置 velocity.y = -jump_speed。

风场规则：

```text
每个风场提供单位方向和 0～1 强度。
multiplier = 收拢 ? compact_multiplier : spread_multiplier
wind_acceleration = direction × strength × full_strength_acceleration × multiplier
热量损失率 = 当前姿态基础耗热
             + strength × multiplier × full_wind_extra_loss_per_second
heat = clamp(heat - 热量损失率 × dt, 0, maximum)
```

第一阶段只需支持一个有效风场；多个风场重叠时选择优先级最高者，相同优先级按稳定编号选择。将这个约定写入文档。

水滴规则：

- 每颗水滴拥有稳定编号和 consumed 标记。
- 首次结算时立即标记 consumed，再发事件和删除节点。
- 同一颗水滴最多结算一次。
- 同一步遇到多颗水滴，按稳定编号顺序处理。
- 热量以本步持续耗热之后、接触扣热之前的值判断。

```text
如果角色存活、正在收拢，且 heat >= bounce_min_heat：
  t = clamp(
    (heat - bounce_min_heat) / (maximum - bounce_min_heat),
    0,
    1
  )
  bounce_speed = lerp(bounce_speed_min, bounce_speed_max, t)
  heat -= bounce_heat_cost
  velocity.y = min(velocity.y, -bounce_speed)
  发出一次 steam_bounce 事件
否则：
  heat = max(0, heat - failed_contact_heat_damage)
  发出一次 water_damage 事件
```

不要把弹跳速度作为可无限累加的冲量。

所有交互后：

- heat 保持在 0～maximum。
- velocity.x 保持在 ±max_horizontal_speed。
- velocity.y 保持在 -max_rise_speed～max_fall_speed。

熄灭规则：

- 停止接受移动、跳跃和弹跳输入。
- 可以保留重力和碰撞，让角色落地。
- 显示“已熄灭，按 R 重试”。
- 热量归零后不能被后续事件恢复成存活状态。

## 六、灰盒关卡与反馈

主场景包含：

1. 平地与普通跳跃练习平台。
2. 一处必须借助水滴弹跳才能抵达的平台。
3. 一个默认向上的可切换风场。
4. 清晰的出生点和终点。

水滴可以沿固定轨迹下落；R 恢复其初始位置与状态。安排可重复练习的路线，不要求首次试玩就精准输入。

风场用箭头显示方向和强度。角色用简单像素形状区分：

- 展焰：较高、明亮。
- 收拢：较紧凑。
- 熄灭：暗色。
- 蒸汽弹跳：短暂白色效果。

满强度向上风场中，展焰能够从静止开始上升；收拢从静止开始仍会下落。

调试面板显示：

- 热量、姿态、存活状态。
- 位置、速度、物理步编号。
- 当前风场强度和计算出的风加速度。
- 最近一次水滴事件。
- 当前配置标识。
- 录制/回放状态。

提供暂停时编辑热量、风强度和弹跳速度的调试入口。运行时修改使用配置副本，不覆盖默认资源。修改参数后要求重置场景再开始正式录制。

## 七、输入录制与回放

真人输入和回放输入通过同一 InputSource 接口进入角色控制器。回放不能直接设置角色轨迹或绕过交互规则。

按物理步记录：tick、move_axis、jump_pressed、compact_held。

回放文件还必须包含：

- 文件格式版本。
- Godot 版本。
- 完整参数快照与配置哈希。
- 初始角色状态。
- 场景/夹具版本。
- 随机种子；不使用随机数时明确记录。

播放前重置角色、风场、水滴、计时器、事件计数器。每个物理步结束后记录位置、速度、热量、状态及关键事件。

只承诺相同引擎版本和环境内的可重复性，不要宣称跨平台逐位确定性。

交付一个真实验证过的 reference_replay.json，能够展示至少一次水滴弹跳和一次风场交互。

## 八、自动验收

实现不依赖第三方插件的测试运行器。测试必须调用游戏实际使用的规则和场景；不要在测试里复制公式，再用复制结果验证自身。

### 规则测试

1. 关闭持续耗热后，热量 34、收拢接触水滴：不弹跳，剩余热量为 4。
2. 同样条件热量 35：弹跳，剩余热量为 10，向上速度为 480。
3. 热量 100：弹跳后热量为 75，向上速度为 560。
4. 展焰状态即使热量足够，也不能触发蒸汽弹跳。
5. 同一水滴重复提交接触 10 次，只扣热和发事件一次。
6. 满风强度下：展焰风加速度大小 1500，收拢为 225。
7. 无风、关闭其他交互，持续 10 秒：展焰热量从 70 降到 50；收拢热量从 70 降到 65；浮点误差不超过 0.01。
8. 检验耗热后恰好跨过弹跳门槛的情况，确认判断顺序符合第五节。
9. 热量归零后不再接受跳跃或弹跳。
10. 非法配置被明确拒绝。

第 2、3 项在接触前竖直速度为 0 时检查弹跳结算后的即时速度，不混入后续重力步。

### 真实场景集成测试

1. 无风普通跳跃高度约 66 px，允许 ±5 px。
2. 从空中静止开始，满强度向上风作用 0.5 秒：展焰最终竖直速度为负，收拢为正。
3. 真实碰撞检测触发水滴事件，并验证不会重复触发。
4. 熄灭后按 R，角色、水滴、热量与事件计数恢复初始值。
5. 参考回放连续运行 3 次：每个物理步的位置偏差不超过 0.1 px，热量偏差不超过 0.01，事件序列完全一致。
6. 在固定 60 Hz 物理步下，分别设置 30/60/120 FPS 上限，执行相同回放，比较逐步轨迹：最大位置偏差不超过 2 px，事件序列一致。
7. 正常游戏路径不能出现 NaN、Inf、超出热量范围或超速。

第 6 项必须区分“设置的 FPS 上限”和“实际观测 FPS”。有图形环境时禁用垂直同步进行验证并记录实际帧率。无图形环境时只能报告主循环节奏测试；图形帧率验收标记为 SKIP，不能冒充已验证。硬件达不到目标帧率时同样报告实际限制。

## 九、测试脚本与报告

run_tests.sh 要求：

- 可从任意工作目录调用。
- 使用严格错误处理并正确引用带空格路径。
- 支持通过 GODOT_BIN 指定可执行文件。
- 否则查找 godot、godot4 和常见 macOS 应用路径。
- 运行前输出完整引擎版本。
- 先无窗口导入项目，再执行测试。
- 为测试进程设置合理超时，超时计为失败。
- 保留完整标准输出与错误日志。
- 测试失败、进程崩溃、脚本解析错误返回非零退出码。
- 不允许通过隐藏日志或过滤错误来获得绿色结果。

README 中给出一条可复制的运行命令：

```sh
bash tools/physics_lab/run_tests.sh
```

报告写入 tools/physics_lab/reports/：

- acceptance.json
- acceptance.txt
- engine.log
- replay_trace.csv

每个测试记录：测试名、PASS / FAIL / SKIP、预期值、实际值、容差、失败或跳过原因、引擎版本和配置哈希。

同时记录汇总状态：全部必需项通过才算完整通过。出现 SKIP 时明确标记“验证不完整”，不能写成全部通过。

## 十、小规模参数扫描

实现 sweep_runner.gd，只扫描一组参数：

```text
bounce_speed_min = [440, 460, 480, 500, 520]
```

其余参数、关卡布局与输入条件保持不变。使用独立配置副本，禁止修改默认资源。

对每个候选值测试固定的水滴接近轨迹，枚举接触前后 -6～+6 个物理步的收拢开始时间，保持到接触结束，并记录：

- 是否触发弹跳。
- 是否抵达目标平台。
- 接触时和结束时热量。
- 最高点。
- 成功输入时间偏移集合。
- 最长连续成功窗口，单位为物理步和毫秒。

先验证该轨迹确实经过水滴，不得直接注入“接触成功”事件。明确接触时间基准的测量方式；偏移到接触之后的输入可以失败，不得调整水滴轨迹来强行制造成功。

输出 sweep.csv 和简短解释。这些结果仅代表该测试轨迹的容错范围，不得称为真实玩家通关率。本轮不自动覆盖默认参数，由交付结果提出建议。

## 十一、实施顺序

1. 建立或检查已有项目骨架，验证主场景可以启动。
2. 完成角色移动、配置和热量规则。
3. 完成水滴和风场交互。
4. 完成灰盒关卡和调试显示。
5. 完成录制、回放和自动验收。
6. 完成小规模参数扫描。
7. 修复失败项，整理交付。

每个阶段简短报告：已完成内容、验证结果、实际阻塞。不要为了通过测试而放宽验收阈值、删除失败测试，或针对参考回放写特殊分支。发现要求存在矛盾时，说明证据与最小修正建议。

## 十二、最终交付

交付：

1. 完整可运行 Godot 项目。
2. README：引擎版本、启动方式、按键、测试和扫描命令。
3. mechanics.md：更新顺序、公式、碰撞层和接触结算时序。
4. acceptance.md：验收结果与已知限制。
5. 测试脚本、真实生成的报告和参考回放。
6. 参数扫描结果。
7. 有图形环境时提供实际运行截图或短视频。

最终回复明确列出：项目路径、如何启动、如何运行测试、PASS / FAIL / SKIP 数量、尚未验证的内容、建议下一轮调整的参数及依据。

未经实际执行的测试必须标为未执行，不得编造结果。

## 技术参考

- [Godot CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)
- [Godot Engine 物理频率与帧率](https://docs.godotengine.org/en/stable/classes/class_engine.html)
- [Godot 命令行运行与导入](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)

具体 API 以首次选定并记录的 Godot 版本为准。
