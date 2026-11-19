# 物理验证工具交付约定

本目录目前仅预留结构。不要将 README 或空目录视为测试工具已实现。

Devin 第一阶段应在此实现：

| 文件 | 用途 |
| --- | --- |
| `run_tests.sh` | 定位 Godot、导入、超时控制、执行验收与返回状态 |
| `test_runner.gd` | 汇总规则与真实场景测试，输出报告 |
| `test_rules.gd` | 校验门槛、耗热、风力、重复接触和非法配置 |
| `test_integration.gd` | 在真实场景验证跳跃、碰撞、重置和回放 |
| `replay_runner.gd` | 以物理步输入驱动真实角色代码 |
| `sweep_runner.gd` | 固定轨迹与配置条件下扫描弹跳速度 |
| `fixtures/integration_lab.tscn` | 可重复的集成测试场景 |
| `fixtures/reference_replay.json` | 真实运行验证过的参考输入 |

运行器必须调用实际游戏逻辑，不复制公式来制造自洽测试；失败返回非零，未执行或缺少图形环境不能伪装成 PASS。

生成物写入 `reports/`，默认不纳入 Git。交付时提供真实文件或附件链接，文档同步结果摘要。

完整要求见 [第一阶段任务书](../../docs/DEVIN_PHASE_1_PROMPT.md)。
