extends RigidBody2D

func _ready():
	# 设置摩擦、阻尼等，增强真实感
	linear_damp = 3.0  # 阻尼越大，越快停下
	mass = 10.0        # 质量越大，越难推动
