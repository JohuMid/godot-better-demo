extends Node2D
const SPRITE_SCALE: float = 1.0
# —————— 动画相关 ——————
@export var atlas: Texture2D
@export var json_path: String = "res://resources/item/ball/spritesheet.json"
@export var type: String = "fireball"
@export var id: String = "Telepad1"
var original_frame_width: int = 32
var original_frame_height: int = 32
var animated_sprite: AnimatedSprite2D
var detector: Area2D

const ANIM_SPEED = {
	"default": 2.0
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(id)

	if not atlas:
		push_error("请在检查器中指定 Atlas 纹理！")
		return

	var frames = TexturePackerImporter.create_sprite_frames(atlas, json_path, original_frame_width, original_frame_height)
	animated_sprite = $AnimatedSprite2D
	animated_sprite.sprite_frames = frames

	animated_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)

	_set_animation(type)
	detector = $Detector
	detector.body_entered.connect(_on_body_entered)

	EventManager.subscribe(EventNames.PRESSURE_PLATE_ACTIVATED, Callable(self, "_on_pressure_plate_activated"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_pressure_plate_activated(tag: String):
	print('tag',tag)
	if "telepadchange" != tag:
		return
	if type == 'fireball':
		type = 'waterball'
		_set_animation(type)

# —————— 设置动画 ——————
func _set_animation(anim_name: String):
	if animated_sprite.animation == anim_name:
		return

	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		var speed_scale = ANIM_SPEED.get(anim_name, ANIM_SPEED.default)
		animated_sprite.speed_scale = speed_scale
		# print("▶ 播放动画: %s (速度: %.1f)" % [anim_name, speed_scale])
	else:
		print("⚠️ 动画不存在: %s" % anim_name)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if type == 'fireball':
			body.take_hit(Vector2(200, 0))
			return
		print("检测到物体进入: %s" % body.name)
		# 播放触发音效
		AudioManager.play_sfx("telepad")
		EventManager.emit(EventNames.TELEPAD_ENTERED, [id])
