# MovingPlatform.gd
extends StaticBody2D

@export var move_offset: Vector2 = Vector2(100, 0)
@export var speed: float = 60.0
@export var move_node: Node2D = null

# 新增：用于玩家同步的平台速度
var current_velocity: Vector2 = Vector2.ZERO

var original_position: Vector2
var current_tween: Tween
var prev_global_position: Vector2

@onready var pressure_plate = get_node("../PressurePlate")

func _ready():
	add_to_group("moveplate")
	original_position = global_position
	prev_global_position = global_position

	if not move_node:
		move_node = self

	if pressure_plate:
		pressure_plate.activated.connect(on_activated)
		pressure_plate.deactivated.connect(on_deactivated)
	else:
		push_error("未找到 PressurePlate 节点！")

func _physics_process(delta):
	# 每帧计算平台的瞬时速度（用于玩家同步）
	# 注意：即使使用 Tween，global_position 也会被插值更新
	current_velocity = (global_position - prev_global_position) / delta
	prev_global_position = global_position

func on_activated():
	_stop_current_tween()
	
	var target = original_position + move_offset
	var distance = global_position.distance_to(target)
	if distance <= 0.01:
		current_velocity = Vector2.ZERO
		return
	
	var duration = distance / speed
	current_tween = create_tween()
	current_tween.tween_property(move_node, "global_position", target, duration)
	current_tween.set_trans(Tween.TRANS_LINEAR)

func on_deactivated():
	_stop_current_tween()
	
	var distance = global_position.distance_to(original_position)
	if distance <= 0.01:
		current_velocity = Vector2.ZERO
		return
	
	var duration = distance / speed
	current_tween = create_tween()
	current_tween.tween_property(move_node, "global_position", original_position, duration)
	current_tween.set_trans(Tween.TRANS_LINEAR)

func _stop_current_tween():
	if current_tween and current_tween.is_running():
		current_tween.stop()
