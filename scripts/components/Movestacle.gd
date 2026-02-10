extends StaticBody2D

@export var dir_prompt:Node2D
var current_velocity:Vector2 = Vector2.ZERO
var prev_global_position:Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 链接信号
	# signal input_up
	# signal input_down
	# signal input_left
	# signal input_right
	dir_prompt.input_up.connect(_on_input_up)
	dir_prompt.input_down.connect(_on_input_down)
	dir_prompt.input_left.connect(_on_input_left)
	dir_prompt.input_right.connect(_on_input_right)

func _physics_process(delta):
	current_velocity = (global_position - prev_global_position) / delta
	prev_global_position = global_position

func _on_input_up() -> void:
	# 向上均速移动
	self.position.y -= 1

func _on_input_down() -> void:
	# 向下移动
	self.position.y += 1

func _on_input_left() -> void:
	# 向左移动
	self.position.x -= 1

func _on_input_right() -> void:
	# 向右移动
	self.position.x += 1
