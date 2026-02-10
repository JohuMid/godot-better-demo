extends "res://scripts/entities/enemy/Enemy.gd"

var has_hit_in_this_attack: bool = false
var appearing_instance
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 获取Appearing.tscn场景
	var appearing_scene = preload("res://scenes/prefabs/Appearing.tscn")
	# 实例化Appearing.tscn场景
	appearing_instance = appearing_scene.instantiate()
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _set_animated_offset() -> void:
	animated_sprite.offset = Vector2(-24, -36)

# 检查是否在攻击
func _enter_attack_state() -> void:
	has_hit_in_this_attack = false
	velocity.x = 0
	_set_animation("Charge")

	# 已经添加到场景树中，不需要再添加
	if appearing_instance and is_instance_valid(appearing_instance) and not appearing_instance.get_parent():
		add_child(appearing_instance)

	_on_animation_finished()
	# 可播放攻击音效等
	print("Boom 开始攻击！")

func _exit_attack_state() -> void:
	has_hit_in_this_attack = false
	print("Boom 攻击结束")
