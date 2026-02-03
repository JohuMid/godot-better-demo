extends "res://scripts/entities/enemy/Enemy.gd"

# 状态变量（每个实例独立）
var has_hit_in_this_attack: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _set_animated_offset() -> void:
	animated_sprite.offset = Vector2(-24, -36)

# 检查是否在攻击
func _enter_attack_state() -> void:
	has_hit_in_this_attack = false

	_on_animation_finished()
	# 可播放攻击音效等
	print("Pea 开始攻击！")

func _perform_attack_check() -> void:
	pass


func _exit_attack_state() -> void:
	has_hit_in_this_attack = false
	print("Pea 攻击结束")
