# res://scripts/AudioManager.gd
extends Node

var bgm_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_channels = 8

@export var master_volume: float = 1.0
@export var bgm_volume: float = 0.7
@export var sfx_volume: float = 0.8

@export var bgm_map: Dictionary = {
	"game-bgm": preload("res://resources/audio/bgm/game-bgm.mp3"),
}

@export var sfx_map: Dictionary = {
	"bounce": preload("res://resources/audio/sfx/bounce.wav"),
	"getcoin": preload("res://resources/audio/sfx/getcoin.wav"),
	"level-completed": preload("res://resources/audio/sfx/level-completed.wav"),
	"blood-pop": preload("res://resources/audio/sfx/blood-pop.wav"),
	"peabullet": preload("res://resources/audio/sfx/peabullet.wav"),
	"lizardattack": preload("res://resources/audio/sfx/lizardattack.wav"),
	"bridgebrake": preload("res://resources/audio/sfx/bridgebrake.wav"),
	"boom": preload("res://resources/audio/sfx/boom.wav"),
	"stungun": preload("res://resources/audio/sfx/stungun.wav"),
	"barricade": preload("res://resources/audio/sfx/barricade.wav"),
	"telepad": preload("res://resources/audio/sfx/telepad.wav"),
	"launcher": preload("res://resources/audio/sfx/launcher.wav"),
	"chainsaw": preload("res://resources/audio/sfx/chainsaw.wav"),
	"pressplate": preload("res://resources/audio/sfx/pressplate.wav"),
	"spike": preload("res://resources/audio/sfx/spike.wav")
}

var audio_db: Dictionary = {}
var current_bgm_key: String = ""

func _ready():
	_setup_audio_players()
	_build_audio_db()
	_apply_volumes()

func _apply_volumes():
	# Godot 的总线音量需通过 AudioServer 设置
	# 假设你有 "Master", "Music", "SFX" 总线
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 0) # BGM 自身控制
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), 0) # SFX 自身控制

func _setup_audio_players():
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	bgm_player.connect("finished", Callable(self , "_on_bgm_finished"))
	add_child(bgm_player)

	for i in range(max_sfx_channels):
		var player = AudioStreamPlayer.new()
		player.bus = "Sfx"
		player.connect("finished", Callable(self , "_on_sfx_finished").bind(player))
		add_child(player)
		sfx_players.append(player)

func _build_audio_db():
	# 将 bgm_map 和 sfx_map 合并到 audio_db，键名加上前缀以兼容原有逻辑
	for key in bgm_map:
		audio_db["bgm/" + key] = bgm_map[key]
	for key in sfx_map:
		audio_db["sfx/" + key] = sfx_map[key]

func _on_bgm_finished():
	if current_bgm_key != "" and audio_db.has(current_bgm_key):
		# 重新播放当前 BGM（无淡入淡出，直接循环）
		bgm_player.stream = audio_db[current_bgm_key]
		bgm_player.volume_db = linear_to_db(bgm_volume)
		bgm_player.play()

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

func play_sfx(key: String, volume: float = 0.8, pitch_scale: float = 1.0):
	var full_key = key if key.begins_with("sfx/") else "sfx/%s" % key
	if not audio_db.has(full_key):
		push_warning("SFX not found: %s" % full_key)
		return

	# 如果传入 volume <= 0，则使用默认 sfx_volume；否则使用传入值
	var final_volume = volume if volume >= 0.0 else sfx_volume
	final_volume = clamp(final_volume, 0.0, 1.0)  # 安全限制

	for player in sfx_players:
		if not player.playing:
			player.stream = audio_db[full_key]
			player.pitch_scale = pitch_scale
			player.volume_db = linear_to_db(final_volume)
			player.play()
			return

	# 全忙时强制替换第一个
	sfx_players[0].stop()
	sfx_players[0].stream = audio_db[full_key]
	sfx_players[0].pitch_scale = pitch_scale
	sfx_players[0].volume_db = linear_to_db(final_volume)
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
