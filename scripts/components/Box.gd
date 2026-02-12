extends RigidBody2D

@export var magnet_force: float = 1000.0  # 吸引力强度（可调）
var is_in_magnet_area: bool = false
var magnet_timer: SceneTreeTimer = null

# Box.gd
func _ready():
	add_to_group("box")

	sleeping = false
	can_sleep = false

	EventManager.subscribe(EventNames.MAGNETAREA_ENTERED, Callable(self, "_on_magnetarea_entered"))

func _physics_process(delta):
	if is_in_magnet_area:
		apply_central_force(Vector2.UP * magnet_force)  # 向上拉

func _on_magnetarea_entered(tag: String) -> void:
	if tag == "box":
		is_in_magnet_area = true
	
	# 取消之前的定时器（防止多次进入重叠）
	if magnet_timer:
		magnet_timer.timeout.disconnect(_disable_magnet)
	
	# 创建新定时器：5秒后关闭磁力
	magnet_timer = get_tree().create_timer(10.0)
	magnet_timer.timeout.connect(_disable_magnet)


func _disable_magnet() -> void:
	is_in_magnet_area = false
	magnet_timer = null
