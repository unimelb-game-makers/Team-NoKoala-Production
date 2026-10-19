class_name Telescope
extends StaticBody3D

@export var stages: Array[TelescopeStage] = []
@export var telescope_machine : TelescopeMachine
@export var overlay : TelescopeOverlay

var current_stage : int = 0
var in_discovery : bool = false
var is_max_progress : bool = false

var _views: Array[TelescopeView] = []

# note: emitted before internal stage advancement
signal stage_advanced(stage: TelescopeStage)
## Emitted when the stage the player is working towards changes, or the last one is done.
signal stage_changed

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
		
	if not telescope_machine.repair_completed.is_connected(_enter_discovery):
		telescope_machine.repair_completed.connect(_enter_discovery)
	stage_changed.emit()


func get_current_stage() -> TelescopeStage:
	if is_max_progress or current_stage >= stages.size():
		return null
	return stages[current_stage]


func get_current_view() -> TelescopeView:
	if is_max_progress or current_stage >= _views.size():
		return null
	return _views[current_stage]


## Opens the discovery overlay if there is something to discover.
## Returns whether it did; otherwise the machine UI is the way to interact.
func try_open_discovery() -> bool:
	if overlay == null or is_max_progress or not in_discovery:
		return false
	overlay.open(_views[current_stage])
	return true


func _enter_discovery() -> void:
	# TO DO: check if we want to open it immediately or need another interaction
	overlay.open(_views[current_stage])
	in_discovery = true

func _advance_stage() -> void:
	stage_advanced.emit(stages[current_stage])
	if current_stage + 1 >= stages.size():
		is_max_progress = true
		stage_changed.emit()
		return
	current_stage += 1
	stage_changed.emit()
	
func _on_zones_unlocked(view: TelescopeView) -> void:
	if view != _views[current_stage]:
		return
	in_discovery = false
	telescope_machine.resume()
	_advance_stage()
