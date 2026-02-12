# Player.gd
extends CharacterBody2D

# —————— 导出属性（可在编辑器调整）——————
@export var speed: float = 80.0
@export var jump_velocity: float = -200.0
@export var gravity: float = 800.0
@export var gravity_scale: float = 1

# —————— 动画相关 ——————
@export var atlas: Texture2D
@export var json_path: String = "res://resources/player/spritesheet.json"

# —————— 攀爬相关 ——————
@export var climb_check_forward: float = 8.0 # 向前检测距离（像素）
@export var climb_check_up: float = -8.0 # 向上偏移（负值表示向上）
@export var climb_stand_offset: float = -4.0 # 爬上后角色底部应处的 Y 偏移（相对于边缘点）
var climb_target_y: float = 0.0
var is_climbing: bool = false

# —————— 推箱子相关 ——————
@export var box_distance: float = 8.0 # 推箱子距离（像素）
var is_pushing: bool = false

# —————— 动画帧偏移相关 ——————
var original_offset: Vector2 = Vector2.ZERO # 原始偏移量
var platform_jump_offset: float = -44 # PlatformJump最后两帧的向上偏移

# —————— 受击相关 ——————
var is_hit: bool = false
var hit_duration: float = 1 # 受击僵直时间（秒）
var hit_timer: float = 0.0

# —————— 绳子相关 ——————
var on_rope: bool = false
var rope_segment: RigidBody2D = null
var climbing: bool = false
var swing_force: float = 15.0
var climb_speed: float = 40.0 # ✅ 降低爬行速度（30-50 之间）

var rope_climb_offset: float = 0.0 # 玩家在当前绳段上的偏移量
var target_position: Vector2 = Vector2.ZERO # 目标位置
var position_smoothness: float = 12.0 # 位置平滑系数（8-15 之间）

var is_swinging: bool = false # 是否正在荡秋千
var swing_smoothness: float = 20.0 # 荡秋千时的快速跟随系数

# 挂点和旋转
var hang_offset_y: float = 12.0 # 玩家在绳子下方的距离
var rotation_smoothness: float = 15.0 # 旋转平滑系数
var max_rotation_angle: float = PI / 3 # 最大旋转角度（60度）

# 跳离冷却
var rope_detach_cooldown: float = 0.0 # 冷却计时器
var rope_detach_cooldown_time: float = 0.3 # 冷却时间（秒）

# —— 角色原始帧尺寸 ——
const ORIGINAL_FRAME_WIDTH: int = 128
const ORIGINAL_FRAME_HEIGHT: int = 128
const SPRITE_SCALE: float = 0.2

# —— 动画速度配置 ——
const ANIM_SPEED = {
	"Idle": 1.2, # 慢速站立
	"Walk": 1.2, # 步行
	"Running": 2.5, # 跑步
	"SideJumpUp": 3.0, # 跑跳上升
	"SideJumpDown": 1.0, # 跑跳下降
	"UpwardJumpUp": 5.0, # 原地跳上升
	"UpwardJumpDown": 1.0, # 原地跳下降
	"Landing": 1.7, # 落地
	"PlatformJump": 2.0, # 跳跃平台
	"Death": 2.0, # 死亡
	"TakingDamage": 2.0, # 受击
	"ClimbingLadder": 2.0, # 攀爬
	"default": 1.0
}

var animated_sprite: AnimatedSprite2D
var was_on_floor: bool = false

var box_ray: PhysicsRayQueryParameters2D
var climb_ray: PhysicsRayQueryParameters2D

# —————— 初始化 ——————
func _ready():
	add_to_group("player")
	if not atlas:
		push_error("请在检查器中指定 Atlas 纹理！")
		return
	
	EventManager.subscribe(EventNames.PRESSURE_PLATE_ACTIVATED, Callable(self, "_on_pressure_plate_activated"))
	EventManager.subscribe(EventNames.COUNTDOWN_END, Callable(self, "_on_countdown_end"))

	var frames = TexturePackerImporter.create_sprite_frames(atlas, json_path, ORIGINAL_FRAME_WIDTH, ORIGINAL_FRAME_HEIGHT)
	animated_sprite = $AnimatedSprite2D
	animated_sprite.sprite_frames = frames

	# 设置缩放和对齐（关键！）
	animated_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	animated_sprite.centered = false
	animated_sprite.offset = Vector2(
		- float(ORIGINAL_FRAME_WIDTH) / 2.0,
		- ORIGINAL_FRAME_HEIGHT
	)

	# 存储原始偏移量
	original_offset = animated_sprite.offset

	# 连接动画信号
	animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	animated_sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))
	_create_collision_shape()
	_set_animation("Idle")

	# 初始化推箱子射线查询参数（只创建一次）
	box_ray = PhysicsRayQueryParameters2D.new()
	box_ray.exclude = [self]

	climb_ray = PhysicsRayQueryParameters2D.new()
	climb_ray.exclude = [self]
	# 检测层，添加 64 层以检测断桥
	climb_ray.collision_mask = 1 | 64 | 128

