extends Enemy

enum State{
	ENTER,
	IDLE,
	WALK,
	RUN,
	CAST_SKILL_1, # 施放技能1 (跟踪魔法弹)
	CAST_SKILL_2, # 施放技能2 (瞬移攻击)
	CAST_SKILL_3, # 施放技能3 (吟唱魔法圈)
	CAST_SKILL_4, # 施放技能4 (冰锥)
	ATTACK,	# 攻击
	WEAK, # 虚弱状态
	RETURN_HOME,  # 返回原点
	HURT,
	DYING,
}
 
var pending_damage:Damage
var home_position: Vector2      # Boss 的“原点”位置
var player: CharacterBody2D     # 玩家引用
var current_magic_circle: Node2D = null # 当前魔法圈
var next_skill_sequence: int = 1 # 下一个施放的技能
var flash_attack_count: int = 0 # 瞬移攻击的次数


@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var calm_down_timer: Timer = $CalmDownTimer

@onready var health_bar_timer: Timer = $HealthBarTimer
@onready var magic_circle_timer: Timer = $MagicCircleTimer
@onready var hitbox: Hitbox = $Graphics/Hitbox

@onready var fire_timer = $FireTimer
@onready var fire_position1 = $FirePosition1
@onready var fire_position2 = $FirePosition2
@onready var fire_position3 = $FirePosition3

@onready var boss_panel: HBoxContainer = $CanvasLayer/BossPanel

# 冰锥引用标记点
@onready var icicle_spawn_left: Marker2D = $IcicleSpawnLeft
@onready var icicle_spawn_right: Marker2D = $IcicleSpawnRight
@onready var ground_level_marker: Marker2D = $GroundLevelMarker

@export var bullet_effect: PackedScene
@export var bullet_scene: PackedScene
@export var magic_circle_scene: PackedScene 
# 预加载冰锥和预警场景
@export var icicle_scene: PackedScene
@export var icicle_warning_scene: PackedScene


func _ready() -> void:
	super() # 父类代码，加入enemy分组
	add_to_group("boss")
	hitbox.damage_amount = 2
	boss_panel.show_hp()
	print("Boss 节点已就绪。")
	# 查找玩家
	player = get_tree().get_first_node_in_group("player")
	

# Skill_1 引导特效
func _start_skill_1_channeling():
	if not bullet_effect:
		print("错误: 缺少引导特效场景!")
		return
	
	var fire_positions = [fire_position1, fire_position2, fire_position3]
	
	for position_marker in fire_positions:
		if not is_instance_valid(position_marker):
			continue
			
		# 1. 实例化“引导特效”
		var effect_instance = bullet_effect.instantiate()
		
		# 2. 设置位置
		effect_instance.global_position = position_marker.global_position
		
		# 3. 添加到场景
		get_parent().add_child(effect_instance)


# Skill_1
func _fire_magic_bullet():
	if not bullet_scene:
		print("错误: 脚本中没有分配 bullet_scene!")
		return 
		
	# 1. 实例化子弹
	var fire_positions = [fire_position1, fire_position2, fire_position3]
	
	for fire_position in fire_positions:	
		var bullet_instance = bullet_scene.instantiate()
		# 2. 设置子弹的初始位置
		bullet_instance.global_position = fire_position.global_position
		# 3. 将子弹添加到游戏中
		# get_parent() 获取 Boss 所在的节点 (即 Level 场景)
		# .add_child() 将子弹实例作为 Level 的子节点添加
		get_parent().add_child(bullet_instance)

	
