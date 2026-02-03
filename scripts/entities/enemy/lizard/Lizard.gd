extends "res://scripts/entities/enemy/Enemy.gd"

@export var attack_frames: Array = [4, 5, 6]  # 第5/6/7帧（索引从0）

# 状态变量（每个实例独立）
var has_hit_in_this_attack: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	original_frame_width = 72
	original_frame_height = 48
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _set_animated_offset() -> void:
	animated_sprite.offset = Vector2(-50, -36)

func _enter_attack_state() -> void:
	_set_animation("Attack")
	has_hit_in_this_attack = false
	# 可播放攻击音效等
	print("Lizard 开始攻击！")

# 检查是否在攻击帧
func _perform_attack_check() -> void:
	velocity.x = 0
	# 只在特定帧检测
	if animated_sprite.frame in attack_frames:
		if not has_hit_in_this_attack:
			if _check_lizard_attack_hit():
				has_hit_in_this_attack = true

func _exit_attack_state() -> void:
	has_hit_in_this_attack = false
	print("Lizard 攻击结束")

# Lizard 特有的命中检测
func _check_lizard_attack_hit() -> bool:
	var attack_offset = Vector2(30 * facing, 0)
	var attack_pos = global_position + attack_offset
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2(25, 30)

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.transform = Transform2D(0, attack_pos)
	query.shape = shape
	# 玩家层
	query.collision_mask = 2
	query.exclude = [self]

	var results = space_state.intersect_shape(query)
	for result in results:
		if result.collider.has_method("take_hit"):
			result.collider.take_hit(Vector2(200 * facing, 0))  # 传递伤害值
			return true
	return false
