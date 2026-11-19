extends Resource
class_name EmberPhysicsConfig

## 火焰交互参数结构，默认数值统一从 default_physics.tres 加载。
## 当前只声明字段；加载校验和运行时配置副本由第一阶段实现。

@export_group("Simulation")
@export var physics_hz: int

@export_group("Movement")
@export var move_speed: float
@export var ground_acceleration: float
@export var air_acceleration: float
@export var gravity: float
@export var jump_speed: float
@export var max_horizontal_speed: float
@export var max_rise_speed: float
@export var max_fall_speed: float

@export_group("Heat")
@export var initial_heat: float
@export var maximum_heat: float
@export var spread_loss_per_second: float
@export var compact_loss_per_second: float
@export var full_wind_extra_loss_per_second: float

@export_group("Wind")
@export var full_strength_acceleration: float
@export var spread_multiplier: float
@export var compact_multiplier: float

@export_group("Water")
@export var bounce_min_heat: float
@export var bounce_heat_cost: float
@export var bounce_speed_min: float
@export var bounce_speed_max: float
@export var failed_contact_heat_damage: float
