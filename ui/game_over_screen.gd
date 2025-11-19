extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	hide()
	set_process_input(false)

func _input(event: InputEvent) -> void:
	#屏蔽键盘输入
	get_window().set_input_as_handled()
	
	#播放动画时不能按键
	if animation_player.is_playing():
		return
	
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed() and not event.is_echo():
			if Game.has_save():
				Game.load_game()
			else:
				Game.back_to_title() 

#其他对象调用，显示结束界面
func show_game_over() -> void:
	show()
	set_process_input(true)
	animation_player.play("enter")
