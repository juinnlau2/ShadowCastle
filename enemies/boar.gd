extends Enemy

enum State{
	IDLE,
	WALK,
	RUN,
	HURT,
	DYING,
}
const KNOCKBACK_AMOUNT := 460.0
var pending_damage:Damage

@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var calm_down_timer: Timer = $CalmDownTimer
@onready var enemy_h_box_container: HBoxContainer = $EnemyHBoxContainer
@onready var health_bar_timer: Timer = $HealthBarTimer


@onready var hitbox: Hitbox = $Graphics/Hitbox

func _ready() -> void:
	super() #父类代码，加入enemy分组
	# 初始隐藏血条
	hitbox.damage_amount = 2 #修改野猪的碰撞伤害
	enemy_h_box_container.visible = false
	# 连接血条计时器信号
	health_bar_timer.timeout.connect(_on_health_bar_timer_timeout)
	
func can_see_player() -> bool:
	#无碰撞
	if not player_checker.is_colliding():
		return false
	return player_checker.get_collider() is Player

func tick_physics(state: State, delta:float) -> void:
	match state:
		State.IDLE,State.HURT,State.DYING:
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
	
	if pending_damage:
		return State.HURT
	
	match state:
		#空闲状态2s后进入walk状态
		State.IDLE:
				#检测到玩家
			if can_see_player():
				return State.RUN	
			if state_machine.state_time > 2:
				return State.WALK
		
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
				
		State.HURT:
			#受伤动画播放完变为idle
			if not animation_player.is_playing():
				return State.IDLE
				
	#前面条件都不符合，保持当前状态	
	return StateMachine.KEEP_CURRENT
	
func transition_state(from: State, to:State) ->void:
	#print("[%s] %s => %s" % [
	#	Engine.get_physics_frames(),
	#	State.keys()[from] if from != -1 else "<START>",
	#	State.keys()[to],
	#])
	#提前着陆
		
	match to:
		State.IDLE:
			animation_player.play("idle")
			#遇到墙立即转身
			if wall_checker.is_colliding():
				direction *= -1
				
		State.WALK:
			animation_player.play("walk")	
			#遇到悬崖时，先转移到idle停止2s，再转移到walk
			#此时到效果是面对悬崖停2s，转身立即走
			if not floor_checker.is_colliding():	
				direction*= -1
				floor_checker.force_raycast_update()
				
		State.RUN:
			animation_player.play("run")
			
		State.HURT:
			animation_player.play("hit")
			
			stats.health -= pending_damage.amount
			
			#判断击退方向
			var dir:=pending_damage.source.global_position.direction_to(global_position)
			velocity = dir * KNOCKBACK_AMOUNT
			
			#面朝玩家方向
			if dir.x>0:
				direction = Direction.LEFT
			else:
				direction = Direction.RIGHT
			
			pending_damage = null
			
		State.DYING:
			animation_player.play("die")


func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	pending_damage = Damage.new()
	pending_damage.amount = hitbox.damage_amount  # 用技能伤害
	pending_damage.source = hitbox.owner
	
	# 显示血条
	show_health_bar()
	#stats.health -=1
	#if stats.health == 0:
	#	queue_free()
	print("Ouch!")

func show_health_bar() -> void:
	# 显示血条
	enemy_h_box_container.visible = true
	# 如果计时器正在运行，先停止
	if health_bar_timer.time_left > 0:
		health_bar_timer.stop()
	# 重新开始10秒计时
	health_bar_timer.start()
func _on_health_bar_timer_timeout() -> void:
	# 隐藏血条
	enemy_h_box_container.visible = false
