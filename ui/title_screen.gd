extends Control


@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var label: Label = $Label

@onready var new_game: Button = $VBoxContainer/NewGame
@onready var load_game: Button = $VBoxContainer/LoadGame
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


var is_loading: bool = false

func _ready() -> void:
	load_game.disabled = not Game.has_save()#无存档则禁用
	new_game.grab_focus()
	
	#for button:Button in v_box_container.get_children():
		#当鼠标移动到按钮区域时，变为focus状态
	#	button.mouse_entered.connect(button.grab_focus)

	SoundManager.setup_ui_sounds(self)
	SoundManager.play_bgm(preload("res://assets/bgm/02 1 titles LOOP.mp3"))
	# 连接动画播放完成的信号
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	

func _on_new_game_pressed() -> void:
	v_box_container.visible = false
	label.visible = false
	is_loading = false
	animated_sprite_2d.play("stand")
	#Game.new_game()


func _on_load_game_pressed() -> void:
	v_box_container.visible = false
	label.visible = false
	is_loading = true
	animated_sprite_2d.play("stand")
	#Game.load_game()


func _on_exit_game_pressed() -> void:
	get_tree().quit()

# 动画播放完成的回调函数
func _on_animation_finished() -> void:
	if is_loading:
		Game.load_game()
	else:
		Game.new_game()
