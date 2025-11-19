class_name Player
extends CharacterBody2D

@export var fireball_scene: PackedScene
@export var firespin_scene: PackedScene
@export var firepillar_scene: PackedScene
@export var timestop_scene : PackedScene
@export var pillar_offset_x: float = 64.0
@export var pillar_offset_y: float = -60.0  # 往上移动的距离（负数是向上）

enum Direction{
	LEFT = -1,
	RIGHT= +1,
}

enum State{
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP,
	ATTACK_1,
	ATTACK_2,
	ATTACK_3,
	ATTACK_4,
	HURT,
	DYING,
	SLIDING_START,
	SLIDING_LOOP,
	SLIDING_END,
	PRAY_1,
	PRAY_2,
	PRAY_3,
	PRAY_4,
	
}

const GROUND_STATES :=[
	State.IDLE,State.RUNNING,State.LANDING,State.WALL_SLIDING,
	State.ATTACK_1,State.ATTACK_2,State.ATTACK_3,State.ATTACK_4,
]

const ATTACK_STATES :=[
	State.ATTACK_1,State.ATTACK_2,State.ATTACK_3,State.ATTACK_4,
]
const KNOCKBACK_AMOUNT := 10.0
const SLIDING_DURATION := 0.3
const SLIDING_SPEED := 256.0
const SLIDING_ENERGY := 4.0
const LANDING_HEIGHT := 100.0



var run_speed := 260.0
var jump_velocity :=-480.0
var floor_acceleration := run_speed / 0.2 #0.2s加速到最大速度
var air_acceleration := run_speed/0.1
var wall_jump_velocity := Vector2(220,-330)
var spell_energy_1 := 1.0
var spell_energy_2 := 1.0
var spell_energy_3 := 1.0
var spell_energy_4 := 1.0
var is_spell_ready := false

@export var can_combo := false
@export var direction := Direction.RIGHT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = direction
		
var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
var is_first_tick := false #判断是否第一帧，关掉重力影响
var is_combo_requested := false
var pending_damage: Damage
var fall_from_y : float
var interacting_with : Array[Interactable]
var pray_position: Vector2  # 记录施法时的位置
var control_enabled: bool = true

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var hand_checker: RayCast2D = $Graphics/HandChecker
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = Game.player_stats
@onready var invincible_timer: Timer = $InvincibleTimer
@onready var slide_request_timer: Timer = $SlideRequestTimer
@onready var interaction_icon: AnimatedSprite2D = $InteractionIcon
@onready var fireball_point: Node2D = $Graphics/FireballPoint
@onready var firespin_point: Node2D = $Graphics/FirespinPoint
@onready var game_over_screen: Control = $CanvasLayer/GameOverScreen
@onready var pause_screen: Control = $CanvasLayer/PauseScreen



@onready var hitbox: Hitbox = $Graphics/Hitbox

func _ready() -> void:
	add_to_group("player")
	hitbox.damage_amount = 1 #修改玩家的初始伤害

func set_control_enabled(enable: bool):
	control_enabled = enable

func _physics_process(delta):
	if not control_enabled:
		return

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	#提前松开跳跃键，则更迅速落地
	if event.is_action_released("jump") and velocity.y<jump_velocity/2:
		velocity.y=jump_velocity/2
	
	if event.is_action_pressed("attack") and can_combo:
		is_combo_requested = true
	
	if event.is_action_pressed("slide"):
		slide_request_timer.start()
	
	if event.is_action_pressed("interact") and interacting_with:
		#只和最后一个可交互对象交互
		interacting_with.back().interact()
	
	if event.is_action_pressed("pause"):
		pause_screen.show_pause()
	
func can_wall_slide() -> bool:
	return is_on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding()

func should_slide() -> bool:
	if slide_request_timer.is_stopped():
		return false
	#精力不足
	if stats.energy < SLIDING_ENERGY:
		return false
	#只要脚没撞到东西就可以滑铲
	return not foot_checker.is_colliding()

