# Player.gd
extends CharacterBody2D

# —————— 导出属性（可在编辑器调整）——————
@export var speed: float = 120.0
@export var jump_velocity: float = -200.0
@export var gravity: float = 800.0

# —————— 动画相关 ——————
@export var atlas: Texture2D
@export var json_path: String = "res://resources/player/spritesheet.json"

# —————— 攀爬相关 ——————
@export var climb_check_forward: float = 8.0   # 向前检测距离（像素）
@export var climb_check_up: float = -8.0       # 向上偏移（负值表示向上）
@export var climb_stand_offset: float = -2.0   # 爬上后角色底部应处的 Y 偏移（相对于边缘点）
var climb_target_y: float = 0.0
var is_climbing: bool = false

# —————— 推箱子相关 ——————
var is_pushing: bool = false
@export var push_distance: float = 8.0  # 推箱子距离（像素）
var target_box: RigidBody2D = null
@export var push_force: float = 1000.0  # 推箱子力（像素）

# —————— 动画帧偏移相关 ——————
var original_offset: Vector2 = Vector2.ZERO   # 原始偏移量
var platform_jump_offset: float = -280.0       # PlatformJump最后两帧的向上偏移

# —— 角色原始帧尺寸 ——
const ORIGINAL_FRAME_WIDTH: int = 128
const ORIGINAL_FRAME_HEIGHT: int = 128
const SPRITE_SCALE: float = 0.2

# —— 动画速度配置 ——
const ANIM_SPEED = {
	"Idle": 1.2,         # 慢速站立
	"Walk": 1.2,         # 步行
	"Running": 2.5,      # 跑步
	"SideJumpUp": 3.0,   # 跑跳上升
	"SideJumpDown": 1.0, # 跑跳下降
	"UpwardJumpUp": 5.0, # 原地跳上升
	"UpwardJumpDown": 1.0,# 原地跳下降
	"Landing": 1.7,      # 落地
	"PlatformJump": 2.0,      # 跳跃平台
	"default": 1.0
}

var animated_sprite: AnimatedSprite2D
var was_on_floor: bool = false

# —————— 初始化 ——————
func _ready():
	if not atlas:
		push_error("请在检查器中指定 Atlas 纹理！")
		return

	var frames = TexturePackerImporter.create_sprite_frames(atlas, json_path)
	animated_sprite = $AnimatedSprite2D
	animated_sprite.sprite_frames = frames

	# 设置缩放和对齐（关键！）
	animated_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	animated_sprite.centered = false
	animated_sprite.offset = Vector2(
		-float(ORIGINAL_FRAME_WIDTH) / 2.0,
		-ORIGINAL_FRAME_HEIGHT
	)

	# 存储原始偏移量
	original_offset = animated_sprite.offset

	# 连接动画信号
	animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	animated_sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))
	_create_collision_shape()
	_set_animation("Idle")

# —————— 创建碰撞体 ——————
func _create_collision_shape():
	var scaled_width = ORIGINAL_FRAME_WIDTH * SPRITE_SCALE
	var scaled_height = ORIGINAL_FRAME_HEIGHT * SPRITE_SCALE

	var capsule = CapsuleShape2D.new()
	capsule.radius = scaled_width * 0.15  # 窄碰撞体
	capsule.height = scaled_height * 0.7

	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = capsule
	collision_shape.position = Vector2(0, -scaled_height * 0.35)
	collision_shape.name = "PlayerCollider"
	
	add_child(collision_shape)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_start_push()   # 按下时尝试找箱子
		else:
			is_pushing = false  # 松开就停止

