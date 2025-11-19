extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("fly")

func set_size(size: float) -> void:
	scale = Vector2(size, size)
