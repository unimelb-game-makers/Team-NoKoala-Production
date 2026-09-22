@tool
class_name MachineSynchronizer
extends BlockSynchronizer

@export var machine: Machine


@export_tool_button("Sync Machine", "Callable")
var sync_machine_button := sync_machine_to_block_data

var _watched_definition: MachineDefinition
var _watched_cells: Array[MachineCellDefinition] = []




func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return 

	var definition := machine.definition if machine != null else null
	if definition != _watched_definition:
		_watch_definition(definition)

	super._process(delta)


func _exit_tree() -> void:
	_disconnect_definition()


func sync_machine_to_block_data() -> void:
	if not Engine.is_editor_hint():
		return
	if block == null or machine == null:
		return
	if machine.definition == null:
		return
	if block.block_data == null:
		block.block_data = BlockData.new()
		block.block_data.resource_local_to_scene = true

	var footprint: Array[Vector3i] = []
	var overlap_cells: Array[Vector3i] = []
	for machine_cell in machine.definition.cells:
		if machine_cell == null:
			continue
		footprint.append(machine_cell.local_cell_offset)
		if machine_cell.can_overlap:
			overlap_cells.append(machine_cell.local_cell_offset)

	block.block_data.footprint = footprint
	block.block_data.overlap_cells = overlap_cells
	block.block_data.emit_changed()


func _watch_definition(definition: MachineDefinition) -> void:
	_disconnect_definition()
	_watched_definition = definition
	if _watched_definition == null:
		return

	_watched_definition.changed.connect(_on_definition_changed)
	_watch_cells()
	sync_machine_to_block_data()


func _watch_cells() -> void:
	_watched_cells.clear()
	for machine_cell in _watched_definition.cells:
		if machine_cell == null:
			continue
		machine_cell.changed.connect(_on_machine_cell_changed)
		_watched_cells.append(machine_cell)


func _disconnect_definition() -> void:
	if (
		_watched_definition != null
		and _watched_definition.changed.is_connected(_on_definition_changed)
	):
		_watched_definition.changed.disconnect(_on_definition_changed)

	for machine_cell in _watched_cells:
		if machine_cell.changed.is_connected(_on_machine_cell_changed):
			machine_cell.changed.disconnect(_on_machine_cell_changed)
	_watched_cells.clear()
	_watched_definition = null


func _on_definition_changed() -> void:
	_watch_definition(machine.definition if machine != null else null)


func _on_machine_cell_changed() -> void:
	sync_machine_to_block_data()
