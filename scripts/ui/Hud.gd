extends Node

var LevelSelector: TextureButton
var AchievementsButton: TextureButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LevelSelector = $HBoxContainer/LevelSelector
	LevelSelector.pressed.connect(_on_level_selector_pressed)
	
	AchievementsButton = $HBoxContainer/AchievementsButton
	AchievementsButton.pressed.connect(_on_achievements_pressed)

	# 初始化死亡次数标签
	$HBoxContainer/DeathCount.text = str(DataManager.get_death_count())

	EventManager.subscribe(EventNames.PLAYER_DIED, _on_player_died)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# 关卡选择器点击事件处理函数
func _on_level_selector_pressed() -> void:
	EventManager.emit(EventNames.SHOW_LEVEL_SELECTOR, [true])

# 成就按钮点击事件处理函数
func _on_achievements_pressed() -> void:
	EventManager.emit(EventNames.SHOW_ACHIEVEMENTS, [true])

# 玩家死亡事件处理函数
func _on_player_died() -> void:
	# 增加死亡次数
	var death_count = DataManager.get_death_count()
	DataManager.set_death_count(death_count + 1)

	# 更新死亡次数标签
	$HBoxContainer/DeathCount.text = str(death_count + 1)
