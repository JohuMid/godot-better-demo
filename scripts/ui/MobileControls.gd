# MobileControls.gd
# 挂在 CanvasLayer（layer=10）的子节点上
extends Node

# ══════════════════ 配置 ══════════════════
const SWIPE_H_THRESHOLD: float = 18.0 # 水平滑动触发移动的最小距离
const SWIPE_V_THRESHOLD: float = 22.0 # 垂直滑动触发跳跃/攀爬的最小距离
const LONG_PRESS_TIME: float = 0.22 # 长按判定时间（秒）
const DEAD_ZONE: float = 6.0 # 抖动忽略区

# ══════════════════ 左区状态 ══════════════════
var _l_idx: int = -1 # 左区手指 ID（-1 = 无）
var _l_start: Vector2 = Vector2.ZERO # 按下时的位置
var _l_lp_timer: float = 0.0 # 长按计时
var _l_lp_active: bool = false # 长按已激活
var _l_moved: bool = false # 是否已判定为滑动（取消长按）

# 左区当前方向输入（对应 move_left/right/up/down）
var _l_dir_h: float = 0.0 # -1 左，0 无，1 右
var _l_dir_v: float = 0.0 # -1 上，0 无，1 下

# ══════════════════ 右区状态 ══════════════════
var _r_idx: int = -1
var _r_start: Vector2 = Vector2.ZERO
var _r_lp_timer: float = 0.0
var _r_lp_active: bool = false
var _r_moved: bool = false
var _r_jumped: bool = false # 本次触控是否已触发跳跃

# ══════════════════ 内部按键镜像 ══════════════════
# 用来做差量更新，避免每帧重复 parse
var _state: Dictionary = {
    "move_left": false,
    "move_right": false,
    "move_down": false,
    "jump": false,
    "mouse_left": false,
}

# ══════════════════ 生命周期 ══════════════════
func _ready():
    set_process_input(true)

func _input(event: InputEvent):
    if event is InputEventScreenTouch:
        _on_touch(event)
    elif event is InputEventScreenDrag:
        _on_drag(event)

func _process(delta: float):
    _tick_long_press(delta)
    _flush_actions()

# ══════════════════════════════════════════════
# 触控按下 / 抬起
# ══════════════════════════════════════════════
func _on_touch(ev: InputEventScreenTouch):
    var half_w = get_viewport().get_visible_rect().size.x * 0.5

    if ev.pressed:
        if ev.position.x < half_w:
            # ——— 左区按下 ———
            if _l_idx == -1:
                _l_idx = ev.index
                _l_start = ev.position
                _l_lp_timer = 0.0
                _l_lp_active = false
                _l_moved = false
                _l_dir_h = 0.0
                _l_dir_v = 0.0
        else:
            # ——— 右区按下 ———
            if _r_idx == -1:
                _r_idx = ev.index
                _r_start = ev.position
                _r_lp_timer = 0.0
                _r_lp_active = false
                _r_moved = false
                _r_jumped = false
    else:
        if ev.index == _l_idx:
            # ——— 左区抬起 ———
            _l_idx = -1
            _l_dir_h = 0.0
            _l_dir_v = 0.0
            if _l_lp_active:
                _l_lp_active = false
                _apply_state("mouse_left", false)

        elif ev.index == _r_idx:
            # ——— 右区抬起 ———
            _r_idx = -1
            if _r_lp_active:
                _r_lp_active = false
                _apply_state("mouse_left", false)

# ══════════════════════════════════════════════
# 拖动
# ══════════════════════════════════════════════
func _on_drag(ev: InputEventScreenDrag):
    if ev.index == _l_idx:
        var dx = ev.position.x - _l_start.x
        var dy = ev.position.y - _l_start.y
        var adx = abs(dx)
        var ady = abs(dy)

        # 判定主方向（取更大的那个轴）
        if adx < DEAD_ZONE and ady < DEAD_ZONE:
            return # 太小，忽略

        if not _l_moved:
            _l_moved = true
            # 开始滑动 → 取消长按计时（但已激活的长按继续保持到抬起）
            if not _l_lp_active:
                _l_lp_timer = -9999.0

        if adx >= ady:
            # 主方向：水平
            if adx >= SWIPE_H_THRESHOLD:
                _l_dir_h = sign(dx)
                _l_dir_v = 0.0
            else:
                _l_dir_h = 0.0
        else:
            # 主方向：垂直（爬绳）
            if ady >= SWIPE_V_THRESHOLD:
                _l_dir_v = sign(dy) # -1 上爬，1 下爬
                _l_dir_h = 0.0
            else:
                _l_dir_v = 0.0

    elif ev.index == _r_idx:
        var dx = ev.position.x - _r_start.x
        var dy = ev.position.y - _r_start.y
        var adx = abs(dx)
        var ady = abs(dy)

        if adx < DEAD_ZONE and ady < DEAD_ZONE:
            return

        if not _r_moved:
            _r_moved = true
            if not _r_lp_active:
                _r_lp_timer = -9999.0

        # 右区：上滑 = 跳跃（优先检测）
        if dy < -SWIPE_V_THRESHOLD and adx < SWIPE_H_THRESHOLD * 1.5:
            if not _r_jumped:
                _r_jumped = true
                _trigger_jump()

# ══════════════════════════════════════════════
# 长按计时
# ══════════════════════════════════════════════
func _tick_long_press(delta: float):
    # 左区长按
    if _l_idx != -1 and not _l_lp_active and _l_lp_timer >= 0:
        _l_lp_timer += delta
        if _l_lp_timer >= LONG_PRESS_TIME:
            _l_lp_active = true
            _apply_state("mouse_left", true)

    # 右区长按
    if _r_idx != -1 and not _r_lp_active and _r_lp_timer >= 0:
        _r_lp_timer += delta
        if _r_lp_timer >= LONG_PRESS_TIME:
            _r_lp_active = true
            _apply_state("mouse_left", true)

# ══════════════════════════════════════════════
# 将逻辑状态 → InputAction / InputEventMouseButton
# ══════════════════════════════════════════════
func _flush_actions():
    _sync("move_left", _l_idx != -1 and _l_dir_h < -0.5)
    _sync("move_right", _l_idx != -1 and _l_dir_h > 0.5)
    _sync("jump", _l_idx != -1 and _l_dir_v < -0.5) # 上爬绳
    _sync("move_down", _l_idx != -1 and _l_dir_v > 0.5) # 下爬绳

# _sync：只在状态变化时才 parse，避免事件洪水
func _sync(action: String, want: bool):
    if action == "mouse_left":
        return # mouse_left 由 _set 单独处理
    if _state[action] == want:
        return
    _state[action] = want
    var ev = InputEventAction.new()
    ev.action = action
    ev.pressed = want
    Input.parse_input_event(ev)

func _apply_state(key: String, val: bool):
    if _state[key] == val:
        return
    _state[key] = val
    if key == "mouse_left":
        var ev = InputEventMouseButton.new()
        ev.button_index = MOUSE_BUTTON_LEFT
        ev.pressed = val
        ev.position = get_viewport().get_visible_rect().size * 0.5
        ev.global_position = ev.position
        Input.parse_input_event(ev)
    else:
        var ev = InputEventAction.new()
        ev.action = key
        ev.pressed = val
        Input.parse_input_event(ev)

# 跳跃：模拟 just_pressed（按下 + 下一帧松开）
func _trigger_jump():
    _apply_state("jump", true)
    await get_tree().process_frame
    _apply_state("jump", false)
