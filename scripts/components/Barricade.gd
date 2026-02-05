extends StaticBody2D

var player_ray: PhysicsRayQueryParameters2D
var ground_ray: PhysicsRayQueryParameters2D
var original_position: Vector2
var is_attacking: bool = false
var down_distance: float
var detector: Area2D
var ground_offset: float = 24

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 初始化玩家射线查询参数（只创建一次）
	player_ray = PhysicsRayQueryParameters2D.new()
	player_ray.exclude = [self]
	player_ray.collision_mask = 2

	# 初始化地面射线查询参数（只创建一次）
	ground_ray = PhysicsRayQueryParameters2D.new()
	ground_ray.exclude = [self]
	ground_ray.collision_mask = 1 # 仅检测地面层Ground

	original_position = global_position # 保存初始位置

	detector = $Detector
	detector.body_entered.connect(_on_player_entered)
	

func _on_player_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		var facing = body._check_facing_dir()
		body.take_hit(Vector2(150 * -facing, 0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_attacking:
		return # 攻击中，不重复检测

	ground_ray.from = global_position
	ground_ray.to = global_position + Vector2(0, 200)
	
	# 如果down_distance未设置，尝试计算
	if not down_distance:
		var ground_result = get_world_2d().direct_space_state.intersect_ray(ground_ray)
		if ground_result and ground_result.collider is TileMapLayer:
			# print('down_distance', ground_result.position.y, global_position.y)
			down_distance = ground_result.position.y - global_position.y - ground_offset

	# 检测正下方是否有玩家
	player_ray.from = global_position
	player_ray.to = global_position + Vector2(0, 200)

	var result = get_world_2d().direct_space_state.intersect_ray(player_ray)
	
	if result and result.collider is CharacterBody2D:
		is_attacking = true
		_start_attack()


func _start_attack():
	# 向下动画（0.5秒下落）
	var target_y = original_position.y + down_distance
	var tween_down = create_tween()
	tween_down.tween_property(self, "global_position:y", target_y, 0.3)
	await tween_down.finished

	# 播放攻击动画
	$AnimationPlayer.play("attack")
	# 等待 0.5 秒（攻击持续时间）
	await get_tree().create_timer(0.5).timeout
	# 回到原位（0.5秒上升）
	var tween_up = create_tween()
	tween_up.tween_property(self, "global_position", original_position, 0.3)
	await tween_up.finished

	# 播放攻击动画
	$AnimationPlayer.play_backwards("attack")

	# 结束攻击状态
	is_attacking = false
