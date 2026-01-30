extends Node2D # <--- 脚本现在继承自 Node2D

signal activated   # 压力板被压下（打开通路）
signal deactivated # 压力板释放（关闭通路）

# --- 可配置的属性 ---
@export var bounce_speed: float = 400.0

# --- 内部状态变量 ---
var object_count: int = 0
var animation_player: AnimationPlayer

# --- 节点引用 ---
@onready var detector: Area2D = $Detector
@onready var visual: Node2D = $Visual

func _ready() -> void:
	animation_player = $AnimationPlayer
	# 连接检测器的信号到本脚本的函数
	detector.body_entered.connect(_on_body_entered)
	detector.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D or body is RigidBody2D:
		object_count += 1
		if object_count == 1:
			activate()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D or body is RigidBody2D:
		object_count -= 1
		object_count = max(object_count, 0)
		if object_count == 0:
			deactivate()

func activate() -> void:
	print("Activated!")
	animation_player.play("bounce")
	# 将进入区域的物体向上推动
	for body in detector.get_overlapping_bodies():
		if body is CharacterBody2D:
			body.velocity.y = -bounce_speed
		elif body is RigidBody2D:
			body.linear_velocity.y = -bounce_speed
			print("Activated!")
			emit_signal("activated")

func deactivate() -> void:
	print("Deactivated!")
	emit_signal("deactivated")
