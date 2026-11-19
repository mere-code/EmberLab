# 物理规则与初始参数

状态：设计草案，尚未实现或通过物理验证。完整实施要求以 [第一阶段任务书](DEVIN_PHASE_1_PROMPT.md) 为准。

## 单位与配置

距离 px、时间 s、速度 px/s、加速度 px/s²；热量范围 0～100，为游戏数值而非摄氏温度。物理频率为 60 Hz，Y 正方向向下。

参数结构见 `config/physics_config.gd`，默认值统一保存在 `config/default_physics.tres`。配置中的 `initial_heat` / `maximum_heat` 对应任务书的 `heat.initial` / `heat.maximum`。

## 更新顺序

每个固定物理步：输入及环境采样 → 姿态 → 持续耗热 → 熄灭判定 → 移动与风加速度 → 水滴结算 → 熄灭与限速 → 角色碰撞移动 → 记录和视觉反馈。

实际接触检测的采样时序、碰撞层和查询方式由实现后补充，不能仅假设 Area2D 重叠列表始终同步。

## 风和耗热

```text
multiplier = 收拢 ? compact_multiplier : spread_multiplier
wind_acceleration = direction × strength × full_strength_acceleration × multiplier
loss = 当前姿态基础耗热 + strength × multiplier × full_wind_extra_loss_per_second
heat = clamp(heat - loss × dt, 0, maximum_heat)
```

风方向归一化，强度范围 0～1。满强度风加速度为 1500，高于重力 1100，因此展焰可被托起；收拢只受到 225 的风加速度。

## 水滴弹跳

每颗水滴只结算一次。收拢且接触结算前热量达到 35 时：

```text
t = clamp((heat - bounce_min_heat) / (maximum_heat - bounce_min_heat), 0, 1)
bounce_speed = lerp(bounce_speed_min, bounce_speed_max, t)
heat -= bounce_heat_cost
velocity.y = min(velocity.y, -bounce_speed)
```

默认弹跳速度范围 480～560，成本为 25；条件不满足则损失 30 热量。持续耗热先于接触判定。热量为零则熄灭；同一步后续事件不能恢复角色。

## 后续补充

- 输入缓冲和接触采样的真实执行时序。
- 碰撞层、掩码与水滴运动方式。
- 主场景路线、回放格式和配置校验。
- 实际测试后的参数选择依据。

木材、真空和真实流体不在第一阶段实施范围。
