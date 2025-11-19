extends AnimatedSprite2D

func _ready():
	# 1. 播放动画
	play("default")

	# 2. 连接 animation_finished 信号
	connect("animation_finished", _on_animation_finished)


func _on_animation_finished():
	# 3. 动画播放完毕，自我销毁
	queue_free()
