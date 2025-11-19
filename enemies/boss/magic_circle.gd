extends Area2D
class_name MagicCircle

@export var tracking_speed: float = 260.0   # 追随玩家时的移动速度
@export var tracking_duration: float = 2.8 # 追随玩家的时间 (秒)
@export var tracking_radius: float = 50.0  # 魔法圈围绕玩家的半径

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Hitbox = $Graphics/Hitbox
@onready var tracking_timer: Timer = $TrackingTimer # 用于控制追随时间的计时器

var target: CharacterBody2D = null      # 玩家引用
var boss_node: CharacterBody2D = null      # boss引用
var start_pos: Vector2 = Vector2.ZERO	# 初始位置
var is_tracking: bool = false           # 是否处于追随状态
var has_exploded: bool = false          # 是否已经爆炸（防止重复爆炸和伤害）
var time_scale = 1.0

func _ready() -> void:
	add_to_group("bullet")
	hitbox.damage_amount = 4
	# 连接信号
	tracking_timer.timeout.connect(_on_tracking_timer_timeout)
	# 连接动画结束信号，用于清理
	animation_player.animation_finished.connect(_on_animation_finished)
	target = get_tree().get_first_node_in_group("player")
	# boss_node = get_tree().get_first_node_in_group("boss")
	global_position = target.global_position
	
	# 确保在场景中放置了计时器节点，否则会报错
	if tracking_timer == null:
		push_error("TrackingTimer is missing!")
	
	# 魔法圈开始时播放追踪动画
	animation_player.play("surround_2")
	SoundManager.play_sfx("MagicCircleSurround")
	
	# 关闭 Hitbox，防止在追随阶段造成伤害
	if is_instance_valid(hitbox):
		hitbox.monitoring = false


# Boss 脚本调用
func start_tracking(player_target: CharacterBody2D, reaper_pos: Vector2) -> void:
	if not is_instance_valid(player_target):
		# 如果玩家目标无效，立即进入爆炸阶段
		_on_tracking_timer_timeout()
		return
	# start_pos = reaper_pos
	is_tracking = true
	# 启动计时器，开始追随
	tracking_timer.start(tracking_duration)


func _physics_process(delta: float) -> void:
	#animation_player.speed_scale = time_scale
	if not is_tracking or not is_instance_valid(target):
		return

	# 1. 计算目标位置（围绕玩家的某个点）
	# 获取从玩家到魔法圈的当前向量
	var vector_to_self = global_position - target.global_position
	
	# 如果离玩家太近（防止被玩家挤压），则简单追随玩家位置
	if vector_to_self.length_squared() < 1:
		global_position = target.global_position
		return
		
	# 2. 计算围绕玩家的理想位置
	# 保持在 tracking_radius 距离处，使用当前向量的方向
	#var desired_offset = vector_to_self.normalized() * tracking_radius
	#var desired_position = target.global_position + desired_offset
	var desired_position = target.global_position  - Vector2(0, 25)
	# 3. 计算移动方向
	var direction_vector = desired_position - global_position
	
	if direction_vector.length_squared() > 0:
		# 4. 平滑移动
		var movement = direction_vector.normalized() * tracking_speed * delta *time_scale
		# 确保不会超调
		if movement.length_squared() > direction_vector.length_squared():
			global_position = desired_position
		else:
			global_position += movement


# 计时器超时（追随时间结束）
func _on_tracking_timer_timeout():
	if not is_tracking:
		return
		
	is_tracking = false
	
	# 停止追随，固定位置
	
	# 延迟 1 秒后播放爆炸动画
	get_tree().create_timer(0.2).timeout.connect(func():
		animation_player.play("explosion")
		SoundManager.play_sfx("MagicCircleVanish")
		
		# 启用 hitbox，进行伤害检测
		#if is_instance_valid(hitbox):
		#	hitbox.monitoring = true
	)
	
	
# 动画播放完毕
func _on_animation_finished(anim_name: StringName):
	# 仅在爆炸动画播放完毕后才销毁自身
	if anim_name == "explosion":
		queue_free()
