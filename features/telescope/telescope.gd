class_name Telescope
extends StaticBody3D

@export var view_scenes : Array[TelescopeView] = []
@export var telescope_machine : TelescopeMachine
@export var overlay : TelescopeOverlay

var current_stage : int = 0
var in_discovery : bool = false

func _ready() -> void:
	if telescope_machine != null:
		telescope_machine.repair_completed.connect(_advance_stage)
		for view in view_scenes:
			view.unlocked_all_zones.connect(_on_zones_unlocked)

func interact() -> void:
	if overlay == null or current_stage == 0:
		return
	overlay.show()
	overlay.open(view_scenes[current_stage - 1])

func _advance_stage() -> void:
	current_stage = mini(current_stage + 1, view_scenes.size()) # can't go past last stage

func _on_zones_unlocked() -> void:
	pass
