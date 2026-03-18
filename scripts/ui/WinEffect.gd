# res://scenes/WinEffect.gd
extends Control

@onready var animation_player = $AnimationPlayer
var can_process_input = false

func _ready():
	visible = false
	EventManager.subscribe(EventNames.END_GAME, Callable(self, "_trigger_win"))

	animation_player.animation_finished.connect(_on_win_animation_finished, CONNECT_ONE_SHOT)

func _trigger_win():
	visible = true
	animation_player.play("win_effect")

# 动画结束时触发
func _on_win_animation_finished(anim_name):
	can_process_input = true

# 拦截所有输入事件（键盘、鼠标、手柄等）
func _input(event):
	if not visible:
		return
	
	# 检测“按下”动作（避免长按重复触发）
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		if event.is_pressed() and can_process_input:
			DataManager.set_current_level(0)
			EventManager.emit(EventNames.RESTART_GAME, [])
			# 跳转到主菜单
			get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
