## A resource deposit that yields items only while someone works on it.
##
## Anyone able to gather can harvest it by standing on it and working. Spirits
## are only asked to work it while it has a harvest order: a remaining amount
## set by the player in the machine UI, or "forever".
class_name ResourceAreaMachine
extends Machine

signal harvest_order_changed

enum LandingKind { BLOCKED, EMPTY, STACK }

const HARVEST_PORT := &"harvest"

@export var block: Block
@export var resource_area_definition: ResourceAreaDefinition
## Height above the area that harvested items are thrown from.
@export var launch_height := 1.0
@export var min_flight_time := 0.8
@export var max_flight_time := 1.1
## How far (in cells) harvested items can be thrown.
@export var max_throw_distance := 2

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


func get_progress_phase() -> ProgressPhase:
	return ProgressPhase.WORK if is_processing_recipe() else ProgressPhase.NONE


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
			var landing_cell := _pick_landing_cell(output.item, factory_manager)
			var factory_item := factory_manager.item_spawner.launch_factory_item(
				output.item,
				from_position,
				landing_cell,
				randf_range(min_flight_time, max_flight_time),
			)
			if factory_item != null:
				launched += 1
	return launched


## Picks a free cell around the area to throw an item onto. Cells that already
## hold a stack the item can join are preferred so harvests pile up together.
func _pick_landing_cell(
	item: FactoryItemDefinition,
	factory_manager: FactoryManager,
) -> Vector3i:
	var origin := _get_area_cell()
	for distance in range(1, max_throw_distance + 1):
		var empty_cells: Array[Vector3i] = []
		var stack_cells: Array[Vector3i] = []
		for dx in range(-distance, distance + 1):
			for dz in range(-distance, distance + 1):
				if maxi(absi(dx), absi(dz)) != distance:
					continue
				var cell := origin + Vector3i(dx, 0, dz)
				match _get_landing_kind(cell, item, factory_manager):
					LandingKind.EMPTY:
						empty_cells.append(cell)
					LandingKind.STACK:
						stack_cells.append(cell)
		if not stack_cells.is_empty():
			return stack_cells.pick_random()
		if not empty_cells.is_empty():
			return empty_cells.pick_random()
	# Boxed in: drop it back onto the area itself.
	return origin


func _get_landing_kind(
	cell: Vector3i,
	item: FactoryItemDefinition,
	factory_manager: FactoryManager,
) -> LandingKind:
	var grid := factory_manager.grid
	if not grid.grid_data.is_in_bounds(cell) or not grid.get_blocks_at(cell).is_empty():
		return LandingKind.BLOCKED

	var processables := factory_manager.get_processables_at(cell)
	if processables.is_empty():
		return LandingKind.EMPTY
	for processable in processables:
		var factory_item := processable as FactoryItem
		if (
			factory_item != null
			and factory_item.stack != null
			and factory_item.stack.item_definition == item
			and not factory_item.stack.is_full()
		):
			return LandingKind.STACK
	return LandingKind.BLOCKED


func _get_area_cell() -> Vector3i:
	var cells := get_occupied_cells()
	return cells[0] if not cells.is_empty() else center_position


func _on_harvest_order_changed() -> void:
	_update_job_requests()
	harvest_order_changed.emit()
