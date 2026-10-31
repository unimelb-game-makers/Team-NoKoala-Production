class_name BlueprintSuppliedCondition
extends TutorialCondition

## Satisfied once the blueprint of the MachineAssembly in [member machine_group] has
## every construction material delivered.
@export var machine_group: StringName

var _ctx: TutorialContext
var _assembly: MachineAssembly
var _ratio := -1.0


func has_progress() -> bool:
	return true


func start(ctx: TutorialContext) -> void:
	_ctx = ctx
	_ratio = -1.0
	for n in ctx.tree.get_nodes_in_group(machine_group):
		print("group member: ", n.get_path(), " ", n)
	_assembly = ctx.tree.get_first_node_in_group(machine_group) as MachineAssembly
	if _assembly == null:
		push_error("BlueprintSuppliedCondition: no MachineAssembly in group '%s'" % machine_group)
		return
	# delivered items are counted from the grid, which has no change signal
	ctx.ticked.connect(_on_tick)
	_on_tick(0.0)


func stop() -> void:
	if _ctx != null and _ctx.ticked.is_connected(_on_tick):
		_ctx.ticked.disconnect(_on_tick)
	_ctx = null
	_assembly = null


func _on_tick(_delta: float) -> void:
	if not is_instance_valid(_assembly):
		return
	var blueprint := _assembly.blueprint as BlueprintMachine
	# once construction starts the materials are claimed and stop counting as delivered
	var supplied := (
		not _assembly.is_blueprint_active()
		or blueprint.is_processing_recipe()
	)
	var ratio := 1.0 if supplied else blueprint.get_material_progress()
	if ratio != _ratio:
		_ratio = ratio
		progress_changed.emit(ratio)
	if ratio >= 1.0:
		stop()
		satisfied.emit()
