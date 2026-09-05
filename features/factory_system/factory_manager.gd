class_name FactoryManager
extends Node

signal machine_registered(machine: Machine)
signal machine_unregistered(machine: Machine)
signal processable_registered(processable: Processable)
signal processable_unregistered(processable: Processable)

@export var grid: Grid

var _machines: Array[Machine] = []
var _processables: Array[Processable] = []
var _processables_by_cell: Dictionary = {}
var _processable_cells: Dictionary = {}


# --- machine apis ---

func register_machine(machine: Machine) -> bool:
	if machine == null or _machines.has(machine):
		return false

	_machines.append(machine)

	var exit_callback := _on_machine_tree_exiting.bind(machine)
	if not machine.tree_exiting.is_connected(exit_callback):
		machine.tree_exiting.connect(exit_callback)

	machine_registered.emit(machine)
	return true

func unregister_machine(
	machine: Machine,
	disconnect_exit_signal: bool = true
) -> bool:
	var index := _machines.find(machine)
	if index == -1:
		return false

	_machines.remove_at(index)
	if disconnect_exit_signal and is_instance_valid(machine):
		var exit_callback := _on_machine_tree_exiting.bind(machine)
		if machine.tree_exiting.is_connected(exit_callback):
			machine.tree_exiting.disconnect(exit_callback)

	machine_unregistered.emit(machine)
	return true

func is_machine_registered(machine: Machine) -> bool:
	return _machines.has(machine)

func get_machines() -> Array[Machine]:
	return _machines.duplicate()

func get_machines_at(cell: Vector3i) -> Array[Machine]:
	var result: Array[Machine] = []
	if grid == null:
		return result

	for block in grid.get_blocks_at(cell):
		var assembly := block.get_parent() as MachineAssembly
		if assembly == null:
			continue

		var machine := assembly.machine
		if (
			is_instance_valid(machine)
			and not machine.is_queued_for_deletion()
			and is_machine_registered(machine)
			and not result.has(machine)
		):
			result.append(machine)

	return result

## The first registered machine occupying a cell, if any.
func get_machine_at(cell: Vector3i) -> Machine:
	var machines := get_machines_at(cell)
	return machines[0] if not machines.is_empty() else null

func cell_to_world(cell: Vector3i) -> Vector3:
	assert(grid != null, "FactoryManager requires a Grid")
	return grid.cell_to_world(cell)

# --- processable apis ---

func register_processable(processable: Processable) -> bool:
	if processable == null or _processables.has(processable):
		return false

	_processables.append(processable)
	_connect_processable(processable)
	if processable.is_dropped():
		_index_processable(processable, processable.get_drop_world_position())

	processable_registered.emit(processable)
	return true

func unregister_processable(
	processable: Processable,
	disconnect_signals: bool = true,
) -> bool:
	var index := _processables.find(processable)
	if index == -1:
		return false

	_processables.remove_at(index)
	_remove_processable_from_index(processable)
	if disconnect_signals and is_instance_valid(processable):
		_disconnect_processable(processable)

	processable_unregistered.emit(processable)
	return true

func get_processables() -> Array[Processable]:
	return _processables.duplicate()

func is_processable_registered(processable: Processable) -> bool:
	return _processables.has(processable)

func get_processables_at(cell: Vector3i) -> Array[Processable]:
	var result: Array[Processable] = []
	for processable: Processable in _processables_by_cell.get(cell, []):
		result.append(processable)
	return result

# --- internal functions --- 

#wire the drop signals 
func _connect_processable(processable: Processable) -> void:
	if not processable.dropped.is_connected(_on_processable_dropped):
		processable.dropped.connect(_on_processable_dropped)
	if not processable.claim_changed.is_connected(_on_processable_claim_changed):
		processable.claim_changed.connect(_on_processable_claim_changed)

	var exit_callback := _on_processable_tree_exiting.bind(processable)
	if not processable.tree_exiting.is_connected(exit_callback):
		processable.tree_exiting.connect(exit_callback)

#unwire the drop signals 
func _disconnect_processable(processable: Processable) -> void:
	if processable.dropped.is_connected(_on_processable_dropped):
		processable.dropped.disconnect(_on_processable_dropped)
	if processable.claim_changed.is_connected(_on_processable_claim_changed):
		processable.claim_changed.disconnect(_on_processable_claim_changed)

	var exit_callback := _on_processable_tree_exiting.bind(processable)
	if processable.tree_exiting.is_connected(exit_callback):
		processable.tree_exiting.disconnect(exit_callback)

# add processable to _processable_cells and _processables_by_cell
func _index_processable(
	processable: Processable,
	world_position: Vector3,
) -> void:
	_remove_processable_from_index(processable)
	var cell := grid.world_to_cell(world_position)
	var cell_processables: Array = _processables_by_cell.get(cell, [])
	cell_processables.append(processable)
	_processables_by_cell[cell] = cell_processables
	_processable_cells[processable] = cell

#remove processable from _processable_cells and _processables_by_cell
func _remove_processable_from_index(processable: Processable) -> void:
	if not _processable_cells.has(processable):
		return

	var cell: Vector3i = _processable_cells[processable]
	var cell_processables: Array = _processables_by_cell.get(cell, [])
	cell_processables.erase(processable)
	if cell_processables.is_empty():
		_processables_by_cell.erase(cell)
	else:
		_processables_by_cell[cell] = cell_processables
	_processable_cells.erase(processable)



# --- wired signal receiver functions --- 
func _on_machine_tree_exiting(machine: Machine) -> void:
	unregister_machine(machine, false)

func _on_processable_dropped(
	processable: Processable,
	world_position: Vector3,
) -> void:
	_index_processable(processable, world_position)

func _on_processable_claim_changed(
	processable: Processable,
	claimant: Object,
) -> void:
	if claimant != null:
		_remove_processable_from_index(processable)

func _on_processable_tree_exiting(processable: Processable) -> void:
	unregister_processable(processable, false)
