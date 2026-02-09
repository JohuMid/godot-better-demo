extends StaticBody2D

var original_position: Vector2

@export var move_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 保存原始位置
	original_position = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func on_activated() -> void:
	print("Moveplate Activated!")

func on_deactivated() -> void:
	print("Moveplate Deactivated!")