func move_with_speed(gravity: float, delta: float, move_speed: float) -> void:
	#向左为-1，向右为1，默认为0
	var movement := Input.get_axis("move_left","move_right")
	var acceleration := floor_acceleration if is_on_floor() else air_acceleration
	#x方向用加速度逐步达到目标速度
	velocity.x = move_toward(velocity.x, movement * move_speed, acceleration * delta)
	velocity.y += gravity * delta #重力加速度乘时间
	
	if not is_zero_approx(movement):
		#左右移动翻转人物
		#graphics.scale.x = -1 if movement < 0 else 1
		direction = Direction.LEFT if movement < 0 else Direction.RIGHT
	
	move_and_slide()
	
func move(gravity: float, delta: float) -> void:
	move_with_speed(gravity, delta, run_speed)



func stand(gravity:float, delta : float) -> void:
	var acceleration :=floor_acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x , 0.0, acceleration * delta)
	velocity.y += gravity * delta #重力加速度乘时间
	move_and_slide()
	
func slide(delta: float) -> void:
	velocity.x =graphics.scale.x * SLIDING_SPEED
	velocity.y += default_gravity * delta #只受默认重力影响
	move_and_slide()
	


func die() -> void:
	#get_tree().reload_current_scene()
	game_over_screen.show_game_over()
	
func pray1()	 -> void:
	print("pray1 !!! ")
	SoundManager.play_sfx("Fire")
	var fireball_instance = fireball_scene.instantiate()
	fireball_instance.global_position = fireball_point.global_position
	fireball_instance.set_fireball_size(0.5)  # 缩小为一半
	# 根据角色朝向设置方向
	fireball_instance.direction = Vector2(direction, 0)
	
	get_tree().current_scene.add_child(fireball_instance)

func pray2()	 -> void:
	print("pray2 !!! ")
	SoundManager.play_sfx("FireSpin")
	var firespin_instance = firespin_scene.instantiate()
	
	add_child(firespin_instance) # 先绑定
	firespin_instance.set_firespin_size(3)  # 放大为3倍
	firespin_instance.position = firespin_point.position # 本地坐标
	#firespin_instance.z_index = 10 # 显示在玩家上方
	#get_tree().current_scene.add_child(firespin_instance)
	

#生成火柱
func _spawn_flame_at_offset(offset: Vector2) -> void:
	var pillar = firepillar_scene.instantiate()
	get_tree().current_scene.add_child(pillar)
	pillar.global_position = pray_position + offset + Vector2(0, pillar_offset_y)
	pillar.set_firepillar_size(2)
	
func pray3()	 -> void:
	print("pray3 !!! ")
	SoundManager.play_sfx("FirePillar")
	# 前后各 3 根
	var offsets = [1, 2, 3,4,5]
	# 施法瞬间锁定玩家位置
	pray_position = global_position
	for i in offsets:
		# 前方
		_spawn_flame_at_offset(Vector2(pillar_offset_x * i, 0))
		# 后方
		_spawn_flame_at_offset(Vector2(-pillar_offset_x * i, 0))
		# 间隔 0.1s
		await get_tree().create_timer(0.3).timeout

func pray4() -> void:
	print("Time Stop !!!")
	SoundManager.play_sfx("TimeStop")
	var timestop_effect := timestop_scene.instantiate()
		
	# 放在玩家节点下，让动画跟随玩家移动
	add_child(timestop_effect)
	timestop_effect.set_size(0.5)
	# 设置效果位置在头顶 
	timestop_effect.global_position = global_position + Vector2(0, -70)
	# 目标：冻结怪物时间
	set_enemies_time_scale(0.1)  # 越小时间越慢（0.05 ≈ 时停）

	# 3秒后恢复
	await get_tree().create_timer(5.0).timeout
	SoundManager.play_sfx("TimestopVanish")
	set_enemies_time_scale(1.0)
	
	timestop_effect.queue_free()
	timestop_effect = null
	print("Time Stop End !!!")
		