# —————— 创建碰撞体 ——————
func _create_collision_shape():
	var scaled_width = ORIGINAL_FRAME_WIDTH * SPRITE_SCALE
	var scaled_height = ORIGINAL_FRAME_HEIGHT * SPRITE_SCALE

	var capsule = CapsuleShape2D.new()
	capsule.radius = scaled_width * 0.15 # 窄碰撞体
	capsule.height = scaled_height * 0.7

	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = capsule
	collision_shape.position = Vector2(0, -scaled_height * 0.35)
	collision_shape.name = "PlayerCollider"
	
	add_child(collision_shape)

# —————— 物理处理 ——————
func _physics_process(delta):
	# ===== 更新跳离冷却 =====
	if rope_detach_cooldown > 0:
		rope_detach_cooldown -= delta

	# ===== 绳子 physics_process =====
	if on_rope:
		handle_rope_physics(delta)
		return


	# ===== 旋转平滑处理 =====
	if abs(rotation) > 0.01:
		rotation = lerp_angle(rotation, 0.0, 10.0 * delta) # 10.0 是平滑系数

	# ===== 受击期间不处理输入 =====
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0:
			is_hit = false
		# 死亡动画
		_set_animation("Death")
		return

	if is_climbing:
		move_and_slide()
		return

	var current_on_floor = is_on_floor()

	# 重力处理
	if not current_on_floor:
		velocity.y += gravity * gravity_scale * delta
	else:
		velocity.y = 0

	# 跳跃处理
	if Input.is_action_just_pressed("jump") and current_on_floor:
		velocity.y = jump_velocity
		_set_animation("SideJumpUp" if abs(velocity.x) > 50 else "UpwardJumpUp")

	var input_dir = _check_input_dir()
	# 水平移动
	if current_on_floor:
		velocity.x = input_dir * speed
	else:
		# 空中移动速度应小于地面，使用 air_control 系数（例如 0.5 倍）
		var air_control = 0.5
		var target_air_velocity = input_dir * speed * air_control
		# 平滑过渡到目标空中速度（避免突变）
		velocity.x = lerp(velocity.x, target_air_velocity, 0.2)

	var box_to_interact: RigidBody2D = _check_box()
	# ===== 推/拉箱子逻辑 =====
	if current_on_floor and box_to_interact is RigidBody2D:
		var has_input = abs(input_dir) > 0.1
		var mouse_held = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

		if mouse_held and has_input:
			var facing_dir = _check_facing_dir()
			
			var target_vel_x: float = 0.0
			# --- 推：前方有箱子 ---
			if sign(input_dir) == facing_dir:
				target_vel_x = speed * facing_dir # 推
			# --- 拉（且输入方向与面朝相反）---
			elif sign(input_dir) == -facing_dir:
				target_vel_x = - speed * facing_dir # 拉
					
			# --- 应用控制 ---
			if box_to_interact:
				is_pushing = true
				box_to_interact.sleeping = false

				# === 新增：背对墙时禁止拉箱子 ===
				var is_pulling = (sign(input_dir) == -facing_dir) # 拉：输入与面朝相反

				if is_pulling:
					# 检测玩家背后是否有墙（距离 8 像素）
					var behind_offset = Vector2(-8 * facing_dir, 0) # 背后方向
					var behind_ray = PhysicsRayQueryParameters2D.new()
					behind_ray.from = global_position
					behind_ray.to = global_position + behind_offset
					behind_ray.exclude = [self]
					behind_ray.collision_mask = 1

					var hit_behind = get_world_2d().direct_space_state.intersect_ray(behind_ray)
					if hit_behind:
						# 背后有墙 → 禁止拉箱子（设目标速度为0）
						target_vel_x = 0.0

				var current_vel_x = box_to_interact.linear_velocity.x
				var new_vel_x = lerp(current_vel_x, target_vel_x, 0.2)
				box_to_interact.linear_velocity = Vector2(new_vel_x, box_to_interact.linear_velocity.y)
			else:
				is_pushing = false
		else:
			is_pushing = false

	# 推/拉箱子时限制玩家速度
	if box_to_interact and current_on_floor:
		velocity.x = box_to_interact.linear_velocity.x * 0.9

	# —— 玩家和平台同步速度 ——
	if is_on_floor():
		var coll = get_last_slide_collision()
		if coll:
			var body = coll.get_collider()
			if body and "current_velocity" in body:
				velocity += body.current_velocity
		
	# 碰撞与移动
	move_and_slide()

	# 攀爬检测
	if not is_climbing and not current_on_floor:
		_try_climb_edge()

	# 动画更新
	if not is_climbing:
		_update_animation(was_on_floor, current_on_floor)

	was_on_floor = current_on_floor

