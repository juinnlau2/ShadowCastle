extends Area2D


@export var camera_target: NodePath
# @export var boss_node: NodePath
@export var boss_bgm: AudioStream
@export var boss_scene: PackedScene

@onready var boss_position: Marker2D = $"../BossPosition"
@onready var camera_2d: Camera2D = $"../Player/Camera2D"


var triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if triggered:
		return
	if body is Player: # 推荐把玩家放在 group
		triggered = true
		start_boss_sequence(body)
		

func start_boss_sequence(player: Node):
	
	# 播放 BGM
	#var audio := AudioStreamPlayer.new()
	#add_child(audio)
	#audio.stream = boss_bgm
	#audio.play()
	SoundManager.play_bgm(boss_bgm)

	# 创建Boss
	#if boss_node != NodePath(""):
		#var boss = get_node(boss_node)
		#if boss.has_method("start_ai"):
			#boss.start_ai()

	# 镜头过渡
	#var camera = player.get_node(camera_target)
	
	# 暂时禁用玩家控制
	if player.has_method("set_control_enabled"):
		player.set_control_enabled(false)	

	# 1️⃣ 镜头先移动到 Boss 出现位置
	var tween := get_tree().create_tween()
	tween.tween_property(camera_2d, "global_position",
		boss_position.global_position,
		3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 2️⃣ 当镜头移动完成后，再生成 Boss
	tween.finished.connect(func():
		if boss_scene:
			var boss = boss_scene.instantiate()
			boss.global_position = boss_position.global_position
			boss.home_position = boss_position.global_position
			
			# 安全地添加到当前场景（防止物理冲突）
			get_tree().current_scene.call_deferred("add_child", boss)

		# 📸 在 Boss 出现后，再执行第二段动画（例如镜头放大）
		var tween2 := get_tree().create_tween()
		tween2.tween_property(camera_2d, "zoom",
			Vector2(0.6, 0.6),
			1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# 第二段动画结束后恢复控制、锁定镜头
		tween2.finished.connect(func():
			if player.has_method("set_control_enabled"):
				player.set_control_enabled(true)

			# 固定镜头状态
			camera_2d.position_smoothing_enabled = false
			camera_2d.drag_horizontal_enabled = false
			camera_2d.drag_vertical_enabled = false

			camera_2d.limit_left = 1224
			camera_2d.limit_right = 1668
			camera_2d.limit_top = 130
			camera_2d.limit_bottom = 380
		))
	

	
