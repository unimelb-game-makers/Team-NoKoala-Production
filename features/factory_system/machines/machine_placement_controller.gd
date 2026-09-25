class_name MachinePlacementController
extends Node

signal place_mode_changed(enabled: bool)

@export var grid: Grid
@export var factory_manager: FactoryManager
@export var _faith: FaithManager
@export var _jobs: JobBoard
@export var _reservations: ReservationManager

var machine_factory: MachineFactory
var place_mode: bool = false:
	get:
		return place_mode
	set(value):
		if place_mode == value:
			return
		if value and (
			machine_factory == null
			or _selected_machine_definition == null
			or _allowed_machine_definitions.is_empty()
		):
			return
		place_mode = value
		if value:
			begin_placement()
		else:
			cancel_placement()
		place_mode_changed.emit(value)

var _floating_assembly: MachineAssembly
var _selected_machine_definition: MachineDefinition
var _last_rotation: BlockData.Rotation = BlockData.Rotation.DEG0
var _allowed_machine_definitions: Array[MachineDefinition] = []
var _mobs_root: Node


func configure(
	p_machine_factory: MachineFactory,
	p_grid: Grid,
	p_factory_manager: FactoryManager,
	faith: FaithManager,
	jobs: JobBoard,
	reservations: ReservationManager,
	mobs_root: Node,
	_spring_arm: CameraController,
) -> void:
	machine_factory = p_machine_factory
	grid = p_grid
	factory_manager = p_factory_manager
	_faith = faith
	_jobs = jobs
	_reservations = reservations
	_mobs_root = mobs_root
	_allowed_machine_definitions = machine_factory.get_machine_definitions() if machine_factory != null else []
	_select_initial_definition()


func _ready() -> void:
	_select_initial_definition()


func get_allowed_machine_definitions() -> Array[MachineDefinition]:
	return _allowed_machine_definitions.duplicate()


func begin_placement() -> MachineAssembly:
	cancel_placement()
	if machine_factory == null or _selected_machine_definition == null:
		return null
	_floating_assembly = machine_factory.create_machine(_selected_machine_definition)
	if _floating_assembly == null:
		place_mode = false
		return null
	_floating_assembly.configure(
		factory_manager,
		_faith,
		_jobs,
		_reservations,
		_mobs_root,
		grid,
	)
	_floating_assembly.block.disable_collisions()
	get_parent().add_child(_floating_assembly)
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

	if not _floating_assembly.register_machines(factory_manager, cell):
		grid.remove_block(_floating_assembly.block)
		return false

	_floating_assembly.block.enable_collisions()
	if _floating_assembly.toggle_blueprint:
		_floating_assembly.block.set_appearence(
			Block.Appearance.TRANSLUCENT_BLUE,
		)
	else:
		_floating_assembly.block.set_appearence(Block.Appearance.NORMAL)

	_floating_assembly = null
	return true


func cancel_placement() -> void:
	if _floating_assembly != null:
		_floating_assembly.queue_free()
		_floating_assembly = null


func has_active_placement() -> bool:
	return _floating_assembly != null


func select_machine(definition: MachineDefinition) -> void:
	if machine_factory == null or not _allowed_machine_definitions.has(definition):
		return
	_selected_machine_definition = definition
	if has_active_placement():
		begin_placement()


func select_next_machine() -> void:
	if machine_factory == null:
		return
	if _allowed_machine_definitions.is_empty():
		return
	var current_index := _allowed_machine_definitions.find(_selected_machine_definition)
	var next_index := wrapi(current_index + 1, 0, _allowed_machine_definitions.size())
	select_machine(_allowed_machine_definitions[next_index])


func _select_initial_definition() -> void:
	if machine_factory == null:
		return
	if _selected_machine_definition == null or not _allowed_machine_definitions.has(_selected_machine_definition):
		_selected_machine_definition = machine_factory.get_default_machine_definition()
