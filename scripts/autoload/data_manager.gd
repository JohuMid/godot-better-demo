# DataManager.gd
extends Node

# --- 数据结构 ---
var save_data = {
	"current_level": 0,
	"unlocked_level": 0,        # 已解锁关卡
	"achievements": {},            # 成就字典，如 {"found_secret": true}
	"sound_enabled": true,
	"music_volume": 0.8,
    "death_count": 0
}

# --- 文件路径 ---
const SAVE_FILE = "user://savegame.json"

# --- 初始化 ---
func _ready():
	load_data()

# --- 公共 API：安全读写 ---
func get_current_level() -> int:
	return save_data.current_level

func get_unlock_level() -> int:
	return save_data.unlocked_level

func set_current_level(level: int):
	save_data.current_level = level
	save()

func unlock_level(level: int):
	save_data.unlocked_level = max(save_data.unlocked_level, level)
	save()

func is_level_unlocked(level: int) -> bool:
	return save_data.unlocked_level >= level

func complete_achievement(key: String):
	if not save_data.achievements.has(key):
		save_data.achievements[key] = true
		save()

func has_achievement(key: String) -> bool:
	return save_data.achievements.get(key, false)

# --- 核心：加载与保存 ---
func load_data():
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found. Using default data.")
		return
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(content)
		
		if parse_result == OK:
			save_data = json.data.duplicate(true)  # 深拷贝
			print("Save data loaded successfully.")
		else:
			push_error("Failed to parse save file: %s" % json.get_error_message())
	else:
		push_error("Failed to open save file for reading.")

func save():
	DirAccess.make_dir_recursive_absolute("user://")
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(save_data, "\t")  # 格式化缩进
		file.store_string(json_str)
		file.close()
		print("Game saved.")
	else:
		push_error("Failed to save game!")

# --- 调试用：重置存档 ---
func reset_save():
	save_data = {
		"current_level": 0,
		"unlocked_levels": 0,
		"achievements": {},
		"sound_enabled": true,
		"music_volume": 0.8,
        "death_count": 0
	}
	save()