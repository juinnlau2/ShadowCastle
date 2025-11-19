class_name  Teleporter
extends Interactable

@export_file("*.tscn") var path: String
@export var entry_point: String

func interact() -> void:
	super() #执行父类的代码
	Game.change_scene(path, {entry_point=entry_point})
