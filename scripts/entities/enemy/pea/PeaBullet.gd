# PeaBullet.gd
extends Area2D

@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 300.0
@export var start_texture: Texture2D
@export var fly_texture: Texture2D

func _ready():
	if not $Sprite2D:
		push_error("Missing Sprite2D!")
		return

	$Sprite2D.texture = start_texture
	$Sprite2D.flip_h = direction.x < 0
	show()

	await get_tree().create_timer(0.05).timeout
	if is_queued_for_deletion():
		return
	$Sprite2D.texture = fly_texture

	body_entered.connect(_on_body_entered)

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

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		queue_free()
		body.take_hit(Vector2(200 * direction.x, 0))

func _detect_player_collision() -> void:
	pass
