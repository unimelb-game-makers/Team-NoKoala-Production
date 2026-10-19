class_name OnReadyCutsceneTrigger
extends Node3D

@export var cutscene: VideoStream

var _world_ui: WorldUI


func configure(world_ui: WorldUI) -> void:
	_world_ui = world_ui


func _ready() -> void:
	if _world_ui != null:
		_world_ui.play_cutscene(cutscene)
