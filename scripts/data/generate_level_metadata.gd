# generate_level_metadata.gd
# 关卡数据生成脚本
@tool
extends EditorScript

const LEVELS_DIR = "res://scenes/levels/"
const OUTPUT_PATH = "res://scripts/data/level_metadata.gd"

func _run():
	var dir = DirAccess.open(LEVELS_DIR)
	if not dir:
		push_error("❌ 目录不存在: %s" % LEVELS_DIR)
		return

	var entries = []
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if file.begins_with("Level") and file.ends_with(".tscn"):
			var id_str = file.trim_prefix("Level").trim_suffix(".tscn")
			if id_str.is_valid_int():
				entries.append({ "id": int(id_str), "path": LEVELS_DIR + file })
		file = dir.get_next()
	dir.list_dir_end()

	if entries.is_empty():
		push_warning("⚠️ 未找到 Level*.tscn")
		return

	entries.sort_custom(func(a, b): return a.id < b.id)

	var lines = [
		"# AUTO-GENERATED from RightEdge Marker2D",
		"extends Resource\n",
		"const LEVELS = {"
	]

	for e in entries:
		var width = get_level_width_from_right_edge(e.path)
		lines.append('\t%d: { "width": %.1f, "path": "%s" },' % [e.id, width, e.path])
		print("📊 Level%d → %.1f px (from RightEdge)" % [e.id, width])

	lines.append("}\n")

	var f = FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if f:
		for line in lines: f.store_line(line)
		f.close()
		print("✅ 成功生成: %s" % OUTPUT_PATH)
		EditorInterface.get_resource_filesystem().scan()

# --------------------------------------------------
# 从关卡场景的 RightEdge Marker2D 获取宽度
# --------------------------------------------------
func get_level_width_from_right_edge(scene_path: String) -> float:
	var scene = ResourceLoader.load(scene_path)
	if not scene or not scene is PackedScene:
		push_error("无法加载: %s" % scene_path)
		return 1000.0

	var root = scene.instantiate()
	if not root:
		return 1000.0

	# 查找直接子节点中的 RightEdge（不递归）
	var right_edge = null
	for child in root.get_children():
		if child.name == "RightEdge" and child is Marker2D:
			right_edge = child
			break

	var width = 1000.0
	if right_edge:
		width = right_edge.position.x
	else:
		push_warning("⚠️ 未找到 RightEdge，使用默认宽度 1000: %s" % scene_path)

	root.queue_free()
	return width
