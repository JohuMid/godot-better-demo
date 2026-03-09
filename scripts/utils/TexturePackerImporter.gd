# TexturePackerImporter.gd (兼容 Godot 4.0～4.3)
class_name TexturePackerImporter

# 🎯 定义哪些动画不循环（默认都循环）
const NON_LOOPING_ANIMS = [
	"SideJumpUp",
	"SideJumpDown",
	"UpwardJumpUp",
	"UpwardJumpDown",
	"Landing",
	"PlatformJump",
	"Death",
	"Attack",
	"Fall",
	"Jump",
	"TeleportCharacter2"
	# 添加其他只需播放一次的动画名
]

static func create_sprite_frames(atlas_texture: Texture2D, json_path: String, frame_width: int, frame_height: int) -> SpriteFrames:
	print(frame_width,frame_height)
	print(json_path)

	var sprite_frames = SpriteFrames.new()
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("无法加载 JSON: %s" % json_path)
		return sprite_frames
	
	var json_text = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY or not data.has("frames"):
		push_error("JSON 格式无效")
		return sprite_frames

	for anim_key in data.frames:
		var frame_data = data.frames[anim_key]
		var rect = frame_data.frame
		if rect.h != frame_height:
			continue
		
		var anim_name = anim_key.trim_suffix(".png")
		var frame_count = max(1, int(rect.w / frame_width))
		
		var frames: Array[AtlasTexture] = []
		for i in frame_count:
			var region = Rect2(rect.x + i * frame_width, rect.y, frame_width, frame_height)
			var atex = AtlasTexture.new()
			atex.atlas = atlas_texture
			atex.region = region
			frames.append(atex)
		sprite_frames.add_animation(anim_name)
		for tex in frames:
			sprite_frames.add_frame(anim_name, tex) # ← 只加纹理，不设延迟

		# 🔧 设置是否循环
		var should_loop = not (anim_name in NON_LOOPING_ANIMS)
		sprite_frames.set_animation_loop(anim_name, should_loop)
		
		# print("✅ 动画 '%s' 已加载 (%d 帧)" % [anim_name, frame_count])
	
	return sprite_frames
