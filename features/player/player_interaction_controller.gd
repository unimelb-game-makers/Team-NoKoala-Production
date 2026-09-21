class_name PlayerInteractionController
extends Node

@export var camera: Camera3D

var player: Node3D
var _inventory_owner: InventoryOwner
var _machine_placement_controller: MachinePlacementController
var _job_board: JobBoard
var _selected_consumer: JobConsumer
var _job_menu: PopupMenu
var _menu_jobs: Array[Dictionary] = []


func configure(
	machine_placement_controller: MachinePlacementController,
	job_board: JobBoard,
) -> void:
	_machine_placement_controller = machine_placement_controller
	_job_board = job_board
	_bind_placement_controller()


func _ready() -> void:
	player = get_parent()
	_inventory_owner = NodeUtils.get_child_by_type(player, InventoryOwner)
	assert(_inventory_owner != null, "Player requires an InventoryOwner")
	_bind_placement_controller()
	_job_menu = PopupMenu.new()
	_job_menu.name = "JobAssignmentMenu"
	_job_menu.id_pressed.connect(_on_job_menu_id_pressed)
	add_child(_job_menu)


func _input(event: InputEvent) -> void:
	if _is_place_mode():
		return
	if _selected_consumer != null and not is_instance_valid(_selected_consumer):
		_clear_consumer_selection()
	if event.is_action_pressed("ui_cancel"):
		_clear_consumer_selection()
		_job_menu.hide()
		return
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	var hit_node := _node_at_mouse()
	print(hit_node)
	var consumer := _consumer_from_node(hit_node)
	if consumer != null:
		_select_consumer(consumer)
		get_viewport().set_input_as_handled()
		return

	if _selected_consumer == null:
		return

	var item := _item_from_node(hit_node)
	if item != null:
		_open_item_job_menu(item, event.position)
		get_viewport().set_input_as_handled()
		return

	var provider := _provider_from_node(hit_node)
	if provider != null:
		_open_job_menu(provider, event.position)
		get_viewport().set_input_as_handled()
		return

	_clear_consumer_selection()


func _unhandled_input(event: InputEvent) -> void:
	if _is_place_mode():
		return
	if not event is InputEventMouseButton:
		return
	if not event.pressed or (event.button_index != MOUSE_BUTTON_LEFT and event.button_index != MOUSE_BUTTON_RIGHT):
		return
	
	# LMB -> pick up logic
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.shift_pressed and _inventory_owner.inventory.hand_slot != null:
			_try_drop_held_item()
			return
		var factory_item := _factory_item_at_mouse()
		if factory_item != null:
			_try_pick_up_item_at_mouse(factory_item)
	
	# RMB -> stack splitting logic
	if event.button_index == MOUSE_BUTTON_RIGHT:
		print("RMB")
		if _inventory_owner.inventory.hand_slot != null:
			print("held item")
			_try_split_held_item()
			return
		var factory_item := _factory_item_at_mouse()
		if factory_item != null:
			_try_split_item_at_mouse(factory_item)

func _try_split_held_item() -> void:
	if _inventory_owner.try_split_item():
		get_viewport().set_input_as_handled()

func _try_split_item_at_mouse(factory_item: FactoryItem) -> void:
	if _inventory_owner.try_split_item(factory_item):
		get_viewport().set_input_as_handled()

func _try_pick_up_item_at_mouse(factory_item: FactoryItem) -> void:
	if _inventory_owner.try_pick_up_item(factory_item):
		get_viewport().set_input_as_handled()

func _try_drop_held_item() -> void:
	if _inventory_owner.try_drop_held_item():
		get_viewport().set_input_as_handled()

func _factory_item_at_mouse() -> FactoryItem:
	return _item_from_node(_node_at_mouse())


