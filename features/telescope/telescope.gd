class_name Telescope
extends StaticBody3D

@export var view_scenes : Array[PackedScene] = []
@export var telescope_machine : TelescopeMachine
@export var overlay : TelescopeOverlay

var current_stage : int = 0

func _ready() -> void:
	if telescope_machine != null:
		telescope_machine.repair_completed.connect(_advance_stage)

func interact() -> void:
	if overlay == null or current_stage == 0:
		return
	overlay.show()
	var scene = view_scenes[current_stage - 1]
	overlay.show()
	overlay.open(scene)

func _advance_stage() -> void:
	current_stage = mini(current_stage + 1, view_scenes.size()) # can't go past last stage
