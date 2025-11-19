class_name World
extends Node2D

@onready var geometry: TileMapLayer = $Geometry
@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var player: Player = $Player

@export var bgm: AudioStream

func _ready() -> void:
	#地图使用的矩形框，以图块为单位
	var used :=  geometry.get_used_rect() #缩一格
	print("used:%s" , used)
	#获得一个图块的大小
	var tile_size :=  geometry.tile_set.tile_size
	
	#position为左上角坐标，end为右下角坐标
	camera_2d.limit_top = used.position.y * tile_size.y 
	camera_2d.limit_right = used.end.x * tile_size.x 
	camera_2d.limit_bottom = used.end.y * tile_size.y 
	camera_2d.limit_left = used.position.x * tile_size.x 
	camera_2d.reset_smoothing()
	
	if bgm:
		SoundManager.play_bgm(bgm)

#func _unhandled_input(event: InputEvent) -> void:
#	if event.is_action_pressed("ui_cancel"):
#		Game.back_to_title()

func update_player(pos: Vector2, direction: Player.Direction) -> void:
	player.global_position = pos
	player.fall_from_y = pos.y #防止转场结束，进入landing状态
	player.direction = direction
	camera_2d.reset_smoothing()
	camera_2d.force_update_scroll()

func to_dict() -> Dictionary:
	var enemies_alive := []
	for node in get_tree().get_nodes_in_group("enemies"):
		var path := get_path_to(node) as String
		enemies_alive.append(path)
		
	return {
		enemies_alive=enemies_alive,
	}

func from_dict(dict:Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var path := get_path_to(node) as String
		#进入新场景时，如果此时敌人不在存活的字典里，则删除
		if path not in dict.enemies_alive:
			node.queue_free()
