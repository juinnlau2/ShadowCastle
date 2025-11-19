class_name Firespin
extends Area2D
@export var life_time : float = 7.0  # 7秒后销毁
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Hitbox = $Hitbox

var is_vanishing := false

func _ready() -> void:
	animation_player.play("fly")
	hitbox.damage_amount = 4  # 火圈伤害 4
	hitbox.hit.connect(_on_hitbox_hit)
	# life_time 秒后自动销毁
	#await get_tree().create_timer(life_time).timeout
	#queue_free()
	# 自动销毁
	#get_tree().create_timer(life_time).timeout.connect(queue_free)
	# 生命周期到期 → 播消失动画
	get_tree().create_timer(life_time).timeout.connect(vanish)
	
func vanish() -> void:
	if is_vanishing:
		return
	is_vanishing = true
	SoundManager.stop_sfx("FireSpin")
	# 停止伤害判定，避免重复触发
	hitbox.set_deferred("monitoring", false)
	set_deferred("monitoring", false)

	animation_player.play("vanish")
	
	# 等待播放结束再删节点
	await animation_player.animation_finished
	queue_free()


func _on_hitbox_hit(hurtbox: Hurtbox) -> void:
	#print("Fire Spin hit:", hurtbox.owner.name)
	# 打到怪物消失
	#queue_free()  # 火球消失
	SoundManager.play_sfx("FireSpinHit")
	vanish()
	
func set_firespin_size(size: float) -> void:
	scale = Vector2(size, size)
