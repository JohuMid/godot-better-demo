extends Area2D

@export var trigger_tags: Array[String] = []
var wait_timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 直接使用自身作为触发器，连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and body.is_in_group("box"):
		# 三秒之后再触发，防止玩家刚进入就被拉走
		if wait_timer:
			wait_timer.timeout.disconnect(_disable_magnet)
		wait_timer = get_tree().create_timer(3.0)
		wait_timer.timeout.connect(_disable_magnet)

func _on_body_exited(body: Node2D) -> void:
	pass


func _disable_magnet() -> void:
	for tag in trigger_tags:
		EventManager.emit(EventNames.MAGNETAREA_ENTERED, [tag])
	wait_timer = null
