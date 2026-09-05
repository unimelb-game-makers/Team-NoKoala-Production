class_name MachineMousePlacementController
extends MachinePlacementController

@export var camera: Camera3D

func _ready() -> void:
	super()
	begin_placement()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("rotate"):
		rotate_preview()

	if Input.is_action_just_pressed("switch_machine"):
		select_next_machine()

	if camera == null:
		return

	update_preview(cell_at_mouse_position())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_place_machine()

func _place_machine() -> void:
	if confirm_placement(cell_at_mouse_position()):
		begin_placement()

func cell_at_mouse_position() -> Vector3i:
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var ray_end := ray_origin + ray_dir * 1000.0

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result := grid.get_world_3d().direct_space_state.intersect_ray(query)

	if result:
		var hit_pos: Vector3 = result.position
		var cell := grid.local_to_map(
			hit_pos - (result.normal * (grid.cell_size / 2.0))
		)
		cell.y = 0
		return cell

	return Vector3i()
