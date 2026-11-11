class_name MachineConstructedCondition
extends TutorialCondition

## Satisfied once the blueprint of the MachineAssembly in [member machine_group] has
## been built into the real machine.
@export var machine_group: StringName

var _ctx: TutorialContext
var _assembly: MachineAssembly
var _ratio := -1.0


func has_progress() -> bool:
	return true


func start(ctx: TutorialContext) -> void:
	_ctx = ctx
	_ratio = -1.0
	_assembly = ctx.tree.get_first_node_in_group(machine_group) as MachineAssembly
	if _assembly == null:
		push_error("MachineConstructedCondition: no MachineAssembly in group '%s'" % machine_group)
		return
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
	var built := not _assembly.is_blueprint_active()
	var ratio := 1.0 if built else (
		blueprint.get_processing_progress() if blueprint.is_processing_recipe() else 0.0
	)
	if ratio != _ratio:
		_ratio = ratio
		progress_changed.emit(ratio)
	if built:
		stop()
		satisfied.emit()
