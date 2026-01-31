extends CharacterBody2D

class_name Enemy

## 基础属性
@export var speed: float = 80.0
@export var jump_velocity: float = -280.0
@export var gravity: float = 1000.0
const SPRITE_SCALE: float = 1.0

# —————— 动画相关 ——————
@export var atlas: Texture2D
@export var json_path: String = "res://resources/enemy/"
var animated_sprite: AnimatedSprite2D

const ANIM_SPEED = {
	"Idle": 4.0,
	"Walk": 1.2,
	"Run": 4.0,
	"default": 1.0
}

const ORIGINAL_FRAME_WIDTH: int = 72
const ORIGINAL_FRAME_HEIGHT: int = 48

## 内部状态
var facing: int = 1
var is_grounded: bool = false

# —————— 新增：AI 状态管理 ——————
enum AIState { MOVING, WAITING }
var ai_state: int = AIState.WAITING
var wait_timer: float = 0.0
const TURN_WAIT_TIME: float = 2.0

# 缓存 RayCast 引用
var front_detector: RayCast2D

func _ready() -> void:
	print("Enemy _ready")
	if not atlas:
		push_error("请在检查器中指定 Atlas 纹理！")
		return

	var frames = TexturePackerImporter.create_sprite_frames(atlas, json_path, ORIGINAL_FRAME_WIDTH, ORIGINAL_FRAME_HEIGHT)
	animated_sprite = $AnimatedSprite2D
	animated_sprite.sprite_frames = frames

	animated_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	animated_sprite.centered = false
	animated_sprite.offset = Vector2(-50, -36)

	# 关键：初始化面向方向
	_update_facing_direction()

	_set_animation("Run")  # 启动即跑步

func _physics_process(delta: float) -> void:
	
	match ai_state:
		AIState.MOVING:
			_handle_moving(delta)
		AIState.WAITING:
			_handle_waiting(delta)

	# 添加重力
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()

# —————— AI 行为 ——————
func _handle_moving(delta: float) -> void:
	# 检测前方是否有障碍
	if _is_front_blocked():
		# 触发等待状态
		ai_state = AIState.WAITING
		wait_timer = TURN_WAIT_TIME
		_set_animation("Idle")
		velocity.x = 0
		return

	# 正常移动
	velocity.x = speed * facing
	_set_animation("Run")
	_update_facing_direction()

func _handle_waiting(delta: float) -> void:
	wait_timer -= delta
	velocity.x = 0  # 确保不动
	if wait_timer <= 0.15:
		# 等待结束，转身
		facing *= -1
		ai_state = AIState.MOVING

# —————— 检测逻辑 ——————
func _is_front_blocked() -> bool:
	var forward_offset = Vector2(20 * facing, 0)
	var from = global_position
	var to = global_position + forward_offset

	var ray = PhysicsRayQueryParameters2D.new()
	ray.from = from
	ray.to = to
	ray.exclude = [self]

	var result = get_world_2d().direct_space_state.intersect_ray(ray)
	if result and result.collider is TileMapLayer:
		return true
	else:
		return false

func _is_front_cliff() -> bool:
	var space_state = get_world_2d().direct_space_state

	var ray_forward = PhysicsRayQueryParameters2D.new()
	ray_forward.from = global_position
	ray_forward.to = global_position + Vector2(0, 20)
	ray_forward.exclude = [self]
	ray_forward.collision_mask = 1

	var result = space_state.intersect_ray(ray_forward)
	return result.is_empty()  # 没撞到 → 是悬崖

# —————— 工具函数 ——————
func _update_facing_direction() -> void:
	animated_sprite.scale.x = -SPRITE_SCALE * facing

# —————— 原有方法保留 ——————
func _set_animation(anim_name: String):
	if animated_sprite.animation == anim_name:
		return
	
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		var speed_scale = ANIM_SPEED.get(anim_name, ANIM_SPEED.default)
		animated_sprite.speed_scale = speed_scale
		# print("▶ 播放动画: %s (速度: %.1f)" % [anim_name, speed_scale])
	else:
		print("⚠️ 动画不存在: %s" % anim_name)
