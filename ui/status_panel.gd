extends HBoxContainer

@export var stats:Stats

@onready var health_bar: TextureProgressBar = $VBoxContainer/HealthBar
@onready var eased_health_bar: TextureProgressBar = $VBoxContainer/HealthBar/EasedHealthBar
@onready var energy_bar: TextureProgressBar = $VBoxContainer/EnergyBar


func _ready() -> void:
	if not stats:
		stats = Game.player_stats
	stats.health_changed.connect(update_health)
	update_health(true) #第一次同步，不用血条动画
	
	stats.energy_changed.connect(update_energy)
	update_energy()
	tree_exited.connect(func ():
		stats.health_changed.disconnect(update_health)
		stats.energy_changed.disconnect(update_energy)
	)
		
	
func update_health(skip_anim := false) -> void:
	var percentage := stats.health / float(stats.max_health)
	health_bar.value = percentage
	if skip_anim:
		eased_health_bar.value = percentage
	else:
		#补间动画，将红色血条，由此时的value变为percentage，动画时长0.3s
		create_tween().tween_property(eased_health_bar,"value",percentage,0.3)


func update_energy() -> void:
	var percentage := stats.energy / stats.max_energy
	energy_bar.value = percentage
