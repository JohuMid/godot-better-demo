extends Node2D
const SPRITE_SCALE: float = 1.0
# —————— 动画相关 ——————
@export var atlas: Texture2D
@export var json_path: String = "res://resources/item/flag/spritesheet.json"
@export var type: String = "star"
var original_frame_width: int = 48
var original_frame_height: int = 48
var animated_sprite: AnimatedSprite2D

const ANIM_SPEED = {
	"default": 2.0
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not atlas:
		push_error("请在检查器中指定 Atlas 纹理！")
		return

	var frames = TexturePackerImporter.create_sprite_frames(atlas, json_path, original_frame_width, original_frame_height)
	animated_sprite = $AnimatedSprite2D
	animated_sprite.sprite_frames = frames

	animated_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)

	_set_animation(type)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# —————— 设置动画 ——————
func _set_animation(anim_name: String):
	if animated_sprite.animation == anim_name:
		return

	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		var speed_scale = ANIM_SPEED.get(anim_name, ANIM_SPEED.default)
		animated_sprite.speed_scale = speed_scale
		print("▶ 播放动画: %s (速度: %.1f)" % [anim_name, speed_scale])
	else:
		print("⚠️ 动画不存在: %s" % anim_name)
