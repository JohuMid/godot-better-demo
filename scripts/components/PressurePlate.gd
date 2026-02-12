extends Node2D

# --- 可配置的属性 --
@export var trigger_tags: Array[String] = []

var pressed_distance: float = 2.0
var move_speed: float = 200.0

# --- 内部状态变量 ---
var is_pressed: bool = false
var object_count: int = 0
var target_position: Vector2

# --- 节点引用 ---
@onready var detector: Area2D = $Detector
@onready var visual: Node2D = $Visual
@onready var original_visual_position: Vector2 = visual.position # <--- 视觉节点的初始局部位置

func _ready() -> void:
	# 初始化目标位置为视觉节点的初始位置
	target_position = original_visual_position

	# 连接检测器的信号到本脚本的函数
	detector.body_entered.connect(_on_body_entered)
	detector.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	# 移动的是 visual 节点，而不是根节点
	if visual.position.distance_to(target_position) > 1.0:
		visual.position = visual.position.move_toward(target_position, move_speed * delta)
	else:
		visual.position = target_position

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
	if is_pressed:
		return

	is_pressed = true
	# 目标位置是相对于 visual 节点的父节点 (PressurePlate) 的局部位置
	target_position = original_visual_position + Vector2(0, pressed_distance)
	print("Pressure Plate Activated!")
	for tag in trigger_tags:
		EventManager.emit(EventNames.PRESSURE_PLATE_ACTIVATED, [tag])

func deactivate() -> void:
	if not is_pressed:
		return

	is_pressed = false
	target_position = original_visual_position
	print("Pressure Plate Deactivated!")
	for tag in trigger_tags:
		EventManager.emit(EventNames.PRESSURE_PLATE_DEACTIVATED, [tag])