# —————— 动画状态机 ——————
func _update_animation(prev_on_floor: bool, current_on_floor: bool):
	# 检查落地（使用前一帧和当前帧的状态对比）
	if not prev_on_floor and current_on_floor:
		_set_animation("Landing")
		# 等待落地动画完成
		return
	
	# 1. 跳跃动画处理
	if not current_on_floor and velocity.y < 0:
		_set_animation("SideJumpUp" if abs(velocity.x) > 50 else "UpwardJumpUp")
		return
	
	# 2. 下落动画
	if not current_on_floor and velocity.y > 0:
		_set_animation("SideJumpDown" if abs(velocity.x) > 50 else "UpwardJumpDown")
		return
	
	# 3. 移动状态
	var input_dir = _check_input_dir()
	if abs(input_dir) > 0.1:
		# 跑步
		_set_animation("Running")
		# 推拉箱子时不翻转
		if not is_pushing:
			animated_sprite.flip_h = input_dir < 0
		return
	
	_set_animation("Idle")

# —————— 动画管理 ——————
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

# —————— 动画完成回调 ——————
func _on_frame_changed():
	# 检查是否正在播放PlatformJump动画
	if animated_sprite.animation == "PlatformJump":
		var current_frame = animated_sprite.frame
		var total_frames = animated_sprite.sprite_frames.get_frame_count("PlatformJump")
		
		# 检查是否是最后一帧
		if current_frame == total_frames - 1:
			# 设置向上偏移
			animated_sprite.offset = original_offset + Vector2(0, platform_jump_offset)
		# 检查是否是倒数第二帧
		elif current_frame == total_frames - 2:
			# 设置向上偏移
			animated_sprite.offset = original_offset + Vector2(0, platform_jump_offset + 18)
		else:
			# 恢复原始偏移
			animated_sprite.offset = original_offset
	else:
		# 其他动画恢复原始偏移
		animated_sprite.offset = original_offset

func _on_animation_finished():
	var anim_name = animated_sprite.animation # 当前正在播放的动画（即刚完成的）
	if anim_name == "PlatformJump":
		# === 先精确对齐到平台顶部（防止因动画位移不准导致悬空/陷地）===
		var stand_y = climb_target_y
		position.y = stand_y

		# === 再恢复精灵偏移（与位置变化同步，避免视觉卡顿）===
		animated_sprite.offset = original_offset

		# === 恢复碰撞体 ===
		var collider = get_node("PlayerCollider")
		collider.disabled = false

		is_climbing = false
		# 强制刷新一次动画状态（确保回到 Idle 或 Running）
		_update_animation(is_on_floor(), is_on_floor())
	elif anim_name in ["Landing"]:
		_update_animation(was_on_floor, is_on_floor())
	elif anim_name in ["Death"]:
		# 隐藏玩家
		visible = false
		
		# 玩家重生尝试获取当前场景的 LevelManager，如果不存在则报错
		var level_manager = get_tree().get_first_node_in_group("level_manager")
		if level_manager and level_manager.has_method("respawn_player"):
			level_manager.respawn_player()
		else:
			push_error("未找到 LevelManager 节点或 respawn_player 方法！")