func _node_at_mouse() -> Node:
	if camera == null:
		return null
	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_end := ray_origin + camera.project_ray_normal(mouse_position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result := player.get_world_3d().direct_space_state.intersect_ray(query)
	return result.get("collider") as Node


func _item_from_node(node: Node) -> FactoryItem:
	while node != null:
		if node is FactoryItem:
			return node as FactoryItem
		node = node.get_parent()
	return null


func _consumer_from_node(node: Node) -> JobConsumer:
	while node != null:
		var consumer := NodeUtils.get_child_by_type(node, JobConsumer)
		if consumer != null:
			return consumer
		node = node.get_parent()
	return null


func _provider_from_node(node: Node) -> JobProvider:
	while node != null:
		if node is MachineAssembly:
			var machine := (node as MachineAssembly).machine
			return machine.job_provider if machine != null else null
		node = node.get_parent()
	return null


func _select_consumer(consumer: JobConsumer) -> void:
	_clear_consumer_selection()
	_selected_consumer = consumer
	print("Selected NPC: ", consumer.actor.name)


func _clear_consumer_selection() -> void:
	_selected_consumer = null


func _is_place_mode() -> bool:
	return (
		_machine_placement_controller != null
		and _machine_placement_controller.place_mode
	)


func _on_place_mode_changed(enabled: bool) -> void:
	if enabled:
		_clear_consumer_selection()
		_job_menu.hide()


func _open_job_menu(provider: JobProvider, screen_position: Vector2) -> void:
	_job_menu.hide()
	_menu_jobs.clear()
	_job_menu.clear()
	for request in provider.get_available_requests(_selected_consumer):
		_add_job_menu_entry(provider, request, null, null)
	for entry in provider.get_active_assignments():
		if provider.can_take_over(entry.request, _selected_consumer):
			_add_job_menu_entry(provider, entry.request, entry.consumer, entry.job)

	if _menu_jobs.is_empty():
		print("Provider has no actionable jobs")
		return
	_job_menu.position = Vector2i(screen_position)
	_job_menu.popup()


func _open_item_job_menu(item: FactoryItem, screen_position: Vector2) -> void:
	_job_menu.hide()
	_menu_jobs.clear()
	_job_menu.clear()

	for provider in _job_board.get_providers():
		for entry in provider.get_active_assignments():
			var active_job := entry.job as HaulJob
			if (
				active_job != null
				and active_job.item == item
				and provider.can_take_over(entry.request, _selected_consumer)
			):
				_add_job_menu_entry(
					provider,
					entry.request,
					entry.consumer,
					entry.job,
					item,
				)

		for request in provider.get_requests():
			var haul_request := request as HaulRequest
			if (
				haul_request != null
				and haul_request.is_actionable_with_item(
					_selected_consumer,
					item,
				)
			):
				_add_job_menu_entry(provider, request, null, null, item)

	if _menu_jobs.is_empty():
		print("Item has no actionable machine jobs")
		return
	_job_menu.position = Vector2i(screen_position)
	_job_menu.popup()


func _add_job_menu_entry(
	provider: JobProvider,
	request: JobRequest,
	consumer: JobConsumer,
	job: Job,
	exact_item: FactoryItem = null,
) -> void:
	if _selected_consumer.get_job_priority(request.job_type()) <= 0:
		return
	var label := String(request.job_type()).capitalize()
	if request is HaulRequest:
		var haul := request as HaulRequest
		label += ": %s -> %s" % [haul.item_definition.item_name, haul.destination]
	label += " (available)" if consumer == null else " (%s)" % consumer.actor.name
	var id := _menu_jobs.size()
	var item := exact_item
	if item == null and job is HaulJob:
		item = (job as HaulJob).item
	_menu_jobs.append({
		"provider": provider,
		"request": request,
		"item": item,
	})
	_job_menu.add_item(label, id)


func _on_job_menu_id_pressed(id: int) -> void:
	if (
		_selected_consumer == null
		or not is_instance_valid(_selected_consumer)
		or id < 0
		or id >= _menu_jobs.size()
	):
		return
	var entry := _menu_jobs[id]
	var succeeded := _selected_consumer.assign_request(
		entry.provider,
		entry.request,
		entry.item,
	)
	print("Manual provider job assignment: ", "success" if succeeded else "failed")
	if succeeded:
		_clear_consumer_selection()


func _exit_tree() -> void:
	_clear_consumer_selection()
	if (
		_machine_placement_controller != null
		and _machine_placement_controller.place_mode_changed.is_connected(
			_on_place_mode_changed,
		)
	):
		_machine_placement_controller.place_mode_changed.disconnect(
			_on_place_mode_changed,
		)


func _bind_placement_controller() -> void:
	if (
		_machine_placement_controller != null
		and not _machine_placement_controller.place_mode_changed.is_connected(
			_on_place_mode_changed,
		)
	):
		_machine_placement_controller.place_mode_changed.connect(
			_on_place_mode_changed,
		)
