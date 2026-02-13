extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 创建 CanvasLayer 用于显示 UI
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

	# 加载 MainMenu 场景
	var main_menu_scene = preload("res://scenes/ui/MainMenu.tscn")
	var main_menu_instance = main_menu_scene.instantiate()
	canvas_layer.add_child(main_menu_instance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
