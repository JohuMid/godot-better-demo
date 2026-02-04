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
	if body is CharacterBody2D:
		object_count += 1
		if object_count == 1:
			print("Activated!")
			animation_player.play("attack")
			var facing = 1 if body.position.x > position.x else -1
			body.take_hit(Vector2(50 * facing, 0))

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		object_count -= 1
		object_count = max(object_count, 0)
		if object_count == 0:
			print("Deactivated!")
			emit_signal("deactivated")
