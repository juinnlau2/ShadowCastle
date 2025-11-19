class_name Hitbox
extends Area2D

signal hit(hurtbox)

@export var damage_amount: int = 1  # 默认伤害可不同魔法设置


func _init() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(hurtbox: Hurtbox) -> void:
	print("[Hit] %s => %s" % [owner.name,hurtbox.owner.name])
	hit.emit(hurtbox)
	hurtbox.hurt.emit(self)
