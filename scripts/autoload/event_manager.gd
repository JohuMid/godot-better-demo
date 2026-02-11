# res://autoload/EventManager.gd
extends Node

# 内部：事件名 -> 回调列表（Array of Callable）
var _listeners: Dictionary = {}

# 订阅事件
func subscribe(event_name: String, callback: Callable) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	var listeners = _listeners[event_name] as Array
	
	# 避免重复订阅
	if not listeners.has(callback):
		listeners.append(callback)

# 取消订阅（可选，通常非必需）
func unsubscribe(event_name: String, callback: Callable) -> void:
	if _listeners.has(event_name):
		var listeners = _listeners[event_name] as Array
		if listeners.has(callback):
			listeners.erase(callback)

# 发出事件（支持任意参数）
func emit(event_name: String, args: Array = []) -> void:
	if not _listeners.has(event_name):
		printerr("EventManager: No listeners for event '%s'" % event_name)
		return
	
	print("Emitting event: %s with args: %s" % [event_name, args])
	
	var listeners = _listeners[event_name].duplicate() # 防止遍历时修改
	for callback in listeners:
		if callback.is_valid():
			callback.callv(args)
		else:
			# 自动清理无效回调（如目标对象已释放）
			unsubscribe(event_name, callback)

# 可选：清空所有监听（用于重置场景等）
func clear_all() -> void:
	_listeners.clear()
