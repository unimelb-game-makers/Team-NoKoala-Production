class_name MachinePlacementController
extends Node

@export var grid: Grid
@export var machine_manager: MachineManager

var _floating_assembly: MachineAssembly

func begin_placement() -> MachineAssembly:
	cancel_placement()
	_floating_assembly = MachineFactory.create_machine()
	grid.add_block_visual(_floating_assembly)
	return _floating_assembly

func update_preview(cell: Vector3i) -> void:
	if _floating_assembly == null:
		return

	grid.move_block_visual(_floating_assembly, cell)

func rotate_preview() -> void:
	if _floating_assembly == null:
		return

	_floating_assembly.block.switch_rotation()

func confirm_placement(cell: Vector3i) -> bool:
	if _floating_assembly == null:
		return false

	if not grid.move_block(
		_floating_assembly.block,
		cell,
		_floating_assembly,
	):
		return false

	_floating_assembly.machine.center_position = cell
	if not machine_manager.register_machine(_floating_assembly.machine):
		grid.remove_block(_floating_assembly.block)
		return false

	_floating_assembly = null
	return true

func cancel_placement() -> void:
	if _floating_assembly != null:
		_floating_assembly.queue_free()
		_floating_assembly = null

func has_active_placement() -> bool:
	return _floating_assembly != null
