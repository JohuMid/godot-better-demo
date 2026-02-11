extends Area2D


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
		EventManager.emit(EventNames.MAGNETAREA_ENTERED)


func _on_body_exited(body: Node2D) -> void:
	if body is RigidBody2D and body.is_in_group("box"):
		EventManager.emit(EventNames.MAGNETAREA_EXITED)
