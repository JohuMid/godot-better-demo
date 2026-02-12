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

func _ready():
	add_to_group("moveplate")
	original_position = global_position
	prev_global_position = global_position

	if not move_node:
		move_node = self

	EventManager.subscribe(EventNames.PRESSURE_PLATE_ACTIVATED, Callable(self, "_on_pressure_plate_activated"))
	EventManager.subscribe(EventNames.PRESSURE_PLATE_DEACTIVATED, Callable(self, "_on_pressure_plate_deactivated"))

func _physics_process(delta):
	# 每帧计算平台的瞬时速度（用于玩家同步）
	# 注意：即使使用 Tween，global_position 也会被插值更新
	current_velocity = (global_position - prev_global_position) / delta
	prev_global_position = global_position

func _on_pressure_plate_activated(tag: String):
	print('tag',tag)
	if "moveplate" != tag:
		return
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

func _on_pressure_plate_deactivated(tag: String):
	if "moveplate" != tag:
		return
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
