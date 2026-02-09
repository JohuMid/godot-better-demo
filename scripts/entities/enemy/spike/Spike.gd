extends "res://scripts/entities/enemy/Enemy.gd"

var has_hit_in_this_attack: bool = false
var down_ray: PhysicsRayQueryParameters2D
var is_attacking: bool = false
var down_distance: float = 40.0 # 攻击距离（可调节）
var original_position: Vector2 # 保存初始位置
var ground_offset: float = 10.0 # 地面偏移（可调节）
var detector: Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 初始化玩家射线查询参数（只创建一次）
	down_ray = PhysicsRayQueryParameters2D.new()
	down_ray.exclude = [self]
	down_ray.collision_mask = 2

	original_position = global_position # 保存初始位置
	detector = $Detector
	detector.body_entered.connect(_on_player_entered)

	turn_wait_time = 0.0
	super ()

func _set_animated_offset() -> void:
	animated_sprite.offset = Vector2(-24, -20)

func _handle_gravity(delta: float) -> void:
	pass

func _is_player_detected() -> bool:
	if is_attacking:
		return false # 攻击中，不重复检测
	# 检测正下方是否有玩家
	down_ray.from = global_position
	down_ray.to = global_position + Vector2(0, down_distance)

	var result = get_world_2d().direct_space_state.intersect_ray(down_ray)

	if result and result.collider.is_in_group("player"):
		is_attacking = true
		return true
	else:
		is_attacking = false
		return false

func _on_player_entered(body: Node2D) -> void:
	print(body)
	if body is CharacterBody2D:
		body.take_hit(Vector2(150, 0))

# 检查是否在攻击
func _enter_attack_state() -> void:
	has_hit_in_this_attack = false
	velocity.x = 0
	_start_attack()
	# _on_animation_finished()
	# 可播放攻击音效等
	print("Spike 开始攻击！")

func _start_attack() -> void:
	# 向下动画（0.5秒下落）
	var target_y = original_position.y + down_distance
	var tween_down = create_tween()
	tween_down.tween_property(self, "global_position:y", target_y, 0.3)
	await tween_down.finished

	# 播放攻击动画
	_set_animation("Attack")
	# 等待 0.5 秒（攻击持续时间）
	await get_tree().create_timer(0.5).timeout
	# 回到原位（0.5秒上升）
	var tween_up = create_tween()
	tween_up.tween_property(self, "global_position", original_position, 0.3)
	await tween_up.finished

	# 结束攻击状态
	is_attacking = false

func _exit_attack_state() -> void:
	has_hit_in_this_attack = false
	print("Spike 攻击结束")
