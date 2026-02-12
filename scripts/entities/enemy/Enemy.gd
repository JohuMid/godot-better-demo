extends CharacterBody2D

class_name Enemy

## 基础属性
@export var speed: float = 80.0
@export var jump_velocity: float = -280.0
@export var gravity: float = 1000.0
const SPRITE_SCALE: float = 1.0
# 检测范围
var detection_range: float = 40.0

# —————— 动画相关 ——————
@export var atlas: Texture2D
@export var json_path: String = "res://resources/enemy//spritesheet.json
"
var animated_sprite: AnimatedSprite2D

const ANIM_SPEED = {
	"Idle": 4.0,
	"Walk": 1.2,
	"Run": 4.0,
	"Attack": 4.0,
	"default": 1.0
}

var original_frame_width: int = 48
var original_frame_height: int = 48

## 内部状态
var facing: int = 1
var is_grounded: bool = false

# —————— 新增：AI 状态管理 ——————
enum AIState {MOVING, WAITING, ATTACKING}
var ai_state: int = AIState.WAITING
var wait_timer: float = 0.0
var turn_wait_time: float = 2.0

# 缓存射线查询参数，避免每帧新建
var front_block_ray: PhysicsRayQueryParameters2D
var front_cliff_ray: PhysicsRayQueryParameters2D
var player_ray: PhysicsRayQueryParameters2D

func _ready() -> void:
	print("Enemy _ready")
	if not atlas:
		push_error("请在检查器中指定 Atlas 纹理！")
		return

	var frames = TexturePackerImporter.create_sprite_frames(atlas, json_path, original_frame_width, original_frame_height)
	animated_sprite = $AnimatedSprite2D
	animated_sprite.sprite_frames = frames

	animated_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	animated_sprite.centered = false
	_set_animated_offset()

	# 初始化前方障碍射线查询参数（只创建一次）
	front_block_ray = PhysicsRayQueryParameters2D.new()
	front_block_ray.exclude = [self]
	
	# 初始化前方悬崖射线查询参数（只创建一次）
	front_cliff_ray = PhysicsRayQueryParameters2D.new()
	front_cliff_ray.exclude = [self]
	front_cliff_ray.collision_mask = 1 # 仅检测地面层Ground

	# 初始化玩家检测射线查询参数（只创建一次）
	player_ray = PhysicsRayQueryParameters2D.new()
	player_ray.exclude = [self]

	# 初始化面向方向
	_update_facing_direction()

	_set_animation("Run") # 启动即跑步

	animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	ai_state = AIState.MOVING
	_set_animation("Run")

func _physics_process(delta: float) -> void:
	match ai_state:
		AIState.MOVING:
			_handle_moving()
		AIState.WAITING:
			_handle_waiting(delta)
		AIState.ATTACKING:
			_handle_attacking(delta)

	# 添加重力
	_handle_gravity(delta)

	# —— 敌人和平台同步速度 ——
	if is_on_floor():
		var coll = get_last_slide_collision()
		if coll:
			var enemy = coll.get_collider()
			if enemy and "current_velocity" in enemy:
				if ai_state == AIState.WAITING:
					velocity = enemy.current_velocity
				elif ai_state == AIState.MOVING:
					velocity += enemy.current_velocity
				
	move_and_slide()

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

# —————— AI 行为 ——————
func _handle_moving() -> void:
	_update_facing_direction()
	# 检测前方是否有障碍或者悬崖
	if _is_front_blocked() or _is_front_cliff():
		# 触发等待状态
		ai_state = AIState.WAITING
		wait_timer = turn_wait_time
		_set_animation("Idle")
		velocity.x = 0
		return
	elif _is_player_detected():
		# 触发攻击状态
		ai_state = AIState.ATTACKING
		_enter_attack_state()
		return

	# 正常移动
	velocity.x = speed * facing
	_set_animation("Run")
	

func _handle_waiting(delta: float) -> void:
	wait_timer -= delta
	if wait_timer <= 0:
		# 等待结束，转身
		facing *= -1
		ai_state = AIState.MOVING

func _set_animated_offset() -> void:
	pass

func _enter_attack_state() -> void:
	pass

# —————— 攻击逻辑 ——————
func _handle_attacking(delta: float) -> void:
	_perform_attack_check()

func _perform_attack_check() -> void:
	pass

# —————— 检测逻辑 ——————
func _is_front_blocked() -> bool:
	# 动态更新射线起点和终点（根据当前位置和朝向）
	front_block_ray.from = global_position
	front_block_ray.to = global_position + Vector2(20 * facing, 0)

	var result = get_world_2d().direct_space_state.intersect_ray(front_block_ray)
	return result and (result.collider is TileMapLayer or result.collider.is_in_group("box"))

func _is_front_cliff() -> bool:
	# 检测正下方是否有地面（用于防掉落）
	front_cliff_ray.from = global_position
	front_cliff_ray.to = global_position + Vector2(16 * facing, 20)

	var result = get_world_2d().direct_space_state.intersect_ray(front_cliff_ray)
	return is_on_floor() and result.is_empty() # 没有碰撞 → 是悬崖

func _is_player_detected() -> bool:
	# 检测玩家是否在检测范围内
	player_ray.from = global_position
	player_ray.to = global_position + Vector2(detection_range * facing, 0)

	var result = get_world_2d().direct_space_state.intersect_ray(player_ray)
	return result and result.collider.is_in_group("player")

# —————— 更新面向方向 ——————
func _update_facing_direction() -> void:
	animated_sprite.scale.x = - SPRITE_SCALE * facing

# —————— 设置动画 ——————
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
