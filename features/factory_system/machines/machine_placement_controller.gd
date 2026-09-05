class_name MachinePlacementController
extends Node

@export var grid: Grid
@export var factory_manager: FactoryManager
@export var default_machine: MachineFactory.MachineType = MachineFactory.MachineType.DEMO

var place_mode: bool = false:
	get:
		return place_mode
	set(value):
		place_mode = value
		if value:
			begin_placement()
		else:
			cancel_placement()

var _floating_assembly: MachineAssembly
var _selected_machine: MachineFactory.MachineType = MachineFactory.MachineType.DEMO
var _last_rotation: BlockData.Rotation = BlockData.Rotation.DEG0

func _ready() -> void:
	_selected_machine = default_machine

func begin_placement() -> MachineAssembly:
	cancel_placement()
	_floating_assembly = MachineFactory.create_machine(_selected_machine)
	grid.add_block_visual(_floating_assembly.block)
	_floating_assembly.block.disable_collisions()
	_floating_assembly.block.set_appearence(Block.Appearance.TRANSLUCENT)
	_floating_assembly.block.set_rotation_data(_last_rotation)
	return _floating_assembly

func update_preview(cell: Vector3i) -> void:
	if _floating_assembly == null:
		return

	grid.move_block_visual(_floating_assembly.block, cell)

	if grid.can_place_block_at(_floating_assembly.block, cell):
		_floating_assembly.block.set_appearence(Block.Appearance.TRANSLUCENT)
	else:
		_floating_assembly.block.set_appearence(Block.Appearance.TRANSLUCENT_RED)

func rotate_preview() -> void:
	if _floating_assembly == null:
		return

	_floating_assembly.block.switch_rotation()
	_last_rotation = _floating_assembly.block.block_data.block_rotation

func confirm_placement(cell: Vector3i) -> bool:
	if _floating_assembly == null:
		return false

	if not grid.move_block(_floating_assembly.block, cell):
		return false

	_floating_assembly.machine.center_position = cell
	if not factory_manager.register_machine(_floating_assembly.machine):
		grid.remove_block(_floating_assembly.block)
		return false
	
	_floating_assembly.block.enable_collisions()
	_floating_assembly.block.set_appearence(Block.Appearance.NORMAL)

	_floating_assembly = null
	return true

func cancel_placement() -> void:
	if _floating_assembly != null:
		_floating_assembly.queue_free()
		_floating_assembly = null

func has_active_placement() -> bool:
	return _floating_assembly != null

func select_machine(machine: MachineFactory.MachineType) -> void:
	_selected_machine = machine
	if has_active_placement():
		begin_placement()

func select_next_machine() -> void:
	var count := MachineFactory.MachineType.size()
	select_machine(wrapi(_selected_machine + 1, 0, count) as MachineFactory.MachineType)
