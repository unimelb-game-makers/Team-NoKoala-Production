class_name NearMachineCondition
extends TutorialCondition

## Satisfied when the player comes within [member distance] of any cell of the
## MachineAssembly in [member machine_group].
@export var machine_group: StringName
## Horizontal distance from a cell centre, in world units.
@export var distance := 1.5

var _ctx: TutorialContext
var _assembly: MachineAssembly


func start(ctx: TutorialContext) -> void:
	_ctx = ctx
	_assembly = ctx.tree.get_first_node_in_group(machine_group) as MachineAssembly
	if _assembly == null:
		push_error("NearMachineCondition: no MachineAssembly in group '%s'" % machine_group)
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
	var grid := _ctx.factory.grid
	var player := Vector2(_ctx.player.global_position.x, _ctx.player.global_position.z)
	for cell in _assembly.get_active_machine().get_occupied_cells():
		var center := grid.cell_to_world(cell)
		if player.distance_to(Vector2(center.x, center.z)) <= distance:
			stop()
			satisfied.emit()
			return
