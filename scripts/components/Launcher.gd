extends Node

# 发射器模式：auto 自动发射，manual 手动发射
@export var mode: String = "auto"
@export var bullet_scene: PackedScene 
@export var direction: Vector2 = Vector2.LEFT
# 发射的子弹类型 firearrow firespell waterarrow waterspell 
@export var type: String = "firearrow"

var cooldown_timer: float = 0.0  # 冷却时间
var launch_icon: Sprite2D
@export var COOLDOWN_TIME: float = 1  # 1秒冷却


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	launch_icon = $LauncherIcon
	launch_icon.texture = load("res://resources/gui/icon/Icon_" + type + ".png")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if mode == "auto":
		# 冷却时间
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			_spawn_pea_bullet()
			cooldown_timer = COOLDOWN_TIME  # 重置冷却时间


func _spawn_pea_bullet() -> void:
	if bullet_scene == null:
		push_error("bullet_scene 未设置！")
		return

	var bullet = bullet_scene.instantiate()

	bullet.direction = direction
	bullet.type = type
	
	if direction == Vector2.UP or direction == Vector2.DOWN:
		bullet.rotation = direction.angle_to(-Vector2.LEFT)
		launch_icon.rotation = direction.angle_to(Vector2.DOWN)
	else:
		bullet.rotation = direction.angle_to(Vector2.LEFT)
		launch_icon.rotation = direction.angle_to(-Vector2.DOWN)

	var container = get_node_or_null("PeaBullet")
	if container:
		container.add_child(bullet)
	else:
		add_child(bullet)
