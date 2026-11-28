class_name PlayerMachineWorkController
extends Node

@export var capability: WorkerCapability

var _player: Player
@export var _grid: Grid
@export var _factory_manager: FactoryManager
@export var faith_manager: FaithManager
var _working_machine: Machine
var _working_cell: Vector3i
var _gate: FeatureGate


func configure(grid: Grid, factory_manager: FactoryManager, gate: FeatureGate = null) -> void:
	_grid = grid
	_factory_manager = factory_manager
	_gate = gate
	if capability != null:
		capability.consumes_faith = false
	if _gate != null and not _gate.changed.is_connected(_on_gate_changed):
		_gate.changed.connect(_on_gate_changed)


func _on_gate_changed() -> void:
	if not FeatureGate.check(_gate, GameFeature.Id.WORK):
		_stop_working()


func _ready() -> void:
	_player = get_parent() as Player
	if capability != null:
		capability.consumes_faith = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"interact"):
		return
	if not FeatureGate.check(_gate, GameFeature.Id.WORK):
		return

	toggle_work()
	get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if _working_machine == null:
		return

	if (
		not is_instance_valid(_working_machine)
		or _working_machine.disabled
		or _working_machine.is_shut_down
		or _player.target_move_direction.length_squared() > 0.001
		or _get_player_cell() != _working_cell
	):
		_stop_working()
		return

	if not _working_machine.is_working_at_port(_working_cell, capability):
		_clear_working_session()
		_player.is_working = false


func toggle_work() -> bool:
	if _working_machine != null:
		_stop_working()
		return false
	return _try_start_working()


func is_working() -> bool:
	return (
		is_instance_valid(_working_machine)
		and not _working_machine.disabled
		and not _working_machine.is_shut_down
		and _working_machine.is_working_at_port(_working_cell, capability)
	)


func _try_start_working() -> bool:
	if (
		_player == null
		or _grid == null
		or _factory_manager == null
		or capability == null
	):
		return false

	var player_cell := _get_player_cell()
	for candidate in _factory_manager.get_machines_at(player_cell):
		var machine := candidate as Machine
		if machine == null:
			continue
		if machine.disabled:
			continue
		if not machine.try_working_at_port(player_cell, capability):
			continue

		_working_machine = machine
		_working_cell = player_cell
		_player.is_working = true
		return true

	return false


func _stop_working() -> void:
	if (
		is_instance_valid(_working_machine)
		and _working_machine.is_working_at_port(_working_cell, capability)
	):
		_working_machine.try_unallocate_working_port(
			_working_cell,
			capability,
		)
	_clear_working_session()
	_player.is_working = false


func _clear_working_session() -> void:
	_working_machine = null
	_working_cell = Vector3i.ZERO


func _get_player_cell() -> Vector3i:
	var cell := _grid.world_to_cell(_player.global_position)
	cell.y = 0
	return cell


func _exit_tree() -> void:
	_stop_working()
