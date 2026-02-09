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
	spawn_player()

func spawn_player():
	var level0 = load_and_ensure_level(0)
	var spawn_point = level0.find_child("PlayerSpawn", true, false)
	var pos = spawn_point.global_position if spawn_point else Vector2(100, 200)
	
	player = player_scene.instantiate()
	player.global_position = pos
	add_child(player)

	# 初始时设置当前关卡并加载窗口
	current_player_level = 0
	load_and_ensure_level(1)
	update_level_window()


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
