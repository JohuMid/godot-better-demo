# res://scripts/level_manager.gd
extends Node2D

@export var player_scene: PackedScene
@export var levels_container: Node2D

var player: CharacterBody2D = null
var current_player_level: int = -1 # 初始化为 -1
var loaded_levels: Dictionary = {}
var level_meta = preload("res://scripts/data/level_metadata.gd").LEVELS

func _ready():
	add_to_group("level_manager")
	initialize_game()

func initialize_game():
	var status = DataManager.get_start_game_status()
	
	if status == "new":
		# 新游戏：重置存档（可选）
		DataManager.reset_save()  # 或只重置关卡相关字段
		start_new_game()
	elif status == "resume":
		# 继续游戏：从存档读取
		start_resume_game()
	else:
		# 默认当新游戏
		start_new_game()

func start_new_game():
	print("🎮 Starting NEW game")
	current_player_level = 0
	DataManager.set_current_level(0)
	DataManager.unlock_level(0)
	
	# 加载初始关卡窗口 [0, 1]
	load_and_ensure_level(0)
	load_and_ensure_level(1)
	
	# 生成玩家
	spawn_player_at_level(0)

func start_resume_game():
	print("🔄 Resuming game from level %d" % DataManager.get_current_level())
	current_player_level = DataManager.get_current_level()
	
	# 确保至少加载 current-1, current, current+1
	for offset in [-1, 0, 1]:
		var lid = current_player_level + offset
		if level_meta.has(lid):
			load_and_ensure_level(lid)
	
	# 生成玩家到当前关卡
	spawn_player_at_level(current_player_level)

# 通用玩家生成函数（替代原来的 spawn_player）
func spawn_player_at_level(level_id: int):
	var spawn_pos: Vector2
	
	if level_id == 0:
		# 第一关使用 PlayerSpawn
		var level0 = load_and_ensure_level(0)
		var spawn_point = level0.find_child("PlayerSpawn", true, false)
		spawn_pos = spawn_point.global_position if spawn_point else Vector2(100, 200)
	else:
		# 其他关卡：放在关卡起始位置
		spawn_pos = Vector2(get_total_width_before(level_id) + 50, 100)
	
	player = player_scene.instantiate()
	player.global_position = spawn_pos
	add_child(player)
	
	print("👤 Player spawned at level %d, pos: %s" % [level_id, spawn_pos])

# 生成指定关卡的窗口
func update_level_window_index(level_id: int = -1):
	# 如果是当前关卡，不做处理
	if level_id == current_player_level:
		return
		
	if level_id < 0:
		level_id = current_player_level
	if level_id < 0 or level_id >= level_meta.size():
		return

	# 确保加载当前关卡和前后各一级
	for i in range(level_id - 1, level_id + 2):
		if i >= 0 and i < level_meta.size():
			load_and_ensure_level(i)
	
	# 生成玩家到当前关卡
	if player:
		player.global_position = Vector2(get_total_width_before(level_id) + 10, 0)

# 玩家重生函数
func respawn_player():
	if not player:
		return
	var spawn_point
	if get_player_level_id() == 0:
		spawn_point = load_and_ensure_level(0).find_child("PlayerSpawn", true, false).global_position
	else:
		# 当前关卡的
		spawn_point = Vector2(get_total_width_before(get_player_level_id()) + 10, 0)

	var pos = spawn_point
	# 镜头缓慢移动到新位置
	var tween = create_tween()
	tween.tween_property(player, "global_position", pos, 0.5)
	# 等待镜头移动完成
	await tween.finished

	player._set_animation("UpwardJumpDown")
	player.visible = true
	player.is_hit = false
	player.hit_timer = 0.0
	player.on_rope = false
	player.rope_segment = null
	player.gravity = 800.0
	player.gravity_scale = 1
	player.jump_velocity = -200.0

	# 卸载当前关卡，重新加载当前关卡
	loaded_levels[current_player_level].queue_free()
	loaded_levels.erase(current_player_level)
	load_and_ensure_level(current_player_level)
	
# 获取玩家当前所在的关卡 ID（基于 x 坐标）
func get_player_level_id() -> int:
	if not player:
		return 0
	var x = player.global_position.x
	var total = 0.0
	for i in level_meta.keys():
		total += level_meta[i]["width"]
		if x < total:
			return i
	return level_meta.size() - 1

# 加载指定关卡（如果未加载）
func load_and_ensure_level(level_id: int) -> Node2D:
	if not level_meta.has(level_id) or loaded_levels.has(level_id):
		return loaded_levels.get(level_id, null)

	var info = level_meta[level_id]
	var scene = ResourceLoader.load(info["path"])
	var instance = scene.instantiate()
	instance.position.x = get_total_width_before(level_id)
	instance.name = "Level_%d" % level_id
	levels_container.add_child(instance)
	loaded_levels[level_id] = instance
	print("✅ 加载关卡 %d at x=%.1f" % [level_id, instance.position.x])
	return instance

func get_total_width_before(target_id: int) -> float:
	var total = 0.0
	for i in range(target_id):
		if level_meta.has(i):
			total += level_meta[i]["width"]
	return total

# 核心：维护 [current-1, current, current+1] 的关卡窗口
func update_level_window():
	var x = player.global_position.x
	var total_before = get_total_width_before(current_player_level)
	var total_after = total_before + level_meta[current_player_level]["width"]

	# 如果还在当前关卡中间区域，不切换
	if x > total_before + 100 and x < total_after - 100:
		return
	
	if not player:
		return

	var new_level = get_player_level_id()
	if new_level == current_player_level:
		return # 未跨关，无需更新

	print("➡️ 进入关卡 %d" % new_level)
	current_player_level = new_level
	DataManager.set_current_level(new_level)
	# 更新已解锁关卡
	DataManager.unlock_level(new_level)

	# 定义要保留的关卡 ID 集合
	var keep_ids = []
	for offset in [-1, 0, 1, 2]:
		var id = current_player_level + offset
		if level_meta.has(id):
			keep_ids.append(id)
			load_and_ensure_level(id) # 确保加载

	# 卸载不在 keep_ids 中的已加载关卡
	var to_unload = []
	for id in loaded_levels.keys():
		if not id in keep_ids:
			to_unload.append(id)

	for id in to_unload:
		print("🗑️ 卸载关卡 %d" % id)
		loaded_levels[id].queue_free()
		loaded_levels.erase(id)

func _process(delta):
	update_level_window()
