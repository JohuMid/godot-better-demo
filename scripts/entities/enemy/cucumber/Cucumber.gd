extends "res://scripts/entities/enemy/Enemy.gd"

# 状态变量（每个实例独立）
var has_hit_in_this_attack: bool = false

var vertical_jump_speed: float = 200.0

var jump_attack_player_ray: PhysicsRayQueryParameters2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	jump_attack_player_ray = PhysicsRayQueryParameters2D.new()
	jump_attack_player_ray.exclude = [self]
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if velocity.y < 0:
		_set_animation("Jump")
	elif velocity.y > 0:
		_set_animation("Fall")

	if is_on_floor() and ai_state != AIState.WAITING:
		_set_animation("Run")

func _set_animated_offset() -> void:
	animated_sprite.offset = Vector2(-24, -36)

# 检查是否在攻击
func _enter_attack_state() -> void:
	has_hit_in_this_attack = false
	velocity = Vector2(40,-vertical_jump_speed)
	# 计算朝向玩家的水平方向（-1 或 1）
	var horizontal_speed = 80.0  # 可调节

	velocity.x = horizontal_speed
	velocity.y = -vertical_jump_speed

	jump_attack_player_ray.from = global_position
	jump_attack_player_ray.to = global_position + Vector2(20 * facing, 20)

	var result = get_world_2d().direct_space_state.intersect_ray(jump_attack_player_ray)
	if result and result.collider is CharacterBody2D:
		has_hit_in_this_attack = true
		if result.collider.has_method("take_hit"):
			result.collider.take_hit(Vector2(200 * facing, 0))

	_on_animation_finished()
	# 可播放攻击音效等
	print("Cucumber 开始攻击！")

func _perform_attack_check() -> void:
	pass


func _exit_attack_state() -> void:
	has_hit_in_this_attack = false
	print("Cucumber 攻击结束")
