# res://scripts/AudioManager.gd
extends Node

var bgm_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_channels = 8

@export var master_volume: float = 1.0
@export var bgm_volume: float = 0.7
@export var sfx_volume: float = 0.8

var audio_db: Dictionary = {}
var current_bgm_key: String = ""

# 音频目录（可按需修改）
const BGM_DIR = "res://resources/audio/bgm/"
const SFX_DIR = "res://resources/audio/sfx/"

func _ready():
	_setup_audio_players()
	_load_audio_from_folders()
	_apply_volumes()

func _apply_volumes():
	# Godot 的总线音量需通过 AudioServer 设置
	# 假设你有 "Master", "Music", "SFX" 总线
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 0)   # BGM 自身控制
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), 0)     # SFX 自身控制

func _setup_audio_players():
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	bgm_player.connect("finished", Callable(self, "_on_bgm_finished"))
	add_child(bgm_player)

	for i in range(max_sfx_channels):
		var player = AudioStreamPlayer.new()
		player.bus = "Sfx"
		player.connect("finished", Callable(self, "_on_sfx_finished").bind(player))
		add_child(player)
		sfx_players.append(player)

func _on_bgm_finished():
	if current_bgm_key != "" and audio_db.has(current_bgm_key):
		# 重新播放当前 BGM（无淡入淡出，直接循环）
		bgm_player.stream = audio_db[current_bgm_key]
		bgm_player.volume_db = linear_to_db(bgm_volume)
		bgm_player.play()

# ✅ 自动从文件夹加载所有音频
func _load_audio_from_folders():
	_load_audio_dir(BGM_DIR, "bgm")
	_load_audio_dir(SFX_DIR, "sfx")

func _load_audio_dir(path: String, prefix: String = ""):
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		push_warning("Audio dir not found: %s" % path)
		return

	var da = DirAccess.open(path)
	if da == null:
		return

	da.list_dir_begin()
	var file_name = da.get_next()
	while file_name != "":
		if da.current_is_dir():
			file_name = da.get_next()
			continue

		# 支持 .wav .ogg .mp3 等
		if file_name.get_extension().to_lower() in ["wav", "ogg", "mp3"]:
			var key = file_name.get_basename().to_lower()
			if prefix != "":
				key = "%s/%s" % [prefix, key]  # 如 "sfx/jump"
			var full_path = path + file_name
			audio_db[key] = ResourceLoader.load(full_path)
			if audio_db[key] == null:
				push_error("Failed to load audio: %s" % full_path)
		file_name = da.get_next()

# ========================
# 公共接口
# ========================

func play_bgm(key: String, fade_time: float = 1.0):
	# 如果正在播放BGM，不执行操作
	if bgm_player.playing and bgm_player.stream == audio_db[key]:
		return
		
	# 支持直接传 "level1" 或 "bgm/level1"
	var full_key = key if key.begins_with("bgm/") else "bgm/%s" % key
	if not audio_db.has(full_key):
		push_warning("BGM not found: %s (available: %s)" % [full_key, audio_db.keys()])
		return

	if bgm_player.playing:
		create_tween().tween_property(bgm_player, "volume_db", -80, fade_time) \
			.set_trans(Tween.TRANS_LINEAR) \
			.set_on_completion(_switch_bgm.bind(full_key, fade_time))
	else:
		_switch_bgm(full_key, fade_time)

func _switch_bgm(key: String, fade_time: float):
	current_bgm_key = key
	bgm_player.stream = audio_db[key]
	bgm_player.volume_db = linear_to_db(bgm_volume)
	bgm_player.play()
	if fade_time > 0:
		bgm_player.volume_db = -80
		create_tween().tween_property(bgm_player, "volume_db", linear_to_db(bgm_volume), fade_time)

func play_sfx(key: String, pitch_scale: float = 1.0):
	var full_key = key if key.begins_with("sfx/") else "sfx/%s" % key
	if not audio_db.has(full_key):
		push_warning("SFX not found: %s" % full_key)
		return

	for player in sfx_players:
		if not player.playing:
			player.stream = audio_db[full_key]
			player.pitch_scale = pitch_scale
			player.volume_db = linear_to_db(sfx_volume)
			player.play()
			return

	# 全忙时强制替换第一个
	sfx_players[0].stop()
	sfx_players[0].stream = audio_db[full_key]
	sfx_players[0].pitch_scale = pitch_scale
	sfx_players[0].volume_db = linear_to_db(sfx_volume)
	sfx_players[0].play()

# ========================
# 音量控制
# ========================

func set_master_volume(vol: float):
	master_volume = clamp(vol, 0, 1)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))

func set_bgm_volume(vol: float):
	bgm_volume = clamp(vol, 0, 1)
	if bgm_player and bgm_player.stream:
		bgm_player.volume_db = linear_to_db(bgm_volume)

func set_sfx_volume(vol: float):
	sfx_volume = clamp(vol, 0, 1)

func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0
	return log(linear) * 8.685889638

func _on_sfx_finished(player: AudioStreamPlayer):
	player.stop()
