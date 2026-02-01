extends AnimatableBody2D

@export var collapse_delay: float = 1.0
var is_collapsing: bool = false

func _ready():
	# 连接 Area2D 的信号
	$Area2D.body_entered.connect(_on_player_entered)

func _on_player_entered(body):
	if body.name == "Player" and not is_collapsing:
		is_collapsing = true
		await get_tree().create_timer(collapse_delay).timeout
		_collapse()

func _collapse():
	# 播放破碎动画
	$AnimationPlayer.play("break")
	
	# 禁用碰撞（关键！）
	$CollisionShape2D.disabled = true
	
	# 可选：动画结束后移除
	await $AnimationPlayer.animation_finished
	queue_free()