# Skill_2
func _teleport_behind_player():
	if not is_instance_valid(player):
		# 如果玩家不存在，瞬移到原地 (或 home_position)
		global_position = home_position
		print(global_position.x)
		return

	# 1. 获取玩家位置
	var player_pos = player.global_position
	#print("Player Pos: ")
	#print(player_pos)
	
	# 2. 确定玩家的“背后”
	var player_graphics = player.get_node_or_null("Graphics")
	var offset_x = 30.0 # 瞬移到背后 offset_x 像素的位置
	
	if player_graphics != null and player_graphics.scale.x < 0:
		# 玩家朝左 (scale.x < 0)，"背后" 在他的右边 (x 为正)
		direction = Direction.LEFT
	else:
		# 玩家朝右 (scale.x > 0)，"背后" 在他的左边 (x 为负)
		offset_x = -offset_x
		direction = Direction.RIGHT
	
	# 3. 设置 Boss 的新位置
	global_position.x = player_pos.x + offset_x
	global_position.y = player_pos.y
	#print("Reaper Pos: ")
	#print(global_position)
	

# Skill_3
func _cast_magic_circle():
	if not magic_circle_scene:
		print("错误: 脚本中没有分配 magic_circle_scene!")
		return
		
	# 1. 实例化魔法圈
	var circle_instance = magic_circle_scene.instantiate()
	
	# 2. 将魔法圈添加到游戏节点下
	get_parent().add_child(circle_instance)
	current_magic_circle = circle_instance
	circle_instance.start_tracking(player, global_position) 
	
	# 4. 启动计时器，在魔法圈爆炸后结束 CAST_SKILL_3 状态
	# 假设整个技能持续 5 秒 (3秒追随 + 2秒爆炸动画)
	magic_circle_timer.start(5.0)
	

# Skill_4
func _spawn_icicles():
	if not icicle_scene or not icicle_warning_scene:
		return

	var spawn_y = icicle_spawn_left.global_position.y
	var min_x = icicle_spawn_left.global_position.x
	var max_x = icicle_spawn_right.global_position.x
	# 预警的 Y 坐标 (地面)
	var warning_y = ground_level_marker.global_position.y
	# 预警延迟时间
	var fall_delay = 1.5 
	
	
	var icicle_count = randi_range(15, 18)
	var total_width = max_x - min_x
	var spacing = total_width / icicle_count

	for i in icicle_count:
		# 每个间隔的中心点
		var base_x = min_x + spacing * (i + 0.5)
		# 在间隔内随机微调 +- spacing/3
		var random_x = base_x + randf_range(-spacing/3, spacing/3)
		
		# 生成“预警”
		var warning_instance = icicle_warning_scene.instantiate()
		warning_instance.global_position = Vector2(random_x, warning_y)
		get_parent().add_child(warning_instance)
		
		# 生成“冰锥”
		var icicle_instance = icicle_scene.instantiate()
		icicle_instance.global_position = Vector2(random_x, spawn_y)
		get_parent().add_child(icicle_instance)
		
		icicle_instance.start_fall_with_delay(fall_delay)
		
		await get_tree().create_timer(randf_range(0.1, 0.3)).timeout
# Reaper回到初始位置
func _return_throne() -> void:
	direction = Direction.RIGHT
	print(home_position)
	global_position = home_position

	
func can_see_player() -> bool:
	#无碰撞
	if not player_checker.is_colliding():
		return false
	return player_checker.get_collider() is Player


func tick_physics(state: State, delta:float) -> void:
	match state:
		State.ENTER, State.IDLE, State.CAST_SKILL_1, State.CAST_SKILL_2, State.CAST_SKILL_3, \
		State.WEAK, State.ATTACK, State.RETURN_HOME,State.HURT,State.DYING:
			move(0.0,delta)
			
		State.WALK:
			move(max_speed /3 ,delta)
			
		State.RUN:
			#遇到墙或悬崖时转身继续跑
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				direction*= -1
			move(max_speed,delta)
			if can_see_player():
				calm_down_timer.start()


