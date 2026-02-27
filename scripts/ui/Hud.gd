extends Node

var LevelSelector: TextureButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LevelSelector = $LevelSelector
	LevelSelector.pressed.connect(_on_level_selector_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# 关卡选择器点击事件处理函数
func _on_level_selector_pressed() -> void:
	EventManager.emit(EventNames.SHOW_LEVEL_SELECTOR, [true])
