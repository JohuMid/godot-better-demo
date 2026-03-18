extends Node

# 定义四个信号，分别对应上下左右输入
signal input_up
signal input_down
signal input_left
signal input_right

var is_can_control = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var up_sprite = $Up/Up
	var down_sprite = $Down/Down
	var left_sprite = $Left/Left
	var right_sprite = $Right/Right

	up_sprite.pressed.connect(_on_up_sprite_pressed)
	down_sprite.pressed.connect(_on_down_sprite_pressed)
	left_sprite.pressed.connect(_on_left_sprite_pressed)
	right_sprite.pressed.connect(_on_right_sprite_pressed)

func _on_up_sprite_pressed() -> void:
	self.input_up.emit('click')
	print("检测到上输入")

func _on_down_sprite_pressed() -> void:
	self.input_down.emit('click')
	print("检测到下输入")
		
func _on_left_sprite_pressed() -> void:
	self.input_left.emit('click')
	print("检测到左输入")

func _on_right_sprite_pressed() -> void:
	self.input_right.emit('click')
	print("检测到右输入")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_can_control:
		return
	# 检测上下左右输入，一直按着一直触发信号
	if Input.is_action_pressed("up"):
		self.input_up.emit('press')
		print("检测到上输入")
	elif Input.is_action_pressed("down"):
		self.input_down.emit('press')
		print("检测到下输入")
	elif Input.is_action_pressed("left"):
		self.input_left.emit('press')
		print("检测到左输入")
	elif Input.is_action_pressed("right"):
		self.input_right.emit('press')
		print("检测到右输入")
