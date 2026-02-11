extends Node

@onready var pressure_plate = get_node("../PressurePlate")
# 倒计时初始值（可在编辑器中设置）
@export var count_number = 15
# 是否允许控制倒计时
var is_can_control = false
# 数字精灵节点引用
var sprite_number:Sprite2D
# 每个数字的宽度（像素）
var sprite_width = 17
# 每个数字的高度（像素）
var sprite_height = 17
# 倒计时计时器
var countdown_timer:Timer

var initial_count_number = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	EventManager.subscribe(EventNames.PRESSURE_PLATE_ACTIVATED, Callable(self, "start_countdown"))

	initial_count_number = count_number
	# 获取数字精灵节点
	sprite_number = $Number
	# 启用区域裁剪
	sprite_number.region_enabled = true
	# 初始化显示初始数字
	update_number_sprite(count_number)
	
	# 创建并配置倒计时计时器
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0  # 每秒触发一次
	countdown_timer.one_shot = false  # 循环触发
	countdown_timer.timeout.connect(_on_countdown_timeout)
	add_child(countdown_timer)

# 启动倒计时
func start_countdown() -> void:
	count_number = initial_count_number
	# 立即更新显示初始值
	update_number_sprite(count_number)
	is_can_control = true
	countdown_timer.start()
	sprite_number.visible = true
	# 通过事件中心发送倒计时开始事件
	EventManager.emit(EventNames.COUNTDOWN_START)

# 停止倒计时
func stop_countdown() -> void:
	is_can_control = false
	countdown_timer.stop()
	# 计时结束信号
	EventManager.emit(EventNames.COUNTDOWN_END)

# 计时器超时回调（每秒执行一次）
func _on_countdown_timeout() -> void:
	if not is_can_control:
		return
	
	# 数字减1
	count_number -= 1

	# 倒计时结束判断
	if count_number <= 0:
		stop_countdown()
		sprite_number.visible = false
		return
		# 这里可以添加倒计时结束后的逻辑
	
	# 更新数字显示
	update_number_sprite(count_number)

# 更新数字精灵的显示区域
func update_number_sprite(number: int) -> void:
	# 确保数字在有效范围内（1-50），0显示第50个位置
	var clamped_number = max(1, min(50, number))
	if number == 0:
		clamped_number = 50
	
	# 计算区域矩形：x坐标 = (数字-1) * 宽度，y坐标=0，宽高为17x17
	var region_rect = Rect2(
		(clamped_number - 1) * sprite_width,  # X坐标（横向偏移）
		0,                                     # Y坐标（纵向无偏移）
		sprite_width,                          # 宽度
		sprite_height                          # 高度
	)
	
	# 更新精灵的区域矩形
	sprite_number.region_rect = region_rect

# 可选：手动设置数字的函数（外部调用）
func set_number(number: int) -> void:
	count_number = number
	update_number_sprite(number)
