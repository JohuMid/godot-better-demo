extends Area2D
@export var show_node: Node2D = null
@export var fade_duration: float = 0.5 # 淡入淡出动画持续时间

var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 直接使用自身作为触发器，连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 初始化 show_node 的透明度为 0
	if show_node:
		show_node.modulate = Color(1, 1, 1, 0)
		show_node.visible = true # 保持可见，通过透明度控制显示

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	show_node.is_can_control = true
	if body is CharacterBody2D and body.is_in_group("player"):
		if show_node and is_instance_valid(show_node):
			# 淡入效果
			show_node.visible = true
			if tween and tween.is_valid():
				tween.kill()
			tween = create_tween()
			tween.tween_property(show_node, "modulate:a", 1.0, fade_duration)

func _on_body_exited(body: Node2D) -> void:
	show_node.is_can_control = false
	if body is CharacterBody2D and body.is_in_group("player"):
		if show_node and is_instance_valid(show_node):
			# 淡出效果
			if tween and tween.is_valid():
				tween.kill()
			tween = create_tween()
			tween.tween_property(show_node, "modulate:a", 0.0, fade_duration)
			# 淡出后保持可见但透明，以便下次淡入
