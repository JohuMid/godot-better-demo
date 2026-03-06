extends Node

@export var key: String
@export var img_completed: Texture2D
@export var label_name: String
@export var completed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var img = $TextureRect
	img.texture = img_completed
	if not completed:
		img.modulate = Color(0.1, 0.1, 0.1, 1)

	var label = $Label
	label.text = label_name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# completed改变时更新显示
func set_completed(value: bool):
	print("设置成就 %s 完成状态为 %s" % [label_name, value])
	completed = value
	var img = $TextureRect
	if completed:
		img.modulate = Color(1, 1, 1, 1)
	else:
		img.modulate = Color(0.1, 0.1, 0.1, 1)

func update_text():
	if key:
		$Label.text = DataManager.get_achievement_name(key)
