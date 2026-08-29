class_name Pathfinder
extends Node

var grid: Grid
var factory_manager: FactoryManager
var _astar := AStarGrid2D.new()
## Passable machine port cells
var _port_cells: Dictionary = {}
var _ready_ok := false


func _ready() -> void:
	add_to_group("pathfinder")
	grid = get_parent() as Grid
	_rebuild()
	grid.grid_changed.connect(_on_grid_changed)
	_ready_ok = true
	# FactoryManager readies after us in the scene tree; wire it up once the
	# whole tree is ready so machine ports are known.
	_connect_factory_manager.call_deferred()


func _connect_factory_manager() -> void:
	factory_manager = get_tree().get_first_node_in_group("factory_manager")
	if factory_manager == null:
		return
	factory_manager.machine_registered.connect(_on_machines_changed)
	factory_manager.machine_unregistered.connect(_on_machines_changed)
	_on_machines_changed(null)


func _rebuild() -> void:
	var cells := grid.grid_data.get_cells()
	if cells.is_empty():
		return

	var min_c := Vector2i(cells[0].x, cells[0].z)
	var max_c := min_c
	for c in cells:
		min_c = Vector2i(mini(min_c.x, c.x), mini(min_c.y, c.z))
		max_c = Vector2i(maxi(max_c.x, c.x), maxi(max_c.y, c.z))

	_astar.region = Rect2i(min_c, max_c - min_c + Vector2i.ONE)
	_astar.cell_size = Vector2.ONE
	# Only cut a corner when neither adjacent cell is blocked, so mobs never
	# clip through the corner of a machine footprint.
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()

	_refresh_port_cells()
	for c in cells:
		_apply_cell(c)


## Re-reads occupancy for a single grid cell. Cheap enough to call per affected
## cell on every placement / removal.
func _apply_cell(cell: Vector3i) -> void:
	var id := Vector2i(cell.x, cell.z)
	if not _astar.is_in_boundsv(id):
		return
	var data := grid.grid_data.get_cell_data(cell)
	var blocked := data != null and data.block != null
	_astar.set_point_solid(id, blocked and not _port_cells.has(id))


func _on_grid_changed(affected_cells: Array) -> void:
	for cell: Vector3i in affected_cells:
		_apply_cell(cell)


## A machine was registered or unregistered: recompute the passable port cells
## and re-apply solidity to every cell that gained or lost port status.
func _on_machines_changed(_machine: Machine) -> void:
	var stale := _port_cells.keys()
	_refresh_port_cells()
	var touched := {}
	for id in stale:
		touched[id] = true
	for id in _port_cells:
		touched[id] = true
	for id: Vector2i in touched:
		_apply_cell(Vector3i(id.x, 0, id.y))


func _refresh_port_cells() -> void:
	_port_cells.clear()
	if factory_manager == null:
		return
	for machine in factory_manager.get_machines():
		for cell in machine.get_input_cells():
			_port_cells[Vector2i(cell.x, cell.z)] = true
		for cell in machine.get_output_cells():
			_port_cells[Vector2i(cell.x, cell.z)] = true


## Returns an empty array when the goal is unreachable (walled off, goal cell
## solid, or the mob boxed in) so the caller can fail the move.
func find_path(from_world: Vector3, to_world: Vector3) -> PackedVector3Array:
	if not _ready_ok:
		return PackedVector3Array()

	var from_cell := grid.world_to_cell(from_world)
	var to_cell := grid.world_to_cell(to_world)
	var from_id := Vector2i(from_cell.x, from_cell.z)
	var to_id := Vector2i(to_cell.x, to_cell.z)

	if not _astar.is_in_boundsv(from_id) or not _astar.is_in_boundsv(to_id):
		return PackedVector3Array()

	# The mob is standing on `from_id`; a machine dropped on top of it must not
	# make the mob unable to path out.
	var from_was_solid := _astar.is_point_solid(from_id)
	_astar.set_point_solid(from_id, false)
	# No partial paths: an unreachable goal (walled off, or the mob boxed in)
	# comes back as an empty array, which the caller treats as a failed move.
	var id_path := _astar.get_id_path(from_id, to_id, false)
	_astar.set_point_solid(from_id, from_was_solid)

	if id_path.is_empty():
		return PackedVector3Array()

	var out := PackedVector3Array()
	out.append(from_world)
	for i in range(1, id_path.size()):
		out.append(grid.cell_to_world(Vector3i(id_path[i].x, 0, id_path[i].y)))

	# A non-empty path always ends on `to_id`; use the caller's exact target as
	# the final waypoint so arrival checks land on it, not the cell centre.
	out[out.size() - 1] = to_world

	return out
