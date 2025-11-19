extends HBoxContainer


@export var stats:Stats

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var eased_health_bar: TextureProgressBar = $HealthBar/EasedHealthBar


func _ready() -> void:
	visible = false  # 默认隐藏
	
	#stats.health_changed.connect(update_health)
	#update_health(true) #第一次同步，加载血条动画
	
	#tree_exited.connect(func ():
	#	stats.health_changed.disconnect(update_health)
	#)
		

func show_hp() -> void:
	if visible:
		return
	
	visible = true
	stats.health_changed.connect(update_health)
	update_health(true)
	
func update_health(first_anim := false) -> void:
	var percentage := stats.health / float(stats.max_health)
	if first_anim:
		eased_health_bar.value = percentage
		health_bar.value=0
		#血条从0变为1
		create_tween().tween_property(health_bar,"value",1,2.0)

	else:
		health_bar.value = percentage
		#补间动画，将红色血条，由此时的value变为percentage，动画时长0.3s
		create_tween().tween_property(eased_health_bar,"value",percentage,0.3)
