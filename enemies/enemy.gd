class_name Enemy
extends CharacterBody2D

enum Direction{
	LEFT=-1,
	RIGHT=+1,
}

signal  died
var time_scale: float = 1.0

@export var direction := Direction.LEFT:
	set(v):
		direction  = v
		if not is_node_ready():
			await ready
		graphics.scale.x = -direction
		
@export var max_speed: float = 180.0
@export var acceleration: float = 2000.0
var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float


@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = $Stats

func _ready() -> void:
	add_to_group("enemies")

func move(speed: float,delta:float) ->void:
	var dt = delta * time_scale
	#velocity.x = move_toward(velocity.x , speed*direction, acceleration * dt)*time_scale 
	velocity.x = move_toward(velocity.x , speed*direction*time_scale , acceleration * dt)
	velocity.y += default_gravity * dt #重力加速度乘时间
	
	move_and_slide()

		
func  _physics_process(delta: float) -> void:
	animation_player.speed_scale = time_scale

		
func die() -> void:
	died.emit()
	
	queue_free()
	
