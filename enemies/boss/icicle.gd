extends Area2D

@export var fall_speed: float = 400.0
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var wall_detector: Area2D = $WallDetector
@onready var hitbox: Hitbox = $Graphics/Hitbox

# 标记冰锥是否“激活”
var is_active: bool = false
var is_vanishing = false
var time_scale = 1.0

func _ready():
	add_to_group("bullet")
	# 冰锥在生成时不应该立即移动
	set_physics_process(false)
	visible = false
	hitbox.damage_amount = 2
	hitbox.hit.connect(_on_hitbox_hit)
	# 检测地形
	wall_detector.body_entered.connect(_on_wall_collision) 
	SoundManager.play_sfx("IcicleFall")

	
func start_fall_with_delay(delay: float):
	# 等待预警时间
	await get_tree().create_timer(delay).timeout
	
	if not is_instance_valid(self):
		return
	
	visible = true
	set_physics_process(true)
	is_active = true
	

func _physics_process(delta: float) -> void:
	animation_player.speed_scale = time_scale
	global_position.y += delta * fall_speed * time_scale

func vanish() -> void:
	if is_vanishing:
		return
	is_vanishing = true
	fall_speed = 0 
	# 延迟关闭监控，避免信号阻塞错误
	hitbox.set_deferred("monitoring", false)
	wall_detector.set_deferred("monitoring", false)
	# 播放消失动画
	animation_player.play("vanish")
	SoundManager.play_sfx("IcicleHit")
	await  animation_player.animation_finished
	queue_free()
	
	
func _on_hitbox_hit(hurtbox: Hurtbox) -> void:
	# 打到怪物消失
	vanish()  
	
func _on_wall_collision(body):
	vanish()
		
