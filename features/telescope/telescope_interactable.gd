class_name Telescope
extends StaticBody3D

@export var stages: Array[TelescopeStage] = []
@export var telescope_machine : TelescopeMachine
@export var overlay : TelescopeOverlay
@export var telescope_ui : TelescopeUI

var current_stage : int = 0
var in_discovery : bool = false

var _views: Array[TelescopeView] = []

func _ready() -> void:
	if telescope_machine == null or stages.is_empty():
		return
	
	var recipes: Array[ProductionRecipe] = []
	for stage in stages:
		recipes.append(stage.recipe)
	telescope_machine.recipes = recipes
	telescope_machine.repair_completed.connect(_enter_discovery)
	
	for stage in stages:
		var view = stage.view_scene.instantiate() as TelescopeView
		view.hide()
		overlay.add_child(view)
		_views.append(view)
		view.unlocked_all_zones.connect(_on_zones_unlocked.bind(view))
	telescope_machine.repair_completed.connect(_enter_discovery)
	_show_stage()

func interact() -> void:
	if overlay == null:
		return
		
	if not in_discovery:
		telescope_ui.open()
		return

	overlay.open(_views[current_stage])
	
	
func _enter_discovery() -> void:
	in_discovery = true

func _advance_stage() -> void:
	if current_stage + 1 >= stages.size():
		return
	current_stage += 1
	_show_stage()
	
func _on_zones_unlocked(view: TelescopeView) -> void:
	if view != _views[current_stage]:
		return
	in_discovery = false
	telescope_machine.resume()
	_advance_stage()

func _show_stage() -> void:
	var stage = stages[current_stage]
	telescope_ui.recipe = stage.recipe
	telescope_ui.update_recipe()
	telescope_ui.update_stage_text(stage)
	telescope_ui.update_tier(_views[current_stage])
