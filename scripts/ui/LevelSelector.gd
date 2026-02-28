# LevelSelector.gd
extends Control

const FADE_DURATION = 0.2
var is_switching = false
var current_level_index: int = 0
var center_image
var close_selector
var back_home
var level_lock
var reset_game

@export var level_textures: Array[Texture2D]  # 在编辑器中拖入3张图

func _ready():
	if level_textures.size() == 0:
		push_warning("请在 Inspector 中为 level_textures 赋值！")
		return
	center_image = $Panel/CenterImage
	level_lock = $Panel/LevelLock
	close_selector = $HBoxContainer/CloseSelector
	close_selector.pressed.connect(_on_close_selector_pressed)
	back_home = $HBoxContainer/BackHome
	back_home.pressed.connect(_on_back_home_pressed)
	reset_game = $HBoxContainer/ResetGame
	reset_game.pressed.connect(_on_reset_game_pressed)
	

	center_image.modulate.a = 1.0  # 确保初始可见

	var timer = get_tree().create_timer(0.05)  # 50 毫秒足够 UI 布局完成
	timer.timeout.connect(_initialize_ui)

	_update_level_lock(0)

	# center_image点击跳转到对应关卡
	center_image.pressed.connect(_on_center_image_pressed)

	EventManager.subscribe(EventNames.SHOW_LEVEL_SELECTOR, Callable(self, "_show_level_selector"))

# 显示关卡选择器
func _show_level_selector(show: bool):
	print("显示关卡选择器")
	visible = show
	center_image.modulate.a = 0.0  # 初始透明
	level_lock.modulate.a = 0.0  # 初始透明

	# 淡入效果
	var tween = create_tween()
	tween.tween_property(center_image, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_property(level_lock, "modulate:a", 1.0, FADE_DURATION)

# center_image点击事件处理函数
func _on_center_image_pressed():
	# 跳转到对应关卡
	print("跳转到关卡 %d" % current_level_index)
	visible = false
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager.update_level_window_index(current_level_index)

# 关闭关卡选择器按钮点击事件处理函数
func _on_close_selector_pressed():
	visible = false

# 回主菜单按钮点击事件处理函数
func _on_back_home_pressed():
	visible = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

# 重置游戏按钮点击事件处理函数
func _on_reset_game_pressed():
	DataManager.reset_save()
	visible = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

# 定时器触发后调用此函数
func _initialize_ui():
	_update_center_image()
	_create_indicator_buttons()

func _create_indicator_buttons():
	var hbox = $IndicatorBox
	
	# 删除所有子节点
	for child in hbox.get_children():
		child.queue_free()

	for i in range(level_textures.size()):
		var btn = Button.new()
		btn.name = "LevelBtn" + str(i)

		# 设置最小尺寸
		btn.custom_minimum_size = Vector2(6, 6)
		btn.focus_mode = Control.FOCUS_NONE  # 点击无焦点框

		# 正常状态：半透明白色圆点
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(1, 1, 1, 0.5)  # 半透明白色
		normal_style.set_corner_radius_all(12)  # 设置圆角半径为宽度/2以形成圆形
		btn.add_theme_stylebox_override("normal", normal_style)

		# 悬停状态：不透明白色
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(1, 1, 1, 1)  # 白色
		hover_style.set_corner_radius_all(12)
		btn.add_theme_stylebox_override("hover", hover_style)

		# 按下状态：浅灰色
		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.8, 0.8, 0.8, 1)  # 浅灰色
		pressed_style.set_corner_radius_all(12)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		# 绑定点击事件
		btn.pressed.connect(_on_level_button_pressed.bind(i))

		hbox.add_child(btn)

	# 初始选中第一个
	_set_button_selected(0)

func _on_level_button_pressed(index: int):
	if index == current_level_index or is_switching:
		return
	is_switching = true
	current_level_index = index
	_set_button_selected(index)
	_switch_to_level_with_fade(index)
	_change_level_index_text(index)

func _change_level_index_text(index: int):
	$HBoxContainer/LevelIndex.text = str(index + 1)

func _switch_to_level_with_fade(target_index: int):
	var tween = create_tween()
	var img = center_image

	tween.tween_property(img, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func(): 
		img.texture_normal = level_textures[target_index]
		img.custom_minimum_size = img.texture_normal.get_size()
	)
	tween.tween_property(img, "modulate:a", 1.0, FADE_DURATION)
	tween.finished.connect(func(): is_switching = false)

	_update_level_lock(target_index)

func _update_center_image():
	center_image.texture_normal = level_textures[current_level_index]
	center_image.custom_minimum_size = center_image.texture_normal.get_size()

func _set_button_selected(selected_index: int):
	for i in range($IndicatorBox.get_child_count()):
		var btn = $IndicatorBox.get_child(i)
		
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(6)  # 注意：按钮尺寸是 12x12，半径应为 6
		
		if i == selected_index:
			style.bg_color = Color(1, 1, 1, 1)   # 选中：不透明
		else:
			style.bg_color = Color(1, 1, 1, 0.5) # 未选中：半透明

		btn.add_theme_stylebox_override("normal", style)


func _update_level_lock(target_index: int):
	level_lock.visible = target_index > DataManager.save_data.unlocked_level