func set_enemies_time_scale(time_scale: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.time_scale = time_scale  # 超级慢
	for bullet in get_tree().get_nodes_in_group("bullet"):
		bullet.time_scale = time_scale  # 超级慢

func register_interactable(v: Interactable) -> void:
	#死亡时不交互
	if state_machine.current_state == State.DYING:
		return
	if v in interacting_with:
		return
	interacting_with.append(v)

func unregister_interactable(v: Interactable) -> void:
	interacting_with.erase(v)

#每一帧的物理处理
func tick_physics(state:State,delta: float) -> void:
	#每帧判断是否有可交互对象
	interaction_icon.visible = not interacting_with.is_empty()
	#无敌时间
	if invincible_timer.time_left>0:
		#透明度在0和1之间切换
		graphics.modulate.a=sin(Time.get_ticks_msec()/20) *0.5 + 0.5
	else:
		graphics.modulate.a=1
	#print("状态: ", state, " 速度Y: ", velocity.y, " 重力: ", default_gravity)
	match state:
		State.IDLE:
			move(default_gravity,delta)
				
		State.RUNNING:
			move(default_gravity,delta)
		
		State.JUMP:
			move(0.0 if is_first_tick else default_gravity,delta)
			
		State.FALL:
			move(default_gravity,delta)
		State.LANDING:
			stand(default_gravity,delta)
			
		State.WALL_SLIDING:
			var movement := Input.get_axis("move_left","move_right")
			if not is_zero_approx(movement):
				# 玩家有水平输入，正常移动
				move(default_gravity/5, delta)
			else:
				# 玩家没有输入，给一个朝向墙壁的水平速度
				var wall_normal := get_wall_normal()
				#var acceleration := air_acceleration
				# 根据墙壁法线确定朝向墙壁的方向 (1 表示向右，-1 表示向左)
				var toward_wall_direction := 1 if wall_normal.x < 0 else -1
				velocity.x = 27 * toward_wall_direction
				velocity.y += default_gravity / 5 * delta
				# 确保角色朝向墙壁
				#graphics.scale.x = -1 if toward_wall_direction < 0 else 1
				direction = Direction.LEFT if toward_wall_direction < 0 else Direction.RIGHT
				move_and_slide()

			
		State.WALL_JUMP:
			#if state_machine.state_time <0.1:
				#stand(0.0 if is_first_tick else default_gravity,delta)
			if true:
			# 墙跳期间完全禁用水平输入
				#graphics.scale.x = get_wall_normal().x
				direction = Direction.LEFT if get_wall_normal().x < 0 else Direction.RIGHT
				var acceleration := air_acceleration
				# 保持墙跳的初始水平方向，不允许改变
				velocity.x = move_toward(velocity.x, velocity.x, acceleration * delta)
				velocity.y += default_gravity * delta
				
				move_and_slide()
		State.ATTACK_1,State.ATTACK_2,State.ATTACK_3,State.ATTACK_4:
			#stand(default_gravity,delta)
			move_with_speed(default_gravity, delta, run_speed * 0.1)
		State.HURT,State.DYING:
			stand(default_gravity,delta)
			#move_with_speed(default_gravity, delta, run_speed * 0.1)
		
		State.SLIDING_END:
			stand(default_gravity,delta)
		
		State.SLIDING_START,State.SLIDING_LOOP:
			slide(delta)
			
		State.PRAY_1,State.PRAY_2,State.PRAY_3,State.PRAY_4:
			stand(default_gravity,delta)
			
	is_first_tick =false
	
	


func get_next_state(state: State) -> int:
	if stats.health == 0:
		return StateMachine.KEEP_CURRENT if state==State.DYING else State.DYING
	
	if pending_damage:
		return State.HURT
	
	var can_jump := is_on_floor() or coyote_timer.time_left>0
	var should_jump :=can_jump and jump_request_timer.time_left>0
	if should_jump:
		return State.JUMP
	
	#优先往下掉，特别是当攻击时
	#if state in GROUND_STATES and not is_on_floor():
	#	return State.FALL
		
	#向左为-1，向右为1，默认为0
	var movement := Input.get_axis("move_left","move_right")
	#判断玩家是否静止不动
	var is_still := is_zero_approx(movement) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if not is_on_floor():
				return State.FALL
			if should_slide():
				return State.SLIDING_START
			#进入一段攻击
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK_1
			#祷告1
			if Input.is_action_just_pressed("pray1")  and stats.energy >= spell_energy_1:
				return State.PRAY_1
			#祷告2
			if Input.is_action_just_pressed("pray2") and stats.energy >= spell_energy_2:
				return State.PRAY_2		
				
			if Input.is_action_just_pressed("pray3") and stats.energy >= spell_energy_3:
				return State.PRAY_3	
			if Input.is_action_just_pressed("pray4") and stats.energy >= spell_energy_4:
				return State.PRAY_4
			if not is_still:
				return State.RUNNING
				
		State.RUNNING:
			if not is_on_floor():
				return State.FALL
			if should_slide():
				return State.SLIDING_START
			#进入一段攻击
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK_1
			#祷告1
			if Input.is_action_just_pressed("pray1") and stats.energy >= spell_energy_1:
				return State.PRAY_1
			#祷告2
			if Input.is_action_just_pressed("pray2") and stats.energy >= spell_energy_2:
				return State.PRAY_2
						
			if Input.is_action_just_pressed("pray3") and stats.energy >= spell_energy_3:
				return State.PRAY_3	
			if Input.is_action_just_pressed("pray4") and stats.energy >= spell_energy_4:
				return State.PRAY_4
			if is_still:
				return State.IDLE
		
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
		
		State.FALL:
			if is_on_floor():
				var height := global_position.y - fall_from_y
				return State.LANDING if height >= LANDING_HEIGHT else State.RUNNING
			#手脚均碰到什么东西，且在墙上才滑墙
			if can_wall_slide():
				return State.WALL_SLIDING
				
		State.LANDING:
			if not animation_player.is_playing():
				return State.IDLE
				
		State.WALL_SLIDING :
			if jump_request_timer.time_left > 0 or coyote_timer.time_left>0:
				return State.WALL_JUMP
			#滑到地面
			if is_on_floor():
				return State.IDLE
			#主动跳离墙面
			if not is_on_wall() and velocity.y > -10:
				return State.FALL
		State.WALL_JUMP:
			if can_wall_slide() and not is_first_tick:
				return State.WALL_SLIDING
			#当速度不再朝上，进入下落状态
			if velocity.y>=0:
				return State.FALL
				
		State.ATTACK_1:
			#当动画播放完毕
			if not animation_player.is_playing():
				return State.ATTACK_2 if is_combo_requested else State.IDLE
		State.ATTACK_2:
			#当动画播放完毕
			if not animation_player.is_playing():
				return State.ATTACK_3 if is_combo_requested else State.IDLE
		State.ATTACK_3:
			#当动画播放完毕
			if not animation_player.is_playing():
				return State.ATTACK_4 if is_combo_requested else State.IDLE
		State.ATTACK_4:
			#当动画播放完毕
			if not animation_player.is_playing():
				return State.IDLE
		State.HURT:
			#当动画播放完毕
			if not animation_player.is_playing():
				return State.IDLE
				
		State.SLIDING_START:
			#当动画播放完毕
			if not animation_player.is_playing():
				return State.SLIDING_LOOP
		State.SLIDING_END:
			#当动画播放完毕
			if not animation_player.is_playing():
				return State.IDLE		
		State.SLIDING_LOOP:
			if state_machine.state_time > SLIDING_DURATION or is_on_wall():
				return State.SLIDING_END	
		State.PRAY_1,State.PRAY_2,State.PRAY_3,State.PRAY_4:
			#当动画播放完毕,且未受伤
			if not animation_player.is_playing() and pending_damage == null:
				is_spell_ready = true
				return State.IDLE		
	
	return StateMachine.KEEP_CURRENT

func transition_state(from: State, to:State) ->void:
	#print("[%s] %s => %s" % [
		#Engine.get_physics_frames(),
		#State.keys()[from] if from != -1 else "<START>",
		#State.keys()[to],
	#])
	if from in ATTACK_STATES:
		hitbox.damage_amount = 1 #重置伤害为1
	#提前着陆
	if from not in GROUND_STATES and to in GROUND_STATES:
		coyote_timer.stop()
		
	#释放祷告	
	if from == State.PRAY_1 and is_spell_ready:
		pray1()
		is_spell_ready = false	
		
	if from == State.PRAY_2 and is_spell_ready:
		pray2()	
		is_spell_ready = false		
		
	if from == State.PRAY_3 and is_spell_ready:
		pray3()	
		is_spell_ready = false		
	if from == State.PRAY_4 and is_spell_ready:
		pray4()	
		is_spell_ready = false		
	
		
	match to:
		State.IDLE:
			animation_player.play("idle")
				
		State.RUNNING:
			animation_player.play("running")
		
		State.JUMP:
			animation_player.play("jump")
			velocity.y = jump_velocity
			coyote_timer.stop()
			jump_request_timer.stop()
			SoundManager.play_sfx("Jump")
			
		State.FALL:
			animation_player.play("fall")
			if from in GROUND_STATES:
				coyote_timer.start()
			#开始下落时记录当前高度
			fall_from_y = global_position.y
				
		State.LANDING:
			animation_player.play("landing")
			
		State.WALL_SLIDING:
			velocity.y=0
			animation_player.play("wall_sliding")
			
		State.WALL_JUMP:
			animation_player.play("jump")
			velocity = wall_jump_velocity
			velocity.x *= get_wall_normal().x #根据墙面法向量，确定跳跃方向的正负
			coyote_timer.stop()
			jump_request_timer.stop()
		
		State.ATTACK_1:
			animation_player.play("attack_1")
			#重置为false，只有当玩家按下按键才变为true，进入下一段攻击
			is_combo_requested = false
			hitbox.damage_amount = 1
			SoundManager.play_sfx("Attack")
			
		State.ATTACK_2:
			animation_player.play("attack_2")
			is_combo_requested = false
			hitbox.damage_amount = 2
			SoundManager.play_sfx("Attack_2")
		State.ATTACK_3:
			#SoundManager.play_sfx("Attack")			
			animation_player.play("attack_3")
			is_combo_requested = false
			hitbox.damage_amount = 3
			#SoundManager.play_sfx("Attack_3")
		State.ATTACK_4:
			animation_player.play("attack_4")
			is_combo_requested = false
			hitbox.damage_amount = 4
			SoundManager.play_sfx("Attack_4")
		State.HURT:
			animation_player.play("hurt")
			
			Game.shake_camera(4)
			
			stats.health -= pending_damage.amount

			#判断击退方向
			var dir:=pending_damage.source.global_position.direction_to(global_position)
			velocity = dir * KNOCKBACK_AMOUNT
			
			pending_damage = null
			#开启无敌时间
			invincible_timer.start()
			
		State.DYING:
			animation_player.play("die")
			invincible_timer.stop() #死亡时停止无敌时间
			interacting_with.clear() #清空可交互数组
		
		State.SLIDING_START:
			animation_player.play("sliding_start")
			slide_request_timer.stop()
			stats.energy -= SLIDING_ENERGY
			SoundManager.play_sfx("Slide")
		State.SLIDING_LOOP:
			animation_player.play("sliding_loop")
			
		State.SLIDING_END:
			animation_player.play("sliding_end")
		
		State.PRAY_1:
			SoundManager.play_sfx("Pray")
			animation_player.play("pray")
			stats.energy -= spell_energy_1 #祈祷时减能量
			is_spell_ready = false
		State.PRAY_2:
			SoundManager.play_sfx("Pray")
			animation_player.play("pray")
			stats.energy -= spell_energy_2 #祈祷时减能量
			is_spell_ready = false
		State.PRAY_3:
			SoundManager.play_sfx("Pray")
			animation_player.play("pray")
			stats.energy -= spell_energy_3 #祈祷时减能量
			is_spell_ready = false
		State.PRAY_4:
			SoundManager.play_sfx("Pray")
			animation_player.play("pray")
			stats.energy -= spell_energy_4 #祈祷时减能量
			is_spell_ready = false
	is_first_tick = true


func _on_hurtbox_hurt(hitbox: Variant) -> void:
	#此时无敌，不扣血
	if invincible_timer.time_left>0:
		return
	
	pending_damage = Damage.new()
	#pending_damage.amount = 1
	if hitbox is Hitbox:
		pending_damage.amount = hitbox.damage_amount
	else:
		pending_damage.amount = 1
		
	pending_damage.source = hitbox.owner


func _on_hitbox_hit(hurtbox: Variant) -> void:
	Game.shake_camera(2)
	
	Engine.time_scale = 0.01
	await get_tree().create_timer(0.1,true,false,true).timeout
	Engine.time_scale = 1
