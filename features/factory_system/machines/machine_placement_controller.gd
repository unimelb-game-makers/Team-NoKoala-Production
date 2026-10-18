class_name MachinePlacementController
extends Node

signal place_mode_changed(enabled: bool)

@export var grid: Grid
@export var factory_manager: FactoryManager
@export var _faith: FaithManager
@export var _jobs: JobBoard
@export var _reservations: ReservationManager
@export var _progression_manager: ProgressionManager

# debug purposes
@export var all_machines_unlocked = false
var _unlocked_machines: Array[MachineDefinition] = []

var machine_factory: MachineFactory
var spirit_spawner: SpiritSpawner
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
var _machines_root: Node
var _mobs_root: Node
var _warned_missing_root := false


func configure(
	p_machine_factory: MachineFactory,
	p_grid: Grid,
	p_factory_manager: FactoryManager,
	p_spirit_spawner: SpiritSpawner,
	faith: FaithManager,
	jobs: JobBoard,
	reservations: ReservationManager,
	machines_root: Node,
	mobs_root: Node,
	_spring_arm: CameraController,
	p_progression_manager: ProgressionManager = null
) -> void:
	machine_factory = p_machine_factory
	grid = p_grid
	factory_manager = p_factory_manager
	spirit_spawner = p_spirit_spawner
	_faith = faith
	_jobs = jobs
	_reservations = reservations
	_progression_manager = p_progression_manager
	_bind_progression_manager()
	_machines_root = machines_root
	_mobs_root = mobs_root
	_allowed_machine_definitions = machine_factory.get_machine_definitions() if machine_factory != null else []
	if _progression_manager != null and machine_factory != null and _unlocked_machines.is_empty():
		unlock_machine(machine_factory.get_default_machine_definition())
	_select_initial_definition()

func _bind_progression_manager() -> void:
	if _progression_manager == null:
		return
	if not _progression_manager.telescope_stage_advanced.is_connected(_on_telescope_stage_advanced):
		_progression_manager.telescope_stage_advanced.connect(_on_telescope_stage_advanced)
		
func _ready() -> void:
	_select_initial_definition()


func get_allowed_machine_definitions() -> Array[MachineDefinition]:
	var result: Array[MachineDefinition] = []
	for definition in _allowed_machine_definitions:
		if is_unlocked(definition):
			result.append(definition)
	return result


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
		spirit_spawner,
		_mobs_root,
		grid,
	)
	_floating_assembly.block.disable_collisions()
	if _machines_root != null:
		_machines_root.add_child(_floating_assembly)
	else:
		if not _warned_missing_root:
			printerr("MachinePlacementController has no machines_root; adding machines to the scene root")
			_warned_missing_root = true
		get_tree().root.add_child(_floating_assembly)
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
	if machine_factory == null or not _allowed_machine_definitions.has(definition) or not is_unlocked(definition):
		return
	_selected_machine_definition = definition
	if has_active_placement():
		begin_placement()


func select_next_machine() -> void:
	var definitions := get_allowed_machine_definitions()
	if definitions.is_empty():
		return
	var current_index := definitions.find(_selected_machine_definition)
	var next_index := wrapi(current_index + 1, 0, definitions.size())
	select_machine(definitions[next_index])


func _on_telescope_stage_advanced(stage: TelescopeStage) -> void:
	for definition in stage.machine_unlocks:
		unlock_machine(definition)


func unlock_machine(definition: MachineDefinition) -> void:
	if definition != null and not _unlocked_machines.has(definition):
		_unlocked_machines.append(definition)


func is_unlocked(definition: MachineDefinition) -> bool:
	return all_machines_unlocked or _progression_manager == null or _unlocked_machines.has(definition)


func _select_initial_definition() -> void:
	if machine_factory == null:
		return
	var definitions := get_allowed_machine_definitions()
	if _selected_machine_definition == null or not definitions.has(_selected_machine_definition):
		var default_definition := machine_factory.get_default_machine_definition()
		_selected_machine_definition = default_definition if definitions.has(default_definition) else (definitions[0] if not definitions.is_empty() else null)
