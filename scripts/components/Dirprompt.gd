extends Node

# 定义四个信号，分别对应上下左右输入
signal input_up
signal input_down
signal input_left
signal input_right

var is_can_control = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_can_control:
		return
	# 检测上下左右输入，一直按着一直触发信号
	if Input.is_action_pressed("up"):
		self.input_up.emit()
		print("检测到上输入")
	elif Input.is_action_pressed("down"):
		self.input_down.emit()
		print("检测到下输入")
	elif Input.is_action_pressed("left"):
		self.input_left.emit()
		print("检测到左输入")
	elif Input.is_action_pressed("right"):
		self.input_right.emit()
		print("检测到右输入")
