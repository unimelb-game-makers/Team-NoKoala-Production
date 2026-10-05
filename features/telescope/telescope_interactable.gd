class_name Telescope
extends StaticBody3D

@export var view_scenes : Array[TelescopeView] = []
@export var telescope_machine : TelescopeMachine
@export var overlay : TelescopeOverlay
@export var telescope_ui : TelescopeUI

var current_stage : int = 0
var in_discovery : bool = false

func _ready() -> void:
	if telescope_machine != null:
		telescope_machine.repair_completed.connect(_enter_discovery)
		for view in view_scenes:
			view.unlocked_all_zones.connect(_on_zones_unlocked)
		telescope_ui.recipe = telescope_machine.recipes[current_stage]
		telescope_ui.update_recipe()

func interact() -> void:
	if overlay == null:
		return
		
	if not in_discovery:
		telescope_ui.open()
		return

	overlay.show()
	overlay.open(view_scenes[current_stage - 1])
	
func _enter_discovery() -> void:
	in_discovery = true

func _advance_stage() -> void:
	current_stage = mini(current_stage + 1, view_scenes.size()) # can't go past last stage
	
	telescope_ui.recipe = telescope_machine.recipes[current_stage]
	telescope_ui.update_recipe()
	
func _on_zones_unlocked() -> void:
	in_discovery = false
	telescope_machine.resume()
	_advance_stage()
