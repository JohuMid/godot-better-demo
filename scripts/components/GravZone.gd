extends Area2D

@export var gravity_dir: String = "down"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 监听 body_entered 信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	print("body_entered", body)
	if body.is_in_group("player"):
		# 改变重力方向
		body.change_gravity_scale(gravity_dir)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 恢复重力方向
		body.change_gravity_scale("down")