# 倒计时开始回调
func _on_pressure_plate_activated(tag: String) -> void:
	if tag == "player":
		gravity_scale = 0.1
		jump_velocity = -100

func _on_countdown_end(tag: String) -> void:
	if tag == "player":
		# 玩家重力恢复
		gravity_scale = 1.0
		jump_velocity = -200

# 玩家朝向检测
func _check_facing_dir():
	return 1 if not animated_sprite.flip_h else -1

func _check_input_dir() -> float:
	return Input.get_axis("move_left", "move_right")

func handle_rope_physics(delta):
	var rope_node = rope_segment.get_parent()
	
	# ===== 1. 检测是否在荡秋千 =====
	var swing_dir = _check_input_dir()
	is_swinging = (swing_dir != 0)
	
	# ===== 2. 处理爬行输入 =====
	var climb_input = 0
	if Input.is_action_pressed("jump"):
		climb_input = -1
	elif Input.is_action_pressed("move_down"):
		climb_input = 1

	# 脱离绳子
	if swing_dir and Input.is_action_just_pressed("jump"):
		climbing = false
		on_rope = false
		velocity.y = jump_velocity * 0.7 # 带初速度脱离
		rope_detach_cooldown = rope_detach_cooldown_time
		return
	
	if climb_input != 0:
		climbing = true
		rope_climb_offset += climb_input * climb_speed * delta
		
		var segment_length = rope_node.segment_length
		
		# 向上爬行
		while rope_climb_offset < -segment_length * 0.5:
			var prev = rope_node.get_prev_segment(rope_segment)
			if prev != rope_segment:
				rope_segment = prev
				rope_climb_offset += segment_length
			else:
				rope_climb_offset = - segment_length * 0.5
				break
		
		# 向下爬行
		while rope_climb_offset > segment_length * 0.5:
			var next = rope_node.get_next_segment(rope_segment)
			if next != rope_segment:
				rope_segment = next
				rope_climb_offset -= segment_length
			else:
				rope_climb_offset = segment_length * 0.5
				break
	else:
		climbing = false
		rope_climb_offset = lerp(rope_climb_offset, 0.0, 5.0 * delta)
	
	# ===== 3. 计算绳子上的逻辑位置 =====
	var current_segment_pos = rope_segment.global_position
	var climb_direction = Vector2.ZERO
	
	if abs(rope_climb_offset) > 0.1:
		if rope_climb_offset < 0: # 向上
			var prev = rope_node.get_prev_segment(rope_segment)
			if prev != rope_segment:
				climb_direction = (prev.global_position - current_segment_pos).normalized()
		else: # 向下
			var next = rope_node.get_next_segment(rope_segment)
			if next != rope_segment:
				climb_direction = (next.global_position - current_segment_pos).normalized()
	
	# 绳子上的挂点位置
	var rope_hang_point = current_segment_pos + climb_direction * abs(rope_climb_offset)
	
	# ===== 4. ✅ 计算绳子的角度和方向（修正） =====
	var rope_direction = Vector2(0, 1) # 默认向下
	var rope_angle = 0.0
	
	# 获取上一段绳子来计算角度
	var prev_segment = rope_node.get_prev_segment(rope_segment)
	if prev_segment != rope_segment:
		# 从上一段指向当前段的方向
		rope_direction = (current_segment_pos - prev_segment.global_position).normalized()
		# ✅ 修正：反转角度（加负号）
		rope_angle = - atan2(rope_direction.x, rope_direction.y)
	else:
		# 如果在最顶端，使用下一段计算
		var next_segment = rope_node.get_next_segment(rope_segment)
		if next_segment != rope_segment:
			rope_direction = (next_segment.global_position - current_segment_pos).normalized()
			# ✅ 修正：反转角度（加负号）
			rope_angle = - atan2(rope_direction.x, rope_direction.y)
	
	# ===== 5. 计算玩家位置（沿着绳子方向向下偏移） =====
	target_position = rope_hang_point + rope_direction * hang_offset_y
	
	# ===== 6. 平滑移动和旋转 =====
	var smoothness = swing_smoothness if is_swinging else position_smoothness
	position = position.lerp(target_position, smoothness * delta)
	
	# 限制旋转角度
	var clamped_angle = clamp(rope_angle, -max_rotation_angle, max_rotation_angle)
	
	# 平滑旋转到绳子的角度
	rotation = lerp_angle(rotation, clamped_angle, rotation_smoothness * delta)
	
	# ===== 7. 应用荡秋千力 =====
	if is_swinging:
		var impulse = Vector2(swing_dir * swing_force, 0)
		rope_segment.apply_impulse(impulse, Vector2.ZERO)
	
	# ===== 8. 动画 =====
	_set_animation("ClimbingLadder" if climbing else "ClimbingRopeIdle")

