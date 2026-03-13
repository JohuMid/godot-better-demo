extends Node2D
const SPRITE_SCALE: float = 1.0
# —————— 动画相关 ——————
@export var atlas: Texture2D
@export var json_path: String = "res://resources/item/launcher/spritesheet.json"
@export var type: String = "firearrow"
@export var direction: Vector2 = Vector2.LEFT
@export var speed: float = 300.0
var original_frame_width: int = 60
var original_frame_height: int = 32
var animated_sprite: AnimatedSprite2D
var detector: Area2D

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
	detector = $Detector
	detector.body_entered.connect(_on_body_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	position += direction * speed * delta

	# === 屏幕外销毁 ===
	var cam = get_viewport().get_camera_2d()
	if cam:
		var screen = get_viewport().get_visible_rect().size
		var half = screen / (2.0 * cam.zoom)
		var cx = cam.global_position.x
		if global_position.x < cx - half.x - 200 or global_position.x > cx + half.x + 200:
			queue_free()
			return

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
	if body is TileMapLayer or body.is_in_group("box"):
		# 逐渐消失
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_callback(queue_free)
		
	if body.is_in_group("player"):
		body.take_hit(Vector2(200, 0))
