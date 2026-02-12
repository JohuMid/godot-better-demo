# LetterRenderer.gd
extends Node2D

# --- 可配置参数 ---
@export var text: String = ""                    # 要显示的文字
@export var font_texture: Texture2D                   # A-Z 图集纹理（必须是 26 字母按顺序排列）
@export var letter_width: int = 14                    # 每个字母宽度（像素）
@export var letter_height: int = 14                   # 每个字母高度（像素）
@export var spacing: Vector2 = Vector2(0, 0)          # 字母间距（x, y）
@export var letters_per_row: int = 26                 # 图集中每行多少个字母（通常 26）

# --- 内部 ---
var _sprites: Array[Sprite2D] = []

func _ready():
	render_text(text)

# 渲染新文本（可外部调用）
func render_text(new_text: String):
	# 先清除旧的 sprite
	clear()
	
	var current_pos = Vector2.ZERO
	var upper_text = new_text.to_upper()
	
	for char in upper_text:
		var sprite = create_letter_sprite(char)
		sprite.position = current_pos
		add_child(sprite)
		_sprites.append(sprite)
		
		# 移动到下一个位置
		current_pos.x += letter_width + spacing.x
		current_pos.y += spacing.y
			
		# 忽略非字母字符（如空格、数字等）

# 创建单个字母的 Sprite2D
func create_letter_sprite(letter_char: String) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = font_texture
	sprite.centered = false  # 从左上角对齐，方便排版
	
	# 计算 region
	var index = ord(letter_char) - ord('A')
	var x = (index % letters_per_row) * letter_width
	var y = (index / letters_per_row) * letter_height
	
	sprite.region_enabled = true
	sprite.region_rect = Rect2(x, y, letter_width, letter_height)
	
	# 命名便于调试
	sprite.name = "Letter_%s" % letter_char
	
	return sprite

# 清除所有已创建的字母
func clear():
	for sprite in _sprites:
		sprite.queue_free()
	_sprites.clear()
