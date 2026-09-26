class_name PlayerInteractionController
extends Node

const NO_JOB_TEXT := "No available job"
## Item lookups see through mouse-pick-only colliders (blueprints, resource
## areas), so items inside them can still be clicked.
const ITEM_PICK_MASK := 0xFFFFFFFF & ~Block.MOUSE_PICK_ONLY_COLLISION_LAYER

@export var spring_arm: CameraController

var player: Node3D
var _inventory_owner: InventoryOwner
var _machine_placement_controller: MachinePlacementController
var _job_board: JobBoard
var _selected_consumer: JobConsumer
var _context_menu: ContextMenu
var _selection_box: SelectionBox
var _machine_ui: MachineUI


func configure(
	p_spring_arm: CameraController,
	machine_placement_controller: MachinePlacementController,
	job_board: JobBoard,
	machine_ui: MachineUI,
) -> void:
	spring_arm = p_spring_arm
	_machine_placement_controller = machine_placement_controller
	_job_board = job_board
	_machine_ui = machine_ui
	_bind_placement_controller()


func _ready() -> void:
	player = get_parent()
	_inventory_owner = NodeUtils.get_child_by_type(player, InventoryOwner)
	assert(_inventory_owner != null, "Player requires an InventoryOwner")
	_bind_placement_controller()
	_context_menu = ContextMenu.new()
	_context_menu.name = "ContextMenu"
	add_child(_context_menu)
	var selection_layer := CanvasLayer.new()
	selection_layer.name = "SelectionLayer"
	add_child(selection_layer)
	_selection_box = SelectionBox.new()
	_selection_box.name = "SelectionBox"
	selection_layer.add_child(_selection_box)


func _try_handle_npc_interaction(event: InputEvent) -> bool:
	if _selected_consumer != null and not is_instance_valid(_selected_consumer):
		_clear_consumer_selection()
	if event.is_action_pressed("ui_cancel"):
		_clear_consumer_selection()
		_context_menu.close()
		return false
	if not event is InputEventMouseButton:
		return false
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return false

	var hit_node := _node_at_mouse()
	var consumer := _consumer_from_node(hit_node)
	if consumer != null:
		_select_consumer(consumer)
		get_viewport().set_input_as_handled()
		return true

	if _selected_consumer == null:
		return false

	var item := _factory_item_at_mouse()
	if item != null:
		_open_item_job_menu(item, event.position)
		get_viewport().set_input_as_handled()
		return true

	var provider := _provider_from_node(hit_node)
	if provider != null:
		_open_job_menu(provider, event.position)
		get_viewport().set_input_as_handled()
		return true

	_clear_consumer_selection()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if _is_place_mode():
		return
	if _try_handle_npc_interaction(event):
		return
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		_try_open_machine_ui()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	# LMB -> pick up logic
	if event.shift_pressed and _inventory_owner.inventory.hand_slot != null:
		_try_drop_held_item()
		return
	var factory_item := _factory_item_at_mouse()
	if factory_item != null:
		_try_pick_up_item_at_mouse(factory_item)


func _try_open_machine_ui() -> void:
	var assembly := _assembly_from_node(_node_at_mouse())
	if _machine_ui == null or assembly == null:
		return
	var machine := assembly.get_ui_machine()
	var panels := assembly.get_ui_panels()
	if machine == null or panels.is_empty():
		return
	_machine_ui.open(machine, panels)
	get_viewport().set_input_as_handled()


func _close_machine_ui() -> void:
	if _machine_ui != null:
		_machine_ui.close()


func _try_pick_up_item_at_mouse(factory_item: FactoryItem) -> void:
	if _inventory_owner.try_pick_up_item(factory_item):
		get_viewport().set_input_as_handled()


func _try_drop_held_item() -> void:
	if _inventory_owner.try_drop_held_item():
		get_viewport().set_input_as_handled()


func _factory_item_at_mouse() -> FactoryItem:
	return _item_from_node(_node_at_mouse(ITEM_PICK_MASK))


func _node_at_mouse(collision_mask := 0xFFFFFFFF) -> Node:
	if spring_arm == null:
		return null
	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := spring_arm.camera.project_ray_origin(mouse_position)
	var ray_end := ray_origin + spring_arm.camera.project_ray_normal(mouse_position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = collision_mask
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
	var assembly := _assembly_from_node(node)
	if assembly == null or assembly.machine == null:
		return null
	return assembly.machine.job_provider


func _assembly_from_node(node: Node) -> MachineAssembly:
	while node != null:
		if node is MachineAssembly:
			return node as MachineAssembly
		node = node.get_parent()
	return null


func _select_consumer(consumer: JobConsumer) -> void:
	_clear_consumer_selection()
	_selected_consumer = consumer
	_selection_box.attach(consumer.actor)
	print("Selected NPC: ", consumer.actor.name)


func _clear_consumer_selection() -> void:
	_selected_consumer = null
	if _selection_box != null:
		_selection_box.detach()


func _is_place_mode() -> bool:
	return (
		_machine_placement_controller != null
		and _machine_placement_controller.place_mode
	)


func _on_place_mode_changed(enabled: bool) -> void:
	if enabled:
		_clear_consumer_selection()
		_context_menu.close()
		_close_machine_ui()


func _open_job_menu(provider: JobProvider, screen_position: Vector2) -> void:
	var actions: Array[ContextMenuAction] = []
	for request in provider.get_available_requests(_selected_consumer):
		_append_job_action(actions, provider, request, null, null)
	for entry in provider.get_active_assignments():
		if provider.can_take_over(entry.request, _selected_consumer):
			_append_job_action(
				actions,
				provider,
				entry.request,
				entry.consumer,
				entry.job,
			)

	if actions.is_empty():
		print("Provider has no actionable jobs")
	_context_menu.open(actions, screen_position, NO_JOB_TEXT)


func _open_item_job_menu(item: FactoryItem, screen_position: Vector2) -> void:
	var actions: Array[ContextMenuAction] = []
	for provider in _job_board.get_providers():
		for entry in provider.get_active_assignments():
			var active_job := entry.job as HaulJob
			if (
				active_job != null
				and active_job.item == item
				and provider.can_take_over(entry.request, _selected_consumer)
			):
				_append_job_action(
					actions,
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
				_append_job_action(actions, provider, request, null, null, item)

	if actions.is_empty():
		print("Item has no actionable machine jobs")
	_context_menu.open(actions, screen_position, NO_JOB_TEXT)


## Appends an action that assigns this job to the selected NPC, unless the NPC
## won't do this kind of job.
func _append_job_action(
	actions: Array[ContextMenuAction],
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
	var item := exact_item
	if item == null and job is HaulJob:
		item = (job as HaulJob).item
	actions.append(ContextMenuAction.new(
		label,
		_assign_job.bind(provider, request, item),
	))


func _assign_job(
	provider: JobProvider,
	request: JobRequest,
	item: FactoryItem,
) -> void:
	if _selected_consumer == null or not is_instance_valid(_selected_consumer):
		return
	var succeeded := _selected_consumer.assign_request(provider, request, item)
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
