# auto_move_plate.gd
extends Node2D

@export var travel_offset: Vector2 = Vector2(200, 0)  # 移动偏移量（相对于原始位置）
@export var start_from_end: bool = false               # 是否从终点开始
@export var speed: float = 80.0                        # 像素/秒
@export var wait_time: float = 0.0                     # 到达端点后等待时间（秒）

var original_position: Vector2
var point_a: Vector2  # 起点
var point_b: Vector2  # 终点
var target_position: Vector2
var current_wait: float = 0.0
var moving_to_b: bool = true  # 当前是否正前往 point_b

var current_velocity: Vector2 = Vector2.ZERO
var prev_global_position: Vector2 = Vector2.ZERO

func _ready():
	original_position = global_position
	
	# 定义路径两端
	point_a = original_position
	point_b = original_position + travel_offset
	
	# 根据 start_from_end 决定初始位置和方向
	if start_from_end:
		global_position = point_b
		target_position = point_a
		moving_to_b = false
	else:
		global_position = point_a
		target_position = point_b
		moving_to_b = true


func _process(delta):
	current_velocity = (global_position - prev_global_position) / delta
	prev_global_position = global_position

	if current_wait > 0:
		current_wait -= delta
		return
	
	# 如果到达目标，切换方向
	if global_position.distance_to(target_position) < 1.0:
		global_position = target_position  # 吸附，避免抖动
		
		# 切换目标
		if moving_to_b:
			target_position = point_a
			moving_to_b = false
		else:
			target_position = point_b
			moving_to_b = true
		
		# 开始等待（如果设置了）
		current_wait = wait_time
		return
	
	# 匀速移动
	var dir = (target_position - global_position).normalized()
	global_position += dir * speed * delta