func _try_start_push():
	# 仅在地面上时才尝试推箱子
	if is_on_floor():
		var from = global_position
		var dir = 1 if not animated_sprite.flip_h else -1
		var to = from + Vector2(push_distance * dir, 0)  # 检测推箱子距离

		# 创建射线查询参数（正确方式）
		var ray_params = PhysicsRayQueryParameters2D.new()
		ray_params.from = from
		ray_params.to = to
		ray_params.exclude = [self]
		ray_params.collision_mask = 1  # 根据你的箱子所在层调整

		var space_state = get_world_2d().direct_space_state
		var result = space_state.intersect_ray(ray_params)

		print(result)

		if result and result.collider is RigidBody2D:
			target_box = result.collider
			is_pushing = true
		else:
			is_pushing = false

# —————— 物理处理 ——————
func _physics_process(delta):

	if is_climbing:
		# 保持最小碰撞响应，但不更新速度或位置
		move_and_slide()
		return

	# 1. 保存上一帧的地面状态（关键修复！）
	var current_on_floor = is_on_floor()

	# ===== 推箱子逻辑 =====

	
	# 2. 重力处理
	if not current_on_floor:
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	
	# 3. 跳跃处理
	if Input.is_action_just_pressed("jump") and current_on_floor:
		velocity.y = jump_velocity
		_set_animation("SideJumpUp" if abs(velocity.x) > 50 else "UpwardJumpUp")
	
	# 4. 水平移动
	if current_on_floor:
		var input_dir = Input.get_axis("move_left", "move_right")
		velocity.x = input_dir * speed
	else:
		# 空中保留水平惯性（增加减速系数以获得更好的惯性效果）
		velocity.x = velocity.x * 0.98
		
	# 6. 碰撞处理
	move_and_slide()

	# 攀爬检测
	if not is_climbing and not current_on_floor and velocity.y > 0:  # 下落中
		_try_climb_edge()

	# 7. 动画更新（注意：如果正在攀爬，跳过常规动画）
	if not is_climbing:
		_update_animation(was_on_floor, current_on_floor)
	
	# 8. 更新前一帧地面状态
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
	var input_dir = Input.get_axis("move_left", "move_right")
	if abs(input_dir) > 0.1:
		# 跑步
		_set_animation("Running")
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
		print("▶ 播放动画: %s (速度: %.1f)" % [anim_name, speed_scale])
	else:
		print("⚠️ 动画不存在: %s" % anim_name)

# —————— 动画完成回调 ——————
func _on_frame_changed():
	# 检查是否正在播放PlatformJump动画
	if animated_sprite.animation == "PlatformJump":
		var current_frame = animated_sprite.frame
		var total_frames = animated_sprite.sprite_frames.get_frame_count("PlatformJump")
		
		# 检查是否是最后两帧
		if current_frame >= total_frames - 2:
			# 设置向上偏移
			animated_sprite.offset = original_offset + Vector2(0, platform_jump_offset * SPRITE_SCALE)
		else:
			# 恢复原始偏移
			animated_sprite.offset = original_offset
	else:
		# 其他动画恢复原始偏移
		animated_sprite.offset = original_offset

func _on_animation_finished():
	var anim_name = animated_sprite.animation  # 当前正在播放的动画（即刚完成的）
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

func _try_climb_edge():
	var space_state = get_world_2d().direct_space_state
	var direction = 1 if animated_sprite.flip_h == false else -1

	var from = global_position
	var to = from + Vector2(climb_check_forward * direction, climb_check_up)

	# 创建射线查询参数
	var ray_query = PhysicsRayQueryParameters2D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.exclude = [self]
	ray_query.collision_mask = collision_mask

	var result = space_state.intersect_ray(ray_query)

	if result:
		var input_dir = Input.get_axis("move_left", "move_right")    # -1 ～ 1

		# 检查输入方向是否与平台方向一致
		if direction > 0 and input_dir <= 0:
			return  # 面朝右但没按右/按左 → 不爬
		if direction < 0 and input_dir >= 0:
			return  # 面朝左但没按左/按右 → 不爬
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
			climb_target_y = stand_y
			_start_climb(Vector2(stand_pos.x, stand_y))

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
