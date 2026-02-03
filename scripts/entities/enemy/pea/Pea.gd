extends "res://scripts/entities/enemy/Enemy.gd"

var has_hit_in_this_attack: bool = false
var attack_timer: float = 0.0  # 改用时间冷却，不再用 can_attack + await
const ATTACK_COOLDOWN: float = 1.0  # 1秒攻击一次

@export var pea_bullet_start: Texture2D
@export var pea_bullet_fly: Texture2D
@export var bullet_scene: PackedScene 

func _ready() -> void:
	super()

# 注意：攻击逻辑在 _physics_process 中由父类调用，所以只需更新 timer
func _physics_process(delta: float) -> void:
	if ai_state == AIState.ATTACKING:
		attack_timer -= delta
	super._physics_process(delta)

func _set_animated_offset() -> void:
	animated_sprite.offset = Vector2(-24, -36)

func _enter_attack_state() -> void:
	_set_animation("Attack")
	has_hit_in_this_attack = false
	attack_timer = 0.0  # 允许立即第一次攻击
	print("Pea 开始攻击！")

func _perform_attack_check() -> void:
	velocity.x = 0
	if attack_timer <= 0.0:
		_spawn_pea_bullet()
		attack_timer = ATTACK_COOLDOWN  # 重置冷却

func _exit_attack_state() -> void:
	has_hit_in_this_attack = false
	print("Pea 攻击结束")

func _spawn_pea_bullet() -> void:
	if bullet_scene == null:
		push_error("bullet_scene 未设置！")
		return

	var bullet = bullet_scene.instantiate()
	var facing_right = animated_sprite.scale.x < 0
	# facing_right大于0换为1，小于0换为-1
	var facing_index = -1 if facing_right else 1
	# bullet.position = Vector2(-16 * facing_index, -6)
	bullet.position = Vector2(-16 * facing_index, 0)
	bullet.direction = Vector2.RIGHT if facing_right else Vector2.LEFT
	bullet.fly_texture = pea_bullet_fly
	bullet.start_texture  = pea_bullet_start

	var container = get_node_or_null("PeaBullet")
	if container:
		container.add_child(bullet)
	else:
		add_child(bullet)
