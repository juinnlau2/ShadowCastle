class_name FirePillar
extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Hitbox = $Hitbox
@onready var wall_detector_1: Area2D = $WallDetector
@onready var wall_detector_2: Area2D = $WallDetector2

var wall1_collided := false
var wall2_collided := false

func _ready() -> void:
	hitbox.damage_amount = 10  # 火柱伤害 10

	hitbox.hit.connect(_on_hitbox_hit)

	wall_detector_1.body_entered.connect(_on_wall_collision_1)
	wall_detector_2.body_entered.connect(_on_wall_collision_2)

	animation_player.play("fire")
	animation_player.animation_finished.connect(_on_anim_finished)


func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "fire":
		queue_free()


func _on_hitbox_hit(hurtbox: Hurtbox) -> void:
	print("pillar hit !!!")
	# 火柱命中敌人不立刻销毁


func _on_wall_collision_1(body: Node) -> void:
	wall1_collided = true
	_check_wall_collision()

func _on_wall_collision_2(body: Node) -> void:
	wall2_collided = true
	_check_wall_collision()

func _check_wall_collision() -> void:
	if wall1_collided and wall2_collided:
		queue_free()


func set_firepillar_size(size: float) -> void:
	scale = Vector2(size, size)
