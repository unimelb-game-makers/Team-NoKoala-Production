class_name PlayerEntryCutsceneTrigger
extends Area3D

@export var cutscene: VideoStream
@export var one_shot := true

var _triggered := false
var _world_ui: WorldUI


func configure(world_ui: WorldUI) -> void:
	_world_ui = world_ui


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered or not body is Player:
		return
	if _world_ui.play_cutscene(cutscene):
		_triggered = one_shot
