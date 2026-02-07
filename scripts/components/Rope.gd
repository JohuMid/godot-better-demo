# rope.gd
extends Node2D
class_name Rope

## 绳子配置参数
@export var rope_length: int = 10 # 绳子段数
@export var segment_length: float = 5.0 # 每段长度
@export var rope_width: float = 1.0 # 绳子粗细
@export var rope_color: Color = Color(0.03, 0.3, 0.2) # 绳子颜色藤蔓颜色
@export var damping: float = 2 # 阻尼系数，越大摆动越快停止
@export var gravity_scale: float = 1.0 # 重力缩放

var segments: Array[RigidBody2D] = []
var joints: Array[PinJoint2D] = []

func _ready():
	create_rope()

func create_rope():
	# 创建固定点（绳子顶端）
	var anchor = $RopeAnchor
	var prev_body = anchor
	
	# 创建绳子段
	for i in range(rope_length):
		var segment = create_segment(i)
		segment.position = Vector2(0, (i + 1) * segment_length)
		add_child(segment)
		segments.append(segment)
		
		# 创建关节连接
		var joint = create_joint(prev_body, segment)
		add_child(joint)
		joints.append(joint)
		
		prev_body = segment

func create_segment(index: int) -> RigidBody2D:
	var segment = RigidBody2D.new()
	segment.name = "Segment_" + str(index)
	
	# 设置物理属性
	segment.mass = 0.8
	segment.linear_damp = damping
	segment.angular_damp = damping * 2
	segment.gravity_scale = gravity_scale
	
	# 添加碰撞形状（细长的胶囊体）
	var collision = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.height = segment_length * 1.1
	shape.radius = rope_width
	collision.shape = shape
	segment.add_child(collision)
	segment.collision_layer = 8
	segment.collision_mask = 1
	segment.add_to_group("Rope")
	
	# 添加视觉表现
	var line = Line2D.new()
	line.add_point(Vector2((-segment_length - 3) / 2, 0))
	line.add_point(Vector2(segment_length / 2, 0))
	line.width = rope_width * 2
	line.default_color = rope_color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.rotation = PI / 2 # 旋转90度使其水平
	segment.add_child(line)
	
	return segment

func create_joint(body_a: Node2D, body_b: RigidBody2D) -> PinJoint2D:
	var joint = PinJoint2D.new()
	joint.node_a = body_a.get_path()
	joint.node_b = body_b.get_path()
	
	# 设置关节位置（在两个物体之间）
	if body_a is StaticBody2D:
		joint.position = Vector2(0, segment_length / 2)
	else:
		joint.position = body_a.position + Vector2(0, segment_length / 2)
	
	# 调整关节柔软度
	joint.softness = 0.0 # 增加柔软度
	# 关键参数：让关节更“硬”
	joint.bias = 0.3
	
	return joint

func get_bottom_segment() -> RigidBody2D:
	if segments.size() > 0:
		return segments[-1]
	return null

func get_segment_index(segment: RigidBody2D) -> int:
	return segments.find(segment)

func get_prev_segment(segment: RigidBody2D) -> RigidBody2D:
	var index = get_segment_index(segment)
	if index > 0:
		return segments[index - 1]
	return segments[0]

func get_next_segment(segment: RigidBody2D) -> RigidBody2D:
	var index = get_segment_index(segment)
	if index < segments.size() - 1:
		return segments[index + 1]
	return segments[-1]
