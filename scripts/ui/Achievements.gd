extends Control

var grid_container
var close_btn

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_container = $GridContainer

	close_btn = $HBoxContainer/CloseBtn
	close_btn.pressed.connect(_on_close_btn_pressed)

	EventManager.subscribe(EventNames.SHOW_ACHIEVEMENTS, Callable(self, "_show_achievements"))
	EventManager.subscribe(EventNames.UPDATE_ACHIEVEMENTS, Callable(self, "_update_achievements"))
	EventManager.subscribe(EventNames.TRANSLATION_CHANGED, Callable(self, "_update_translation"))

	_create_achievement_items()
	

func _create_achievement_item(key: String, name: String, completed: bool, img_completed: Texture2D):
	var item = load("res://scenes/ui/AchievementItem.tscn").instantiate()
	item.set("key", key)
	item.set("img_completed", img_completed)
	item.set("name", name)
	item.set("label_name", name)
	item.set("completed", completed)
	grid_container.add_child(item)

func _create_achievement_items():
	for key in DataManager.get_achievements():
		var img_name = "res://resources/gui/achievements/" + key + ".png"
		var img_completed = load(img_name)
		_create_achievement_item(key, DataManager.get_achievement_name(key), DataManager.get_achievement_completed(key), img_completed)

func _show_achievements(show: bool):
	print("显示成就界面")
	visible = show

func _update_achievements(name: String):
	for item in grid_container.get_children():
		print(item.key, name, item)
		if item.key == name:
			item.set_completed(DataManager.get_achievement_completed(name))
			break

func _update_translation():
	for item in grid_container.get_children():
		if item.has_method("update_text"):
			item.update_text()

func _on_close_btn_pressed():
	hide()
