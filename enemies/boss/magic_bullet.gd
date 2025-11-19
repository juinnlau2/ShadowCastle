extends Area2D

@export var speed: float = 300.0       # 子弹的飞行速度 (像素/秒)
@export var turn_speed: float = 4.0    # 子弹的转向速度 (弧度/秒)

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var wall_detector: Area2D = $WallDetector

@onready var hitbox: Hitbox = $Graphics/Hitbox

var time_scale: float = 1.0
# 用于存储玩家节点的变量
var target: Node2D = null
var is_vanishing = false

func _ready():
	add_to_group("bullet")
	hitbox.damage_amount = 2
	animation_player.play("fly")
	# 查找玩家
	target = get_tree().get_first_node_in_group("player")
	hitbox.hit.connect(_on_hitbox_hit)
	# 检测地形等 PhysicsBody
	wall_detector.body_entered.connect(_on_wall_collision) 
	


func  _physics_process(delta: float) -> void:
	#animation_player.speed_scale = time_scale
	pass

func  _process(delta):
	# 检查目标是否存在
	# is_instance_valid() 确保如果玩家被销毁或离开场景，子弹不会崩溃。
	if not is_instance_valid(target):
		# 如果目标没了，子弹就没必要存在了
		queue_free()
		return # 立即停止这帧的后续代码
	
	# =======================================
	# 参考：https://www.bilibili.com/video/BV1sP4y1V7o7/
	var direction = target.position - position
	direction = direction.normalized()
	var rotateAmount = direction.cross(transform.y)
	rotate(rotateAmount * turn_speed*time_scale * delta)
	global_translate(-transform.y * speed*time_scale * delta)
	
	# =======================================


func track_player(delta: float) -> void:
	# --- 核心跟踪逻辑 ---
	# 计算到目标的方向
	# (target.global_position - global_position) 得到一个从子弹指向玩家的向量
	# .angle() 计算这个向量的角度 (以弧度为单位)
	var target_angle = (target.global_position - global_position).angle()
	
	# 平滑转向
	# rotation 是 Area2D 当前的朝向角度 (以弧度为单位)
	# lerp_angle() 会在两个角度之间进行平滑插值，它能正确处理 360° 回环
	# (例如从 350° 转向 10°，它知道走最短的路径)
	# 让当前角度以 turn_speed * delta 的速度 "追赶" 目标角度
	rotation = lerp_angle(rotation, target_angle, turn_speed * delta)
	
	# 向前移动
	# Vector2.RIGHT 是一个 (1, 0) 的向量，代表 "右边" (即 0 度角)
	# .rotated(rotation) 将这个向量旋转到刚刚计算出的新朝向
	var velocity = Vector2.RIGHT.rotated(rotation) * speed * time_scale

	# 更新位置
	global_position += velocity * delta


func vanish() -> void:
	if is_vanishing:
		return
	is_vanishing = true
	speed = 0 
	turn_speed = 0
	# 延迟关闭监控，避免信号阻塞错误
	hitbox.set_deferred("monitoring", false)
	wall_detector.set_deferred("monitoring", false)
	# 播放消失动画
	animation_player.play("vanish")
	SoundManager.play_sfx("BulletVanish")
	await  animation_player.animation_finished
	queue_free()
	
	
func _on_hitbox_hit(hurtbox: Hurtbox) -> void:
	# 打到怪物消失
	vanish()  
	
	
func _on_wall_collision(body):
	vanish()
