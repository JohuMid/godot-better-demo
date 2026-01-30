extends Node2D

signal activated
signal deactivated

# --- 可配置的属性 ---
@export var bounce_speed: float = 200.0
@export var vertical_bounce: float = 50.0  # 可选：轻微向上弹跳，增强打击感
@export var cooldown_time: float = 0.3     # 防止连续触发（可选）

# --- 内部状态变量 ---
var object_count: int = 0
var animation_player: AnimationPlayer
var recently_hit: Dictionary = {}  # 记录最近被击中的对象和时间

# --- 节点引用 ---
@onready var detector: Area2D = $Detector
@onready var visual: Node2D = $Visual

func _ready() -> void:
	animation_player = $AnimationPlayer
	if animation_player:
		animation_player.play("idle")
	detector.body_entered.connect(_on_body_entered)
	detector.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	# 清理过期的冷却记录（可选优化）
	for body in recently_hit.keys():
		if recently_hit[body] + cooldown_time < Time.get_ticks_msec() / 1000.0:
			recently_hit.erase(body)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D or body is RigidBody2D:
		object_count += 1
		if object_count == 1:
			activate()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D or body is RigidBody2D:
		object_count = max(object_count - 1, 0)
		if object_count == 0:
			deactivate()

func activate() -> void:
	print("Activated!")
	
	# 处理所有当前重叠的角色
	for body in detector.get_overlapping_bodies():
		if body is CharacterBody2D:
			_process_body(body)
		elif body is RigidBody2D:
			_process_rigid_body(body)
	
	emit_signal("activated")

func _process_rigid_body(body: RigidBody2D) -> void:
	body.linear_velocity.y = -bounce_speed * 2
	print("Activated!")
	emit_signal("activated")
	pass

func _process_body(body: CharacterBody2D) -> void:
	if recently_hit.has(body):
		return
	recently_hit[body] = Time.get_ticks_msec() / 1000.0

	var direction = (body.global_position - global_position).normalized()
	if direction.length() == 0:
		direction = Vector2.RIGHT

	var push_vel = direction * bounce_speed
	if vertical_bounce > 0:
		push_vel.y -= vertical_bounce

	# 调用玩家的受击接口
	if body.has_method("take_hit"):
		body.take_hit(push_vel)
	else:
		# 兜底：直接设 velocity（但会被覆盖）
		body.velocity = push_vel

func deactivate() -> void:
	print("Deactivated!")
	emit_signal("deactivated")
