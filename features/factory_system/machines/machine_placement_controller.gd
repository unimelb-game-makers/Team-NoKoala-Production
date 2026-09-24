class_name MachinePlacementController
extends Node

signal place_mode_changed(enabled: bool)

@export var grid: Grid
@export var factory_manager: FactoryManager
@export var default_machine: MachineFactory.MachineType = MachineFactory.MachineType.DEMO
@export var _faith: FaithManager
@export var _jobs: JobBoard
@export var _reservations: ReservationManager

var place_mode: bool = false:
	get:
		return place_mode
	set(value):
		if place_mode == value:
			return
		if value and _restrict_machine_types and _allowed_machine_types.is_empty():
			return
		place_mode = value
		if value:
			begin_placement()
		else:
			cancel_placement()
		place_mode_changed.emit(value)

var _floating_assembly: MachineAssembly
var _selected_machine: MachineFactory.MachineType = MachineFactory.MachineType.DEMO
var _last_rotation: BlockData.Rotation = BlockData.Rotation.DEG0
var _allowed_machine_types: Array[int] = []
var _restrict_machine_types := false
var _mobs_root: Node


func configure(
	p_grid: Grid,
	p_factory_manager: FactoryManager,
	faith: FaithManager,
	jobs: JobBoard,
	reservations: ReservationManager,
	mobs_root: Node,
	_spring_arm: CameraController,
) -> void:
	grid = p_grid
	factory_manager = p_factory_manager
	_faith = faith
	_jobs = jobs
	_reservations = reservations
	_mobs_root = mobs_root


func _ready() -> void:
	_selected_machine = default_machine
	if _restrict_machine_types and not _allowed_machine_types.is_empty():
		if not _allowed_machine_types.has(_selected_machine):
			_selected_machine = _allowed_machine_types[0] as MachineFactory.MachineType


func set_allowed_definitions(definitions: Array[MachineDefinition]) -> void:
	_restrict_machine_types = true
	_allowed_machine_types.clear()
	for definition in definitions:
		var machine_type := MachineFactory.machine_type_for_definition(definition)
		if machine_type >= 0 and not _allowed_machine_types.has(machine_type):
			_allowed_machine_types.append(machine_type)
	if _allowed_machine_types.is_empty():
		place_mode = false
	elif not _allowed_machine_types.has(_selected_machine):
		select_machine(_allowed_machine_types[0] as MachineFactory.MachineType)

func begin_placement() -> MachineAssembly:
	cancel_placement()
	_floating_assembly = MachineFactory.create_machine(_selected_machine)
	_floating_assembly.configure(
		factory_manager,
		_faith,
		_jobs,
		_reservations,
		_mobs_root,
		grid
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

func select_machine(machine: MachineFactory.MachineType) -> void:
	if _restrict_machine_types and not _allowed_machine_types.has(machine):
		return
	_selected_machine = machine
	if has_active_placement():
		begin_placement()

func select_next_machine() -> void:
	if _restrict_machine_types:
		if _allowed_machine_types.is_empty():
			return
		var current_index := _allowed_machine_types.find(_selected_machine)
		var next_index := wrapi(current_index + 1, 0, _allowed_machine_types.size())
		select_machine(_allowed_machine_types[next_index] as MachineFactory.MachineType)
		return
	var count := MachineFactory.MachineType.size()
	select_machine(wrapi(_selected_machine + 1, 0, count) as MachineFactory.MachineType)
