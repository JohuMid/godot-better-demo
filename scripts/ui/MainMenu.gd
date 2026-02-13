extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var start_button = $HBoxContainer/StartButton
	var resume_button = $HBoxContainer/ResumeButton
	var select_button = $HBoxContainer/SelectButton
	var quit_button = $HBoxContainer/QuitButton
	# 绑定按钮点击事件
	start_button.pressed.connect(_on_start_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	select_button.pressed.connect(_on_select_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)


# 开始按钮点击事件处理函数
func _on_start_button_pressed() -> void:
	# 加载游戏场景MainGame.tscn
	get_tree().change_scene_to_file("res://scenes/core/MainGame.tscn")

# 继续按钮点击事件处理函数
func _on_resume_button_pressed() -> void:
	print("继续游戏！")

# 选择按钮点击事件处理函数
func _on_select_button_pressed() -> void:
	# 加载关卡选择场景LevelSelector.tscn
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelector.tscn")


# 退出按钮点击事件处理函数
func _on_quit_button_pressed() -> void:
	print("退出游戏！")
	get_tree().quit()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
