class_name MachineMousePlacementController
extends MachinePlacementController

const GROUND_COLLISION_MASK := 1 << 3

@export var spring_arm: CameraController
@export var placement_grid: PlacementGrid


func configure(
	p_machine_factory: MachineFactory,
	p_grid: Grid,
	p_factory_manager: FactoryManager,
	faith: FaithManager,
	jobs: JobBoard,
	reservations: ReservationManager,
	mobs_root: Node,
	p_spring_arm: CameraController,
) -> void:
	# Godot doesn't allow override a function with different parameters
	# Not sure if there's a better way to do this
	spring_arm = p_spring_arm
	super(p_machine_factory, p_grid, p_factory_manager, faith, jobs, reservations, mobs_root, p_spring_arm)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("rotate"):
		rotate_preview()

	if Input.is_action_just_pressed("switch_machine"):
		select_next_machine()

	if Input.is_action_just_pressed("toggle_edit"):
		place_mode = !place_mode

	if spring_arm == null:
		return

	if not has_active_placement():
		if placement_grid:
			placement_grid.hide_grid()
		return

	var hit := _raycast_ground()
	if hit.is_empty():
		if placement_grid:
			placement_grid.hide_grid()
		return

	update_preview(_cell_from_hit(hit))

	if placement_grid:
		placement_grid.show_grid()
		placement_grid.set_cursor(hit.position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_place_machine()

func _place_machine() -> void:
	if confirm_placement(cell_at_mouse_position()):
		begin_placement()

func cell_at_mouse_position() -> Vector3i:
	var result := _raycast_ground()
	if result.is_empty():
		return Vector3i()
	return _cell_from_hit(result)

func _raycast_ground() -> Dictionary:
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := spring_arm.camera.project_ray_origin(mouse_pos)
	var ray_dir := spring_arm.camera.project_ray_normal(mouse_pos)
	var ray_end := ray_origin + ray_dir * 1000.0

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = GROUND_COLLISION_MASK
	return grid.get_world_3d().direct_space_state.intersect_ray(query)

func _cell_from_hit(result: Dictionary) -> Vector3i:
	var hit_pos: Vector3 = result.position
	var cell := grid.local_to_map(
		hit_pos - (result.normal * (grid.cell_size / 2.0))
	)
	cell.y = 0
	return cell
