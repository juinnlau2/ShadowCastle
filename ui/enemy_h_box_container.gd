extends HBoxContainer


@export var stats:Stats

@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
func _ready() -> void:
	stats.health_changed.connect(update_health)
	update_health()

func update_health() -> void:
	var percentage := stats.health / float(stats.max_health)
	texture_progress_bar.value = percentage
