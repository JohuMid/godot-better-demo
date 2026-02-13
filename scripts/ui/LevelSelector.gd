# LevelSelector.gd
extends Control

const FADE_DURATION = 0.2
var is_switching = false
var current_level_index: int = 0

@export var level_textures: Array[Texture2D]  # 在编辑器中拖入3张图

func _ready():
	if level_textures.size() == 0:
		push_warning("请在 Inspector 中为 level_textures 赋值！")
		return

	$CenterImage.modulate.a = 1.0  # 确保初始可见
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

func _switch_to_level_with_fade(target_index: int):
	var tween = create_tween()
	var img = $CenterImage

	tween.tween_property(img, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func(): 
		img.texture = level_textures[target_index]
	)
	tween.tween_property(img, "modulate:a", 1.0, FADE_DURATION)
	tween.finished.connect(func(): is_switching = false)

func _update_center_image():
	$CenterImage.texture = level_textures[current_level_index]

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
