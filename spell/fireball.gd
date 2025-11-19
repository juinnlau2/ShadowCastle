class_name Fireball
extends Area2D

@export var fireball_speed: float = 300.0
@export var life_time : float = 5.0  # 5秒后销毁

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Hitbox = $Hitbox
@onready var wall_detector: Area2D = $WallDetector

var direction := Vector2.RIGHT
var is_vanishing := false


func _ready() -> void:
	
	animation_player.play("fly")
	#animation_player.play("vanish")
	hitbox.damage_amount = 2  # 火球伤害2
	hitbox.hit.connect(_on_hitbox_hit)
	wall_detector.body_entered.connect(_on_wall_collision) # 检测地形等 PhysicsBody
	# life_time 秒后自动销毁
	#await get_tree().create_timer(life_time).timeout
	#queue_free()
	# 自动销毁
	#get_tree().create_timer(life_time).timeout.connect(queue_free)
	get_tree().create_timer(life_time).timeout.connect(vanish)
func _physics_process(delta: float) -> void:
	position += direction * fireball_speed * delta

func vanish():
	if is_vanishing:
		return
	SoundManager.play_sfx("FireHit")
	is_vanishing = true
	# 停止移动
	fireball_speed = 0
	# 延迟关闭监控，避免信号阻塞错误
	hitbox.set_deferred("monitoring", false)
	wall_detector.set_deferred("monitoring", false)

	# 播放消失动画
	animation_player.play("vanish")

	# 播放完动画再销毁
	await animation_player.animation_finished
	queue_free()
	
func _on_hitbox_hit(hurtbox: Hurtbox) -> void:
	# 打到怪物消失
	#queue_free()  # 火球消失
	vanish()
func _on_wall_collision(body):
	#queue_free()
	vanish()
func set_fireball_size(size: float) -> void:
	scale = Vector2(size, size)
