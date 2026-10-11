## A resource deposit that yields items only while someone works on it.
##
## Anyone able to gather can harvest it by standing on it and working. Spirits
## are only asked to work it while it has a harvest order: a remaining amount
## set by the player in the machine UI, or "forever".
class_name ResourceAreaMachine
extends Machine

signal harvest_order_changed

const HARVEST_PORT := &"harvest"

@export var block: Block
@export var resource_area_definition: ResourceAreaDefinition
## Height above the area that harvested items are thrown from.
@export var launch_height := 1.0
## Horizontal speed range of harvested items, thrown in a random direction.
@export var min_launch_speed := 0.4
@export var max_launch_speed := 0.8
## Upward speed range of harvested items.
@export var min_launch_up_speed := 1.0
@export var max_launch_up_speed := 1.5

## Items still to harvest for the current order; ignored when harvesting forever.
var harvest_target := 0
var harvest_forever := false
var _harvest_elapsed := 0.0
var _factory_manager: FactoryManager


func has_harvest_order() -> bool:
	return harvest_forever or harvest_target > 0


func set_harvest_target(amount: int) -> void:
	amount = maxi(amount, 0)
	if harvest_target == amount:
		return
	harvest_target = amount
	_on_harvest_order_changed()


func set_harvest_forever(forever: bool) -> void:
	if harvest_forever == forever:
		return
	harvest_forever = forever
	_on_harvest_order_changed()


func get_recipe() -> ProductionRecipe:
	if resource_area_definition == null:
		return null
	return resource_area_definition.spawner_recipe


func is_processing_recipe() -> bool:
	return are_work_ports_ready() or _harvest_elapsed > 0.0


## Only while someone is working it, so a half-finished harvest left behind
## doesn't keep the progress bar up.
func get_progress_phase() -> ProgressPhase:
	return ProgressPhase.WORK if are_work_ports_ready() else ProgressPhase.NONE


func get_processing_progress() -> float:
	var recipe := get_recipe()
	if recipe == null or recipe.duration_seconds <= 0.0:
		return 0.0
	return clampf(_harvest_elapsed / recipe.duration_seconds, 0.0, 1.0)


func get_progress_text() -> String:
	if get_progress_phase() != ProgressPhase.WORK:
		return ""
	return "Harvest %d%%" % roundi(get_processing_progress() * 100.0)


## Only advertise work to spirits while there is an order to fill. Players can
## still harvest by hand at any time.
func get_remaining_work_needs() -> Array[Dictionary]:
	if not has_harvest_order():
		return []
	return super()


func keeps_assigned_workers() -> bool:
	return has_harvest_order()


func try_working_at_port(
	cell: Vector3i,
	capability: WorkerCapability,
) -> bool:
	_ensure_harvest_port()
	return super(cell, capability)


func _factory_tick(delta: float, factory_manager: FactoryManager) -> void:
	if factory_manager == null:
		return

	_factory_manager = factory_manager
	_ensure_harvest_port()
	_update_job_requests()

	var recipe := get_recipe()
	if recipe == null or not are_work_ports_ready():
		unregister_active()
		return

	register_active(faith_drain_rate)
	if is_shut_down:
		return

	_harvest_elapsed += delta
	if _harvest_elapsed < recipe.duration_seconds:
		return

	_harvest_elapsed = 0.0
	var harvested := _launch_outputs(recipe, factory_manager)
	if harvested > 0 and not harvest_forever and harvest_target > 0:
		set_harvest_target(harvest_target - harvested)


func _ensure_harvest_port() -> void:
	if not work_ports.is_empty() or machine_assembly == null:
		return
	var cells := get_cells_for_port(MachineCellDefinition.Role.WORK, HARVEST_PORT)
	if cells.is_empty():
		_work_ports_valid = false
		return
	var port := WorkPort.new(HARVEST_PORT, WorkType.Value.GATHERING, cells)
	port.enabled_changed.connect(_on_work_port_enabled_changed)
	port.allocation_changed.connect(_on_work_port_allocation_changed)
	work_ports.append(port)
	_work_ports_valid = true


## Throws every output of `recipe` out of the area; returns how many items were
## thrown.
func _launch_outputs(
	recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> int:
	var launched := 0
	var origin := _get_area_cell()
	var from_position := factory_manager.grid.cell_to_world(origin)
	from_position.y += launch_height

	for output in recipe.outputs:
		if output == null or output.item == null or output.amount <= 0:
			continue
		for _i in output.amount:
			var factory_item := factory_manager.item_spawner.launch_factory_item(
				output.item,
				from_position,
				_random_launch_velocity(),
			)
			if factory_item != null:
				launched += 1
	return launched


func _random_launch_velocity() -> Vector3:
	var horizontal := Vector2.from_angle(randf() * TAU) * randf_range(
		min_launch_speed,
		max_launch_speed,
	)
	return Vector3(
		horizontal.x,
		randf_range(min_launch_up_speed, max_launch_up_speed),
		horizontal.y,
	)


func _get_area_cell() -> Vector3i:
	var cells := get_occupied_cells()
	return cells[0] if not cells.is_empty() else center_position


func _on_harvest_order_changed() -> void:
	_update_job_requests()
	harvest_order_changed.emit()