# 箱子检测
func _check_box():
	var facing_dir = _check_facing_dir()
	var ray_offset_y = - ORIGINAL_FRAME_HEIGHT * SPRITE_SCALE * 0.35
	var from = global_position + Vector2(0, ray_offset_y)
	var to_forward = from + Vector2(box_distance * facing_dir, 0)
	box_ray.from = from
	box_ray.to = to_forward
	box_ray.exclude = [self]
	var res = get_world_2d().direct_space_state.intersect_ray(box_ray)
	if res and res.collider is RigidBody2D:
		return res.collider
	else:
		return null

func take_hit(push_velocity: Vector2) -> void:
	if is_hit:
		return # 防止连击
	is_hit = true
	hit_timer = hit_duration
	velocity = push_velocity # 直接应用击退速度
	# 可选：播放音效、屏幕震动等
	
func _try_climb_edge():
	var space_state = get_world_2d().direct_space_state
	var direction = 1 if animated_sprite.flip_h == false else -1

	var from = global_position
	var to = from + Vector2(climb_check_forward * direction, climb_check_up)

	# 创建爬墙射线查询参数
	climb_ray.from = from
	climb_ray.to = to

	var result = space_state.intersect_ray(climb_ray)

	if result and result["collider"].is_in_group("Rope") and rope_detach_cooldown <= 0:
		print("检测到绳子")
		attach_to_rope(result.collider)
		return

	# 攀爬的对象只能是TileMap，玩家下落的时候才检测
	if ((result and result["collider"] is TileMapLayer) or
	(result and result["collider"].is_in_group("fragibridge")) or
	(result and result["collider"].is_in_group("moveplate"))) and velocity.y > 0:
		var input_dir = _check_input_dir() # -1 ～ 1

		# 检查输入方向是否与平台方向一致
		if direction > 0 and input_dir <= 0:
			return # 面朝右但没按右/按左 → 不爬
		if direction < 0 and input_dir >= 0:
			return # 面朝左但没按左/按右 → 不爬
		var ledge_pos = result.position
		var stand_y = ledge_pos.y + climb_stand_offset

		var stand_pos = Vector2(ledge_pos.x, stand_y)

		# 检查站立区域是否空旷
		var scaled_width = ORIGINAL_FRAME_WIDTH * SPRITE_SCALE
		var scaled_height = ORIGINAL_FRAME_HEIGHT * SPRITE_SCALE

		var shape = RectangleShape2D.new()
		shape.size = Vector2(scaled_width * 0.8, scaled_height * 0.9)

		var shape_query = PhysicsShapeQueryParameters2D.new()
		# 注意：角色底部在 stand_y，所以形状中心要上移一半高度f
		var shape_center = Vector2(stand_pos.x, stand_y - shape.size.y / 2)
		shape_query.transform = Transform2D(0, shape_center)
		shape_query.shape = shape
		shape_query.collision_mask = collision_mask
		shape_query.exclude = [self]

		var collisions = space_state.intersect_shape(shape_query)
		if collisions.is_empty():
			climb_target_y = stand_y + 3
			_start_climb(Vector2(stand_pos.x, stand_y))

func attach_to_rope(segment: RigidBody2D):
	rope_detach_cooldown = 0.0
	on_rope = true
	rope_segment = segment
	climbing = false

func _start_climb(ledge_pos: Vector2):
	# 计算抓取位置（视觉起始点）
	var hand_offset_from_center = 80.0
	var grab_y = ledge_pos.y + hand_offset_from_center * SPRITE_SCALE
	position = Vector2(ledge_pos.x, grab_y)

	# 开始攀爬禁用碰撞体
	var collider = get_node("PlayerCollider")
	collider.disabled = true

	is_climbing = true
	velocity = Vector2.ZERO

	_set_animation("PlatformJump")
