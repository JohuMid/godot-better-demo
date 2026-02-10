extends Node

@export var is_back: bool = false
var animation_player: AnimationPlayer
var detector: Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player = $AnimationPlayer
	if is_back:
		animation_player.play("Disappearing")
	else:
		animation_player.play("Appearing")

	# 播放完成后删除实例
	animation_player.animation_finished.connect(_on_animation_finished)

	detector = $Detector
	# 连接检测器的信号到本脚本的函数
	detector.body_entered.connect(_on_body_entered)

# 当动画播放完成时调用
func _on_animation_finished(anim_name: String) -> void:
	queue_free()

# 当检测到有物体进入时调用
func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		body.take_hit(Vector2(200, 0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
