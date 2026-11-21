class_name RecipeSuppliedCondition
extends TutorialCondition

## Satisfied once the machine of the MachineAssembly in [member machine_group]
## has completed a recipe (or has been consumed by completing it).
@export var machine_group: StringName

var _ctx: TutorialContext
var _machine: Machine
var _was_processing := false
var _ratio := -1.0


func has_progress() -> bool:
	return true


func start(ctx: TutorialContext) -> void:
	_ctx = ctx
	_ratio = -1.0
	_was_processing = false
	var assembly := ctx.tree.get_first_node_in_group(machine_group) as MachineAssembly
	if assembly == null:
		push_error("RecipeSuppliedCondition: no MachineAssembly in group '%s'" % machine_group)
		return
	_machine = assembly.get_ui_machine()
	if _machine == null:
		push_error("RecipeSuppliedCondition: assembly in '%s' has no machine" % machine_group)
		return
	ctx.ticked.connect(_on_tick)
	_on_tick(0.0)


func stop() -> void:
	if _ctx != null and _ctx.ticked.is_connected(_on_tick):
		_ctx.ticked.disconnect(_on_tick)
	_ctx = null
	_machine = null


func _on_tick(_delta: float) -> void:
	var done := false
	var ratio := 0.0
	# RitualMachine frees itself when its recipe completes.
	if not is_instance_valid(_machine) or _machine.is_queued_for_deletion():
		done = true
	elif _machine.is_processing_recipe():
		_was_processing = true
		ratio = _machine.get_processing_progress()
	elif _was_processing:
		done = true
	if done:
		ratio = 1.0
	if ratio != _ratio:
		_ratio = ratio
		progress_changed.emit(ratio)
	if done:
		stop()
		satisfied.emit()