func get_next_state(state: State) -> int:
	
	if stats.health == 0:
		return StateMachine.KEEP_CURRENT if state==State.DYING else State.DYING
	
	#if pending_damage:
	#	return State.HURT
	
	match state:
		State.ENTER:
			if  not animation_player.is_playing():
				return State.IDLE
				
		State.IDLE:
			if state_machine.state_time > 2:
				if next_skill_sequence == 1:
					return State.CAST_SKILL_1
				elif next_skill_sequence == 2:
					return State.CAST_SKILL_2
				elif next_skill_sequence == 3:
					return State.CAST_SKILL_3
				elif next_skill_sequence == 4:
					return State.CAST_SKILL_4
		
		State.WALK:
			#检测到玩家
			if can_see_player():
				return State.RUN
			#遇到墙或悬崖时停止
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				return State.IDLE
		
		State.RUN:
			if not can_see_player() and calm_down_timer.is_stopped():
				return State.WALK
				
		State.CAST_SKILL_1:
			if not animation_player.is_playing():
				next_skill_sequence = 2
				return State.IDLE # 返回站立状态，等待
				
		State.CAST_SKILL_2:
			if not animation_player.is_playing():
				flash_attack_count += 1
				return State.ATTACK
				
		State.CAST_SKILL_3:
			if not animation_player.is_playing():
				next_skill_sequence = 4
				return State.IDLE 		
				
		State.CAST_SKILL_4:
			if not animation_player.is_playing():
				next_skill_sequence = 1
				return State.IDLE 		
		
		State.ATTACK:
			if not animation_player.is_playing():
				if flash_attack_count < 3:
					print(flash_attack_count)
					return State.CAST_SKILL_2
				else:
					flash_attack_count = 0;
					next_skill_sequence = 3;
					return State.WEAK
				
		State.WEAK:
			if state_machine.state_time > 4 and not animation_player.is_playing():
				return State.RETURN_HOME
		
		State.RETURN_HOME:
			if not animation_player.is_playing():
				return State.IDLE
				
		#State.HURT:
		#	if not animation_player.is_playing():
		#		return State.IDLE
				
	#前面条件都不符合，保持当前状态	
	return StateMachine.KEEP_CURRENT

	
func transition_state(from: State, to:State) ->void:
	print("[%s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to],
	])
		
	match to:
		State.ENTER:
			animation_player.play("show_up")
			
		State.IDLE:
			animation_player.play("idle")
			#遇到墙立即转身
			if wall_checker.is_colliding():
				direction *= -1
				
		State.WALK:
			animation_player.play("walk")	
			if not floor_checker.is_colliding():	
				direction*= -1
				floor_checker.force_raycast_update()
				
		State.RUN:
			animation_player.play("run")
			
		#State.HURT:
			# animation_player.play("hurt")
			
		#	stats.health -= pending_damage.amount
			
		#	pending_damage = null
			
		State.CAST_SKILL_1:
			animation_player.play("launch_bullet") 
			SoundManager.play_sfx("FireBullet")
						
		State.CAST_SKILL_2:
			animation_player.play("flash") 
			SoundManager.play_sfx("Flash")
		
		State.CAST_SKILL_3:
			animation_player.play("chant")
			SoundManager.play_sfx("Chant")
		
		State.CAST_SKILL_4:
			animation_player.play("call_icicle")
		
		State.ATTACK:
			animation_player.play("attack")
			SoundManager.play_sfx("ReaperAttack")
		
		State.WEAK:
			animation_player.play("weak")
						
		State.RETURN_HOME:
			animation_player.play("flash_home") 
			SoundManager.play_sfx("Flash")
		
		State.DYING:
			animation_player.play("die")
			animation_player.animation_finished.connect(
				func(anim_name):
					if anim_name == "die":
						die()
			, CONNECT_ONE_SHOT)
			
			
func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	pending_damage = Damage.new()
	pending_damage.amount = hitbox.damage_amount
	pending_damage.source = hitbox.owner
	stats.health -= pending_damage.amount
	pending_damage = null
	print("Ohn!")

	#stats.health -=1
	#if stats.health == 0:
	#	queue_free()
	
	
# 覆盖 Enemy.gd 中的 die() 函数
func die() -> void:
	died.emit()

	await get_tree().create_timer(1).timeout
	Game.change_scene(
		"res://ui/game_end_screen.tscn",
		{duration=1,}
	)
