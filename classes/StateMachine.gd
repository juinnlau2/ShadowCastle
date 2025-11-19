class_name StateMachine #定义类名，方便在不同场景使用不同状态机
extends Node

const KEEP_CURRENT := -1
#当前状态为int，而不是具体到枚举类型，方便复用
var current_state: int=-1:
	set(v):
		owner.transition_state(current_state,v)
		current_state = v
		state_time = 0

var state_time: float
	
func _ready() -> void:
	#子节点先ready，父节点再ready，这里等待父节点ready
	#否则可能使用父节点unready的变量而报错
	await owner.ready
	current_state = 0
	
func _physics_process(delta: float) -> void:
	#一个死循环，确认当前状态
	while true:
		var next := owner.get_next_state(current_state) as int
		if next == KEEP_CURRENT:
			break

		current_state = next
	#执行当前状态
	owner.tick_physics(current_state,delta)		
	state_time +=delta
