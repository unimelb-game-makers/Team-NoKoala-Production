class_name WorldJobs
extends Node

@export var factory_manager: FactoryManager

var haulable_items: Array[FactoryItem] = []
var storages: Array[Vector3i] = []


func _ready() -> void:
	factory_manager.processable_registered.connect(_on_processable_registered)
	factory_manager.processable_unregistered.connect(_on_processable_unregistered)
	factory_manager.machine_registered.connect(_on_machine_registered)
	factory_manager.machine_unregistered.connect(_on_machine_unregistered)


func _on_processable_registered(processable: Processable):
	processable.dropped.connect(_on_processable_dropped)
	processable.claim_changed.connect(_on_processable_claim_changed)


func _on_processable_unregistered(processable: Processable):
	unregister_haulable(processable)
	processable.dropped.disconnect(_on_processable_dropped)
	processable.claim_changed.disconnect(_on_processable_claim_changed)


func _on_processable_dropped(processable: Processable, _world_position: Vector3):
	register_haulable(processable)

func _on_processable_claim_changed(processable: Processable, claimant: Object):
	if claimant != null:
		unregister_haulable(processable)
	
	if processable.is_dropped():
		register_haulable(processable)


func _on_machine_registered(machine: Machine):
	var input_cells := machine.get_input_cells()
	storages.append_array(input_cells)


func _on_machine_unregistered(machine: Machine):
	var input_cells := machine.get_input_cells()
	storages = storages.filter(func(cell): return not input_cells.has(cell))


func register_haulable(item: FactoryItem) -> void:
	if not haulable_items.has(item):
		haulable_items.append(item)


func unregister_haulable(item: FactoryItem) -> void:
	haulable_items.erase(item)


func find_nearest_haulable_item(position: Vector3) -> FactoryItem:
	var best_item: FactoryItem = null
	var best_distance := INF

	for item in haulable_items:
		if not is_instance_valid(item):
			continue

		if ReservationManager.is_reserved(item):
			continue

		if item_on_machine_input(item):
			continue

		var distance := position.distance_squared_to(
			item.global_position
		)

		if distance < best_distance:
			best_distance = distance
			best_item = item

	return best_item


func find_storage_for(item: FactoryItem) -> Variant:
	var origin: Vector3 = item.global_position
	var best: Variant = null
	var best_distance := INF

	for storage in storages:
		# Cells are not reserved (multiple mobs may haul to the same one); only
		# skip cells that already hold an item so deliveries spread out.
		if not factory_manager.get_processables_at(storage).is_empty():
			continue

		var distance := origin.distance_squared_to(
			factory_manager.grid.cell_to_world(storage)
		)
		if distance < best_distance:
			best_distance = distance
			best = storage

	return best


func item_on_machine_input(item: FactoryItem) -> bool:
	var cell := factory_manager.grid.world_to_cell(item.get_drop_world_position())
	for machine in factory_manager.get_machines():
		if cell in machine.get_input_cells():
			return true
	return false
