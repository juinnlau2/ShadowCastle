extends Camera2D

@export var recovery_speed := 16.0

var strength := 0.0
var locked := false

func _ready() -> void:
	Game.camera_should_shake.connect(
		func(amount: float):
			strength += amount
	)


func lock_camera():
	locked = true
	#set_process(false)  # 禁用_process
	#set_physics_process(false)  # 禁用_physics_process
	
	#position_smoothing_enabled = false
	#drag_horizontal_enabled = false
	#drag_vertical_enabled = false
	#process_mode = Node.PROCESS_MODE_DISABLED  # 禁止内部更新
	#global_position = global_position # 强制刷新锁定
		# 保存当前的世界变换
   # 保存当前的世界变换
	# 关闭跟随和平滑
	position_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	# 锁定边界为当前坐标
	limit_left = int(global_position.x)
	limit_right = int(global_position.x)
	limit_top = int(global_position.y)
	limit_bottom = int(global_position.y)

	
func unlock_camera():
	locked = false
	position_smoothing_enabled = true
	drag_horizontal_enabled = true
	drag_vertical_enabled = true
	
func _process(delta: float) -> void:
	#global_position = Vector2(0, 0)  # 2D
	if locked:
		#global_position = Vector2(0, 0)  # 2D
		return # 不允许任何位置变化
	offset = Vector2(
		randf_range(-strength , +strength),
		randf_range(-strength, +strength)
	)
	
	strength = move_toward(strength,0,recovery_speed*delta)
